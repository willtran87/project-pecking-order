class_name DepartmentSimulation
extends RefCounted

signal snapshot_changed(snapshot: Dictionary)
signal egg_laid(worker_id: int, quality: StringName, value_cents: int)
signal egg_laid_detailed(
	worker_id: int,
	quality: StringName,
	value_cents: int,
	claim_id: int,
	priority_credit_cents: int
)
signal announcement_posted(message: String)
signal feed_party_funded()
signal upgrade_purchased(upgrade_id: StringName, level: int, cost_cents: int)
signal quality_streak_changed(streak: int, best_streak: int)
signal workday_completed(report: Dictionary)
signal decision_requested(decision: Dictionary)
signal decision_resolved(result: Dictionary)
signal personnel_action_resolved(result: Dictionary)
signal peck_assist_resolved(result: Dictionary)
signal peck_assist_missed(worker_id: int, claim_id: int)
signal staffing_action_resolved(result: Dictionary)
signal career_sponsorship_resolved(result: Dictionary)
signal office_capacity_changed(capacity: int, cost_cents: int)
signal shift_phase_changed(phase: int)

enum ShiftPhase {
	AWAITING_DIRECTIVE,
	RUNNING,
	AWAITING_INCIDENT,
	REVIEW,
}

const SHIFT_START_MINUTE := 8 * 60
const SHIFT_END_MINUTE := 17 * 60
const MINUTES_PER_TICK := 2
const MAX_CLAIM_QUEUE := 18
const BASE_WORK_PROGRESS := 3.2
const MAX_UPGRADE_LEVEL := 5
const SAVE_STATE_VERSION := 7
const MINIMUM_STAFF_COUNT := 3
const MAXIMUM_STAFF_CAPACITY := 6
const PROBATION_CAMPAIGN_SHIFTS := 5
const GOLDEN_DOSSIER_FALLBACK_SHIFT := 3
const FLOCK_RESTRUCTURING_SHIFT := 4
const PECK_ASSIST_LIMIT := 3
const PECK_ASSIST_WINDOW_START := 28.0
const PECK_ASSIST_WINDOW_END := 88.0
const PECK_ASSIST_IDEAL_PROGRESS := 62.0
const BASE_FEED_COST_CENTS := 600
const FEED_COST_PER_ACTIVE_HEN_CENTS := 200
const FACILITY_COST_PER_EXPANDED_SEAT_CENTS := 200
const CAREER_SPONSORSHIP_COST_CENTS := 1200
const LEGACY_FULL_ROSTER_FEED_CENTS := 1800
const CAPACITY_UPGRADE_COSTS := {
	4: 2500,
	5: 5500,
}
const AUTO_ASSIGNMENT: StringName = &"auto"
const SPECIALTY_SPEED_MULTIPLIER := 1.18
const MISMATCH_SPEED_MULTIPLIER := 0.88
const SPECIALTY_CRACK_MODIFIER := -0.04
const MISMATCH_CRACK_MODIFIER := 0.035
const AUTO_SPECIALTY_GRACE_MINUTES := 180
const CAMPAIGN_UNLOCKS: Array[StringName] = [
	&"welfare_breaks",
	&"shell_quality_checks",
	&"farmer_credit_bonus",
]
const CLAIM_LANES: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const CLAIM_LANE_DEFINITIONS := {
	&"nest_damage": {
		"display_name": "NEST DAMAGE",
		"short_name": "NEST",
		"description": "Routine coop and nesting-property losses. Fast, common, and deadline-heavy.",
		"base_difficulty": 0.82,
		"base_value_cents": 360,
		"crack_modifier": -0.015,
		"deadline_minutes": 180,
		"arrival_weight": 0.50,
		"accent_hex": "65b7a5",
	},
	&"predator_loss": {
		"display_name": "PREDATOR LOSS",
		"short_name": "PREDATOR",
		"description": "Sensitive fox, hawk, and missing-flock files with higher value and emotional strain.",
		"base_difficulty": 1.05,
		"base_value_cents": 560,
		"crack_modifier": 0.025,
		"deadline_minutes": 240,
		"arrival_weight": 0.32,
		"accent_hex": "d69a55",
	},
	&"appeals": {
		"display_name": "APPEALS & EXCEPTIONS",
		"short_name": "APPEALS",
		"description": "Complex disputed denials. Slow and lucrative, with substantial shell and compliance risk.",
		"base_difficulty": 1.30,
		"base_value_cents": 820,
		"crack_modifier": 0.055,
		"deadline_minutes": 360,
		"arrival_weight": 0.18,
		"accent_hex": "a987bf",
	},
}
const INITIAL_CLAIM_LANES: Array[StringName] = [
	&"nest_damage",
	&"predator_loss",
	&"appeals",
	&"nest_damage",
	&"predator_loss",
	&"appeals",
]
const INCIDENT_MINUTES: Array[int] = [11 * 60, 14 * 60]
const FLOCK_PETITION_INCIDENT_ID: StringName = &"flock_petition"
const FLOCK_PETITION_CATEGORY: StringName = &"flock_petition"
const FLOCK_PETITION_DAYS: Array[int] = [2, 4]
const FLOCK_PETITION_INCIDENT_SLOT := 1
const FLOCK_PETITION_HISTORY_LIMIT := 8
const FLOCK_PETITION_RESPONSE_IDS: Array[StringName] = [
	&"sign_compact",
	&"offer_concession",
	&"deny_and_monitor",
]
const FLOCK_PETITION_TYPES: Array[StringName] = [
	&"specialty_respect",
	&"safe_pace",
	&"credit_in_writing",
]
const WORK_TO_RULE_SOLIDARITY_THRESHOLD := 45.0
const WORK_TO_RULE_WORK_MULTIPLIER := 0.82
const WORK_TO_RULE_CRACK_MODIFIER := -0.06
const FLOCK_PETITION_DEFINITIONS := {
	&"specialty_respect": {
		"title": "A HEN REQUESTS HER OWN KIND OF PECKWORK",
		"compact_name": "SPECIALTY NEST COMPACT",
		"promise": "Assign the sponsor to her trained claim lane for the entire next shift.",
		"condition": "Sponsor remains assigned to her specialty lane for the full shift.",
		"sign_cost_cents": 800,
		"priority": 3,
	},
	&"safe_pace": {
		"title": "THE FLOCK FILES FOR A SURVIVABLE PACE",
		"compact_name": "SAFE PECKING COMPACT",
		"promise": "Run the next shift without overtime or an individual quota-pressure filing.",
		"condition": "No overtime and no quota-pressure personnel action during the shift.",
		"sign_cost_cents": 900,
		"priority": 2,
	},
	&"credit_in_writing": {
		"title": "A HEN ASKS WHOSE NAME REACHES THE FARMER",
		"compact_name": "NAMED LAYER COMPACT",
		"promise": "File written shared credit for the sponsor during the next shift.",
		"condition": "Use Share Credit on the sponsor before the next shift closes.",
		"sign_cost_cents": 700,
		"priority": 1,
	},
}
const DIRECTIVE_ORDER: Array[StringName] = [
	&"record_harvest",
	&"shell_assurance",
	&"sustainable_flock",
]
const DIRECTIVE_DEFINITIONS := {
	&"record_harvest": {
		"name": "RECORD HARVEST INITIATIVE",
		"short_name": "HARVEST",
		"tagline": "Today's wellness is tomorrow's accounting problem.",
		"preview": "+10% work speed  ·  +20% strain  ·  +4% crack risk",
		"outcome": "Record Harvest authorized. Throughput now outranks shell integrity.",
		"work_multiplier": 1.10,
		"fatigue_multiplier": 1.20,
		"stress_multiplier": 1.20,
		"morale_drain_multiplier": 1.0,
		"crack_modifier": 0.04,
		"feed_delta_cents": 0,
		"tone": &"danger",
	},
	&"shell_assurance": {
		"name": "SHELL ASSURANCE PROTOCOL",
		"short_name": "ASSURANCE",
		"tagline": "Nothing leaves the nest until Compliance can admire it.",
		"preview": "-7% work speed  ·  -5% crack risk  ·  +3 obedience",
		"outcome": "Shell Assurance authorized. The clutch will be slower and harder to dispute.",
		"work_multiplier": 0.93,
		"fatigue_multiplier": 1.0,
		"stress_multiplier": 1.0,
		"morale_drain_multiplier": 1.0,
		"crack_modifier": -0.05,
		"feed_delta_cents": 0,
		"compliance_delta": 3.0,
		"tone": &"quality",
	},
	&"sustainable_flock": {
		"name": "SUSTAINABLE FLOCK STANDARD",
		"short_name": "FLOCK CARE",
		"tagline": "An evidence-based investment in continued laying capacity.",
		"preview": "-3% work speed  ·  -30% strain  ·  daily feed +$6",
		"outcome": "Sustainable Flock authorized. Continued laying has been provisionally funded.",
		"work_multiplier": 0.97,
		"fatigue_multiplier": 0.70,
		"stress_multiplier": 0.70,
		"morale_drain_multiplier": 0.60,
		"crack_modifier": 0.0,
		"feed_delta_cents": 600,
		"worker_stress_delta": -4.0,
		"tone": &"care",
	},
}
const INCIDENT_ORDER: Array[StringName] = [
	&"ledger_molt",
	&"wellness_request",
	&"farmer_story",
	&"feed_shortfall",
]
const INCIDENT_DEFINITIONS := {
	&"ledger_molt": {
		"title": "THE EGG LEDGER IS MOLTING",
		"body": "The legacy ledger server is emitting feathers, duplicate peckwork, and legally meaningful smoke.",
		"choices": [
			{
				"id": &"patch",
				"label": "AUTHORIZE EMERGENCY PATCH",
				"preview": "Cost $18  ·  +4 obedience  ·  -4% crack risk this shift",
				"outcome": "The ledger was patched. Compliance has declared the smoke intentional.",
				"cost_cents": 1800,
				"tone": &"quality",
			},
			{
				"id": &"spreadsheet",
				"label": "USE THE UNOFFICIAL SPREADSHEET",
				"preview": "No cost  ·  +5% speed  ·  +6% crack risk  ·  -6 obedience",
				"outcome": "An unofficial spreadsheet is now mission-critical and completely unaudited.",
				"cost_cents": 0,
				"tone": &"danger",
			},
		],
	},
	&"wellness_request": {
		"title": "THE FLOCK REQUESTS A REAL BREAK",
		"body": "A hen has noticed that the mandatory wellness zone has never reduced anyone's workload.",
		"choices": [
			{
				"id": &"grant_breaks",
				"label": "COVER A ROTATING BREAK",
				"preview": "Cost $6  ·  -6 stress  ·  -5 fatigue  ·  +4 morale",
				"outcome": "A rotating break was approved and immediately described as a productivity pilot.",
				"cost_cents": 600,
				"tone": &"care",
			},
			{
				"id": &"deny_breaks",
				"label": "DENY THE ATTITUDE VARIANCE",
				"preview": "+3 farmer favor  ·  -6 morale  ·  +6 stress  ·  +2.5% crack risk",
				"outcome": "The request was denied. The flock has been reminded that the wellness poster is the benefit.",
				"cost_cents": 0,
				"tone": &"danger",
			},
		],
	},
	&"farmer_story": {
		"title": "THE FARMER NEEDS A SUCCESS STORY",
		"body": "The presentation basket is due before the results. Reality may now be selected as an optional attachment.",
		"choices": [
			{
				"id": &"polish_story",
				"label": "POLISH THE PRESENTATION BASKET",
				"preview": "+$16 fund  ·  +8 farmer favor  ·  tomorrow's quota +1",
				"outcome": "The presentation has been polished. Tomorrow's target already reflects today's optimism.",
				"cost_cents": 0,
				"tone": &"danger",
			},
			{
				"id": &"show_ledger",
				"label": "SHOW THE ACTUAL LEDGER",
				"preview": "+5 obedience  ·  +6 flock unity  ·  tomorrow's quota -1",
				"outcome": "The actual ledger was attached. The farmer has called this an avoidable transparency event.",
				"cost_cents": 0,
				"tone": &"quality",
			},
		],
	},
	&"feed_shortfall": {
		"title": "THE FEED CONTRACT HAS SHRUNK",
		"body": "The preferred supplier has replaced half the grain with inspirational gravel and a revised logo.",
		"choices": [
			{
				"id": &"buy_grain",
				"label": "BUY LOCAL GRAIN",
				"preview": "Cost $16  ·  +6 morale  ·  -4 stress  ·  -15% strain",
				"outcome": "Local grain arrived. Procurement has opened a review into its suspicious edibility.",
				"cost_cents": 1600,
				"tone": &"care",
			},
			{
				"id": &"optimize_portions",
				"label": "OPTIMIZE THE PORTIONS",
				"preview": "Daily feed -$8  ·  -7 morale  ·  +5 stress  ·  +3% crack risk",
				"outcome": "Portions were optimized. The missing feed has been reclassified as efficiency.",
				"cost_cents": 0,
				"tone": &"danger",
			},
		],
	},
}
const UPGRADE_ORDER: Array[StringName] = [&"peckwork_tools", &"shell_lamp", &"nest_cushion"]
const UPGRADE_DEFINITIONS := {
	&"peckwork_tools": {
		"name": "BEAK-FRIENDLY KEYCAPS",
		"short_name": "KEYCAPS",
		"description": "+8% work speed / level",
		"base_cost_cents": 2500,
		"growth": 1.55,
	},
	&"shell_lamp": {
		"name": "SHELL INTEGRITY LAMP",
		"short_name": "QA LAMP",
		"description": "-2.5% crack risk / level",
		"base_cost_cents": 3200,
		"growth": 1.50,
	},
	&"nest_cushion": {
		"name": "ERGONOMIC NEST PAD",
		"short_name": "NEST PAD",
		"description": "-10% strain gain / level",
		"base_cost_cents": 2800,
		"growth": 1.52,
	},
}
const WORKER_NAMES: Array[String] = [
	"Mabel",
	"Pip",
	"Henrietta",
	"Dot",
	"Agnes",
	"Beatrice",
]
const WORKER_SPECIALTIES: Array[StringName] = [
	&"appeals",
	&"nest_damage",
	&"predator_loss",
	&"nest_damage",
	&"appeals",
	&"predator_loss",
]
const PERSONNEL_ACTION_ORDER: Array[StringName] = [
	&"share_credit",
	&"career_coaching",
	&"quota_pressure",
]
const PERSONNEL_ACTION_DEFINITIONS := {
	&"share_credit": {
		"name": "SHARE BASKET CREDIT",
		"short_name": "SHARE CREDIT",
		"description": "Put the selected hen's name on the farmer's presentation basket.",
		"preview": "-$7.00  /  trust +14  /  grievance -10  /  farmer favor -2",
		"cost_cents": 700,
		"tone": &"care",
	},
	&"career_coaching": {
		"name": "FUND PERCH-SIDE COACHING",
		"short_name": "CAREER COACH",
		"description": "Trade some of today's output for safer work and a large career-XP gain.",
		"preview": "-$4.00  /  +18 XP  /  -6% speed  /  -3% crack risk this shift",
		"cost_cents": 400,
		"tone": &"quality",
	},
	&"quota_pressure": {
		"name": "AUTHORIZE A STRETCH CLUTCH",
		"short_name": "APPLY PRESSURE",
		"description": "Push the selected hen faster this shift and leave the relationship debt for later.",
		"preview": "FREE  /  +14% speed  /  +2.5% crack risk  /  trust -12",
		"cost_cents": 0,
		"tone": &"danger",
	},
}
const CAREER_PROFILE_DEFINITIONS := {
	&"credit_conscious": {
		"name": "CREDIT CONSCIOUS",
		"description": "Remembers whose work reached the farmer's basket.",
		"preferred_action": &"share_credit",
	},
	&"advancement_minded": {
		"name": "ADVANCEMENT MINDED",
		"description": "Responds strongly to funded development and visible progress.",
		"preferred_action": &"career_coaching",
	},
	&"quota_conditioned": {
		"name": "QUOTA CONDITIONED",
		"description": "Converts urgency into speed, while still remembering the strain.",
		"preferred_action": &"quota_pressure",
	},
}
const CREDIT_STYLE_IDS: Array[StringName] = [
	&"individual_merit",
	&"shared_scoop",
	&"management_innovation",
]
const CREDIT_OPTION_IDS: Array[StringName] = [
	&"reward_top_layer",
	&"share_feed_credit",
	&"claim_management_innovation",
	&"name_the_layer",
	&"flock_owned_patent",
	&"patent_rooster_method",
	&"nominate_variance",
	&"fund_redeployment",
	&"contest_ranking",
]
const SENIOR_QUARTER_POLICY_IDS: Array[StringName] = [
	&"merit_grants",
	&"flock_dividend",
	&"harvest_forecast",
]
const SENIOR_QUARTER_POLICY_COSTS := {
	&"merit_grants": 1200,
	&"flock_dividend": 2400,
	&"harvest_forecast": 0,
}
const SENIOR_QUARTER_POLICY_STYLES := {
	&"merit_grants": &"individual_merit",
	&"flock_dividend": &"shared_scoop",
	&"harvest_forecast": &"management_innovation",
}

var workers: Array[ChickenState] = []
var day: int = 1
var minute_of_day: int = SHIFT_START_MINUTE
var claims_waiting: int = 0
var claims_processed: int = 0
var eggs_today: int = 0
var eggs_total: int = 0
var cracked_eggs: int = 0
var cracked_today: int = 0
var golden_eggs: int = 0
var golden_today: int = 0
var revenue_cents: int = 5000
var credited_today_cents: int = 0
var feed_cents_per_day: int = 1800
var quota_target: int = 24
var executive_confidence: float = 52.0
var compliance: float = 78.0
var solidarity: float = 18.0
var overtime_enabled: bool = false
var feed_party_used_today: bool = false
var quality_streak: int = 0
var best_quality_streak: int = 0
var last_streak_bonus_cents: int = 0
var shift_phase: int = ShiftPhase.AWAITING_DIRECTIVE
var active_directive_id: StringName = &""
var pending_decision: Dictionary = {}
var incidents_resolved_today: int = 0
var upgrade_levels: Dictionary = {
	&"peckwork_tools": 0,
	&"shell_lamp": 0,
	&"nest_cushion": 0,
}
var lane_processed_totals: Dictionary = {
	&"nest_damage": 0,
	&"predator_loss": 0,
	&"appeals": 0,
}
var lane_processed_today: Dictionary = {
	&"nest_damage": 0,
	&"predator_loss": 0,
	&"appeals": 0,
}
var campaign_unlocks: Dictionary = {
	&"welfare_breaks": false,
	&"shell_quality_checks": false,
	&"farmer_credit_bonus": false,
}
var office_capacity: int = MAXIMUM_STAFF_CAPACITY
var wage_arrears_cents: int = 0
var last_staffing_action: Dictionary = {}
var last_pecking_order: Array[Dictionary] = []
var last_pecking_order_day: int = 0
var last_credit_allocation: Dictionary = {}
var credit_choice_counts: Dictionary = {
	&"individual_merit": 0,
	&"shared_scoop": 0,
	&"management_innovation": 0,
}
var golden_dossier_resolved: bool = false
var golden_dossier_day: int = 0
var flock_restructuring_resolved: bool = false
var flock_restructuring_day: int = 0
var flock_restructuring_record: Dictionary = {}
var last_flock_petition: Dictionary = {}
var flock_petition_history: Array[Dictionary] = []
var active_flock_compact: Dictionary = {}
var last_flock_compact_receipt: Dictionary = {}
var work_to_rule_day: int = 0
var last_work_to_rule_record: Dictionary = {}
var queued_work_to_rule_day: int = 0
var queued_work_to_rule_record: Dictionary = {}
var peck_assists_used_today: int = 0
var peck_assist_interventions_today: int = 0
var peck_assist_refunds_today: int = 0
var peck_assist_streak: int = 0
var best_peck_assist_streak: int = 0
var last_peck_assist: Dictionary = {}
var last_peck_assist_delivery: Dictionary = {}
var priority_credit_today_cents: int = 0
var priority_credit_total_cents: int = 0

var _tick_count: int = 0
var _rng := RandomNumberGenerator.new()
var _claim_rng := RandomNumberGenerator.new()
var _claim_queues: Dictionary = {}
var _pending_rework: Array[ClaimState] = []
var _next_claim_id: int = 1
var _rework_total_created: int = 0
var _worker_at_workstation: Dictionary[int, bool] = {}
var _worker_shift_stats: Array[Dictionary] = []
var _decision_serial: int = 0
var _incident_slot: int = 0
var _directive_work_multiplier := 1.0
var _directive_fatigue_multiplier := 1.0
var _directive_stress_multiplier := 1.0
var _directive_morale_drain_multiplier := 1.0
var _directive_crack_modifier := 0.0
var _daily_feed_adjustment_cents := 0
var _incident_work_multiplier := 1.0
var _incident_strain_multiplier := 1.0
var _incident_crack_modifier := 0.0
var _incident_golden_modifier := 0.0
var _incident_feed_adjustment_cents := 0
var _pending_quota_adjustment := 0
var _assisted_claim_ids: Dictionary[int, bool] = {}
var _missed_assist_claim_ids: Dictionary[int, bool] = {}
var _assist_quality_modifiers: Dictionary[int, float] = {}
var _assist_chain_by_claim_id: Dictionary[int, int] = {}
var _pending_peck_assist_deliveries: Dictionary[int, Dictionary] = {}
var _settled_peck_assist_delivery_ids: Dictionary[int, bool] = {}


func _init(seed: int = 1701, initial_staff_count: int = MAXIMUM_STAFF_CAPACITY) -> void:
	_rng.seed = seed
	_claim_rng.seed = seed + 104729
	_initialize_claim_queues()
	initial_staff_count = clampi(
		initial_staff_count,
		MINIMUM_STAFF_COUNT,
		MAXIMUM_STAFF_CAPACITY
	)
	office_capacity = initial_staff_count
	for index in WORKER_NAMES.size():
		var worker := ChickenState.new(
			index,
			WORKER_NAMES[index],
			index if index < initial_staff_count else -1,
			_rng.randf_range(0.82, 1.16),
			_rng.randf_range(0.78, 0.97),
			WORKER_SPECIALTIES[index]
		)
		worker.employed = index < initial_staff_count
		worker.available_for_hire_day = 0 if worker.employed else 1
		worker.employment_start_day = 1 if worker.employed else 0
		workers.append(worker)
		_worker_at_workstation[worker.id] = false
	_initialize_worker_shift_stats()
	quota_target = active_worker_count() * 4
	for lane in INITIAL_CLAIM_LANES:
		_enqueue_new_claim(lane)
	_sync_claims_waiting()
	_prepare_morning_directive()


func _initialize_worker_shift_stats() -> void:
	_worker_shift_stats.clear()
	for worker in workers:
		_worker_shift_stats.append(_empty_worker_shift_stat(worker.id))


func _empty_worker_shift_stat(worker_id: int) -> Dictionary:
	return {
		"worker_id": worker_id,
		"eggs": 0,
		"sound": 0,
		"cracked": 0,
		"golden": 0,
		"credit_cents": 0,
	}


func _worker_shift_stat(worker_id: int) -> Dictionary:
	if worker_id < 0 or worker_id >= _worker_shift_stats.size():
		return {}
	return _worker_shift_stats[worker_id]


func _record_worker_shift_result(
	worker_id: int,
	quality: StringName,
	value_cents: int,
) -> void:
	var stats := _worker_shift_stat(worker_id)
	if stats.is_empty():
		return
	stats["eggs"] = int(stats.get("eggs", 0)) + 1
	stats["credit_cents"] = int(stats.get("credit_cents", 0)) + maxi(0, value_cents)
	match quality:
		&"cracked":
			stats["cracked"] = int(stats.get("cracked", 0)) + 1
		&"golden":
			stats["golden"] = int(stats.get("golden", 0)) + 1
		_:
			stats["sound"] = int(stats.get("sound", 0)) + 1


func current_pecking_order() -> Array[Dictionary]:
	## The bureau ranks credit first, then golden eggs, fewer cracks, and finally
	## employee number. The intentionally blunt tie-break is disclosed in the UI.
	var ranking: Array[Dictionary] = []
	for worker in workers:
		if not worker.employed:
			continue
		var stats := _worker_shift_stat(worker.id)
		var credit_cents := maxi(0, int(stats.get("credit_cents", 0)))
		ranking.append({
			"rank": 0,
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"employed": worker.employed,
			"eggs": maxi(0, int(stats.get("eggs", 0))),
			"sound": maxi(0, int(stats.get("sound", 0))),
			"cracked": maxi(0, int(stats.get("cracked", 0))),
			"golden": maxi(0, int(stats.get("golden", 0))),
			"credit_cents": credit_cents,
			"score": credit_cents,
		})
	ranking.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var golden_a := int(a.get("golden", 0))
		var golden_b := int(b.get("golden", 0))
		if golden_a != golden_b:
			return golden_a > golden_b
		var cracked_a := int(a.get("cracked", 0))
		var cracked_b := int(b.get("cracked", 0))
		if cracked_a != cracked_b:
			return cracked_a < cracked_b
		return int(a.get("worker_id", 0)) < int(b.get("worker_id", 0))
	)
	for index in ranking.size():
		ranking[index]["rank"] = index + 1
	return ranking


func _reset_worker_shift_stats() -> void:
	for worker_id in _worker_shift_stats.size():
		_worker_shift_stats[worker_id] = _empty_worker_shift_stat(worker_id)


func leadership_record_snapshot() -> Dictionary:
	var highest := -1
	var leaders: Array[StringName] = []
	var total_choices := 0
	var safe_counts: Dictionary = {}
	for style_id in CREDIT_STYLE_IDS:
		var count := maxi(0, int(credit_choice_counts.get(style_id, 0)))
		safe_counts[String(style_id)] = count
		total_choices += count
		if count > highest:
			highest = count
			leaders.assign([style_id])
		elif count == highest:
			leaders.append(style_id)
	if total_choices == 0:
		return {
			"id": &"unfiled",
			"title": "UNFILED MANAGEMENT STYLE",
			"description": "No closing credit memos have been filed yet.",
			"counts": safe_counts,
		}
	if leaders.size() != 1:
		return {
			"id": &"split_ledger",
			"title": "SPLIT LEDGER",
			"description": "Your file alternates between recognition, solidarity, and executive appropriation.",
			"counts": safe_counts,
		}
	match leaders[0]:
		&"individual_merit":
			return {
				"id": leaders[0],
				"title": "MERITOCRATIC ROOSTER",
				"description": "You reward visible winners and let the ranking motivate everyone else.",
				"counts": safe_counts,
			}
		&"shared_scoop":
			return {
				"id": leaders[0],
				"title": "FLOCK STEWARD",
				"description": "You keep redirecting individual credit back toward the hens who produced it.",
				"counts": safe_counts,
			}
		_:
			return {
				"id": &"management_innovation",
				"title": "CREDIT HARVESTER",
				"description": "You convert the flock's labor into executive confidence and larger future targets.",
				"counts": safe_counts,
			}


func campaign_ending_snapshot(passed: bool) -> Dictionary:
	var record := flock_restructuring_record.duplicate(true)
	var worker_name := String(record.get("worker_name", "the lowest-ranked hen"))
	var option_id := StringName(String(record.get("option_id", "")))
	var base := {
		"passed": passed,
		"option_id": String(option_id),
		"affected_worker_name": worker_name,
		"restructuring_resolved": flock_restructuring_resolved,
		"record": record,
	}
	if not passed:
		base.merge({
			"id": &"probation_terminated",
			"title": "PROBATION TERMINATED",
			"coda": "The farmer thanked the rooster for the eggs, archived the context, and opened a search for more dependable leadership.",
			"consequence": (
				"%s still appears in the restructuring appendix. The rooster does not appear in the next org chart."
				% worker_name
				if flock_restructuring_resolved else
				"The flock keeps the ledger. The farmer keeps the presentation."
			),
		}, true)
		return base
	if not flock_restructuring_resolved:
		base.merge({
			"id": &"probationary_rooster",
			"title": "PROBATION EXTENDED",
			"coda": "The numbers passed, but the final people decision was never filed.",
			"consequence": "The farmer has scheduled another shift and called the uncertainty an engagement opportunity.",
		}, true)
		return base
	match option_id:
		&"nominate_variance":
			base.merge({
				"id": &"farmer_favorite",
				"title": "FARMER'S FAVORITE",
				"coda": "The deck is clean, the quota is higher, and one chair is easier to explain than the conditions that emptied it.",
				"consequence": "%s was converted into recovered capacity. The remaining flock now knows what the ranking is for." % worker_name,
			}, true)
		&"fund_redeployment":
			base.merge({
				"id": &"benevolent_rooster",
				"title": "BENEVOLENT ROOSTER",
				"coda": "You kept the hen, corrected her assignment, and proved that basic support can survive when entered as an exception expense.",
				"consequence": "%s remains in the flock with a better perch and a permanent Finance footnote." % worker_name,
			}, true)
		&"contest_ranking":
			base.merge({
				"id": &"collective_bargaining",
				"title": "THE FLOCK HAS A VOICE",
				"coda": "The ranking was contested, every hen stayed, and the farmer discovered that a workforce can become a subject instead of a spreadsheet.",
				"consequence": "%s keeps her chair. Tomorrow's retaliatory quota arrives addressed to everyone." % worker_name,
			}, true)
		_:
			base.merge({
				"id": &"probationary_rooster",
				"title": "PROBATION EXTENDED",
				"coda": "The numbers passed, but the restructuring ledger no longer reconciles.",
				"consequence": "The farmer has requested a cleaner narrative and another week of evidence.",
			}, true)
	return base


func apply_campaign_unlock(unlock_id: StringName) -> bool:
	if unlock_id not in CAMPAIGN_UNLOCKS:
		return false
	if bool(campaign_unlocks.get(unlock_id, false)):
		return true
	campaign_unlocks[unlock_id] = true
	announcement_posted.emit("PROBATION MILESTONE APPROVED: %s." % String(unlock_id).replace("_", " ").to_upper())
	snapshot_changed.emit(snapshot())
	return true


func has_campaign_unlock(unlock_id: StringName) -> bool:
	return bool(campaign_unlocks.get(unlock_id, false))


func campaign_unlock_effects() -> Dictionary:
	return {
		"stress_gain_percent": -12 if has_campaign_unlock(&"welfare_breaks") else 0,
		"fatigue_gain_percent": -10 if has_campaign_unlock(&"welfare_breaks") else 0,
		"crack_risk_basis_points": -250 if has_campaign_unlock(&"shell_quality_checks") else 0,
		"egg_value_bonus_cents": 25 if has_campaign_unlock(&"farmer_credit_bonus") else 0,
	}


func active_worker_count() -> int:
	var count := 0
	for worker in workers:
		if worker.employed:
			count += 1
	return count


func current_daily_payroll_cents() -> int:
	var payroll := 0
	for worker in workers:
		if worker.employed:
			payroll += worker.daily_wage_cents()
	return payroll


func current_daily_facility_cost_cents() -> int:
	return maxi(0, office_capacity - 4) * FACILITY_COST_PER_EXPANDED_SEAT_CENTS


func current_daily_operating_cost_cents() -> int:
	return (
		current_daily_feed_cost_cents()
		+ current_daily_facility_cost_cents()
		+ current_daily_payroll_cents()
	)


func spendable_fund_cents() -> int:
	## Discretionary actions may only spend money left after today's operating
	## obligations and any unpaid wages have been protected.
	return maxi(
		0,
		revenue_cents - current_daily_operating_cost_cents() - wage_arrears_cents
	)


func career_sponsorship_preflight(worker_id: int, target_lane: StringName) -> Dictionary:
	## Read-only planning check for a single cross-training authorization. Every
	## rejection reason is resolved before the apply API mutates Feed Fund or hen
	## state, so callers can safely refresh this receipt after any review action.
	var spendable := spendable_fund_cents()
	var worker: ChickenState = null
	if worker_id >= 0 and worker_id < workers.size():
		worker = workers[worker_id]
	var primary_specialty := worker.specialty if worker != null else &""
	var secondary_specialty := worker.secondary_specialty if worker != null else &""
	var training_target := worker.cross_training_target if worker != null else &""
	var current_wage := worker.daily_wage_cents() if worker != null else 0
	var accredited_wage := (
		current_wage + ChickenState.CROSS_TRAINING_WAGE_BONUS_CENTS
		if worker != null and not worker.has_secondary_specialty() else
		current_wage
	)
	var reason := ""
	if worker == null:
		reason = "Career Sponsorship requires a recognized hen file."
	elif target_lane not in CLAIM_LANES:
		reason = "Career Sponsorship requires a supported peckwork lane."
	elif shift_phase != ShiftPhase.REVIEW:
		reason = "Career Sponsorship may only be authorized during review planning."
	elif not worker.employed:
		reason = "Career Sponsorship requires an employed hen."
	elif worker.career_level() < 1:
		reason = "%s must reach Accredited Layer before cross-training." % worker.display_name
	elif worker.has_secondary_specialty():
		reason = "%s already holds a permanent secondary specialty." % worker.display_name
	elif worker.cross_training_pending():
		reason = "%s already has a cross-training file in progress." % worker.display_name
	elif target_lane == worker.specialty:
		reason = "%s is already accredited in %s." % [
			worker.display_name,
			_lane_display_name(worker.specialty),
		]
	elif spendable < CAREER_SPONSORSHIP_COST_CENTS:
		reason = "Career Sponsorship denied: $%.2f more spendable Feed Fund required." % (
			float(CAREER_SPONSORSHIP_COST_CENTS - spendable) / 100.0
		)
	return {
		"available": reason.is_empty(),
		"reason": reason,
		"worker_id": worker_id,
		"worker_name": worker.display_name if worker != null else "",
		"target_lane": target_lane,
		"primary_specialty": primary_specialty,
		"secondary_specialty": secondary_specialty,
		"cross_training_target": training_target,
		"cost_cents": CAREER_SPONSORSHIP_COST_CENTS,
		"spendable_fund_cents": spendable,
		"training_work_multiplier": ChickenState.CROSS_TRAINING_WORK_MULTIPLIER,
		"current_daily_wage_cents": current_wage,
		"accredited_daily_wage_cents": accredited_wage,
	}


func authorize_career_sponsorship(worker_id: int, target_lane: StringName) -> Dictionary:
	## Applies the preflight atomically. The target remains pending through the
	## next shift the hen actually works, then becomes her permanent secondary
	## specialty at that shift's close.
	var preflight := career_sponsorship_preflight(worker_id, target_lane)
	if not bool(preflight.get("available", false)):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		return rejection
	var worker := workers[worker_id]
	if not worker.begin_cross_training(target_lane):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		rejection["reason"] = "Career Sponsorship could not open the requested training file."
		return rejection

	var fund_before := revenue_cents
	revenue_cents -= CAREER_SPONSORSHIP_COST_CENTS
	var outcome := (
		"Career Sponsorship approved for %s. %s training will reduce her next worked shift by 15%%."
		% [worker.display_name, _lane_display_name(target_lane)]
	)
	var result := preflight.duplicate(true)
	result.merge({
		"accepted": true,
		"action_id": &"career_sponsorship",
		"day": day,
		"fund_delta_cents": revenue_cents - fund_before,
		"training_shift_day": day,
		"spendable_fund_cents": spendable_fund_cents(),
		"outcome": outcome,
	}, true)
	career_sponsorship_resolved.emit(result.duplicate(true))
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return result


func apply_senior_quarter_policy(policy_id: StringName) -> Dictionary:
	## Applies one Senior Roost quarterly policy to the authoritative economy.
	## All validation happens before the first mutation so rejected policies are
	## safe to retry after the review UI has refreshed.
	if policy_id not in SENIOR_QUARTER_POLICY_IDS:
		return _rejected_senior_action("That quarterly policy is not on the Senior Roost docket.")
	if shift_phase != ShiftPhase.REVIEW:
		return _rejected_senior_action("Quarterly policy may only be filed during shift review.")
	if not pending_decision.is_empty():
		return _rejected_senior_action("Resolve the closing credit memo before filing quarterly policy.")

	var cost_cents := int(SENIOR_QUARTER_POLICY_COSTS[policy_id])
	if spendable_fund_cents() < cost_cents:
		return _rejected_senior_action(
			"Quarterly policy denied: $%.2f more spendable Feed Fund required." % (
				float(cost_cents - spendable_fund_cents()) / 100.0
			)
		)
	var merit_worker: ChickenState = null
	if policy_id == &"merit_grants":
		merit_worker = _senior_top_employed_worker()
	if policy_id == &"merit_grants" and merit_worker == null:
		return _rejected_senior_action("Merit grants require at least one employed hen.")

	var before_revenue := revenue_cents
	var before_farmer_favor := executive_confidence
	var before_compliance := compliance
	var before_solidarity := solidarity
	var before_quota := quota_target
	var worker_effects: Array[Dictionary] = []
	var target_worker_id := -1
	var target_worker_name := ""
	var promoted := false
	var outcome := ""
	revenue_cents -= cost_cents

	match policy_id:
		&"merit_grants":
			target_worker_id = merit_worker.id
			target_worker_name = merit_worker.display_name
			var before_worker := _senior_worker_effect_snapshot(merit_worker)
			promoted = merit_worker.add_career_xp(18)
			merit_worker.morale = clampf(merit_worker.morale + 8.0, 0.0, 100.0)
			merit_worker.manager_trust = clampf(merit_worker.manager_trust + 10.0, 0.0, 100.0)
			merit_worker.grievance = clampf(merit_worker.grievance - 8.0, 0.0, 100.0)
			worker_effects.append(_senior_worker_effect_receipt(merit_worker, before_worker))
			compliance = clampf(compliance + 4.0, 0.0, 100.0)
			executive_confidence = clampf(executive_confidence - 2.0, 0.0, 100.0)
			outcome = "%s received the quarterly merit grant. Compliance has approved the beak." % merit_worker.display_name
		&"flock_dividend":
			for worker in workers:
				if not worker.employed:
					continue
				var before_worker := _senior_worker_effect_snapshot(worker)
				worker.morale = clampf(worker.morale + 6.0, 0.0, 100.0)
				worker.stress = clampf(worker.stress - 6.0, 0.0, 100.0)
				worker.fatigue = clampf(worker.fatigue - 6.0, 0.0, 100.0)
				worker.manager_trust = clampf(worker.manager_trust + 6.0, 0.0, 100.0)
				worker.grievance = clampf(worker.grievance - 6.0, 0.0, 100.0)
				worker_effects.append(_senior_worker_effect_receipt(worker, before_worker))
			solidarity = clampf(solidarity + 10.0, 0.0, 100.0)
			executive_confidence = clampf(executive_confidence - 6.0, 0.0, 100.0)
			quota_target = clampi(quota_target - 1, 1, 10_000)
			outcome = "The flock dividend was distributed. The farmer has requested a narrower definition of morale."
		&"harvest_forecast":
			revenue_cents += 2400
			executive_confidence = clampf(executive_confidence + 8.0, 0.0, 100.0)
			quota_target = clampi(quota_target + 3, 1, 10_000)
			compliance = clampf(compliance - 5.0, 0.0, 100.0)
			for worker in workers:
				if not worker.employed:
					continue
				var before_worker := _senior_worker_effect_snapshot(worker)
				worker.stress = clampf(worker.stress + 4.0, 0.0, 100.0)
				worker.manager_trust = clampf(worker.manager_trust - 5.0, 0.0, 100.0)
				worker.grievance = clampf(worker.grievance + 6.0, 0.0, 100.0)
				worker_effects.append(_senior_worker_effect_receipt(worker, before_worker))
			outcome = "Management filed next quarter's harvest before the hens produced it."

	var style_id := StringName(SENIOR_QUARTER_POLICY_STYLES[policy_id])
	credit_choice_counts[style_id] = int(credit_choice_counts.get(style_id, 0)) + 1
	var effects := {
		"fund_cents": revenue_cents - before_revenue,
		"farmer_favor": executive_confidence - before_farmer_favor,
		"compliance": compliance - before_compliance,
		"solidarity": solidarity - before_solidarity,
		"quota": quota_target - before_quota,
	}
	var result := {
		"accepted": true,
		"action_id": policy_id,
		"policy_id": policy_id,
		"style_id": style_id,
		"day": maxi(1, day - 1),
		"cost_cents": cost_cents,
		"fund_delta_cents": int(effects["fund_cents"]),
		"farmer_favor_delta": float(effects["farmer_favor"]),
		"compliance_delta": float(effects["compliance"]),
		"solidarity_delta": float(effects["solidarity"]),
		"quota_delta": int(effects["quota"]),
		"worker_id": target_worker_id,
		"worker_name": target_worker_name,
		"workers_affected": worker_effects.size(),
		"worker_effects": worker_effects,
		"promoted": promoted,
		"career_title": merit_worker.career_title() if merit_worker != null else "",
		"effects": effects,
		"spendable_fund_cents": spendable_fund_cents(),
		"outcome": outcome,
	}
	announcement_posted.emit(outcome)
	if promoted:
		announcement_posted.emit(
			"PROMOTION FILED: %s is now %s." % [target_worker_name.to_upper(), merit_worker.career_title()]
		)
	snapshot_changed.emit(snapshot())
	return result


func apply_senior_year_transition(previous_year_passed: bool) -> Dictionary:
	## Applies the annual performance consequence before the next Senior Roost
	## year begins. The caller owns the calendar; this method owns the economy.
	if shift_phase != ShiftPhase.REVIEW:
		return _rejected_senior_action("Annual transition may only be filed during shift review.")
	if not pending_decision.is_empty():
		return _rejected_senior_action("Resolve the closing credit memo before filing the annual transition.")
	var before_quota := quota_target
	var before_farmer_favor := executive_confidence
	quota_target = clampi(quota_target + (1 if previous_year_passed else 2), 1, 10_000)
	if not previous_year_passed:
		executive_confidence = clampf(executive_confidence - 5.0, 0.0, 100.0)
	var outcome := (
		"The annual review passed. Next year's baseline rises by one egg."
		if previous_year_passed else
		"The annual review failed. The farmer raised next year's baseline and lowered management favor."
	)
	var result := {
		"accepted": true,
		"action_id": &"senior_year_transition",
		"previous_year_passed": previous_year_passed,
		"day": maxi(1, day - 1),
		"cost_cents": 0,
		"fund_delta_cents": 0,
		"quota_delta": quota_target - before_quota,
		"farmer_favor_delta": executive_confidence - before_farmer_favor,
		"outcome": outcome,
	}
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return result


func _rejected_senior_action(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


func _senior_top_employed_worker() -> ChickenState:
	for row in last_pecking_order:
		var worker_id := int(row.get("worker_id", -1))
		if worker_id < 0 or worker_id >= workers.size():
			continue
		if workers[worker_id].employed:
			return workers[worker_id]
	var fallback: ChickenState = null
	for worker in workers:
		if not worker.employed:
			continue
		if fallback == null or worker.id < fallback.id:
			fallback = worker
	return fallback


func _senior_worker_effect_snapshot(worker: ChickenState) -> Dictionary:
	return {
		"career_xp": worker.career_xp,
		"morale": worker.morale,
		"stress": worker.stress,
		"fatigue": worker.fatigue,
		"manager_trust": worker.manager_trust,
		"grievance": worker.grievance,
	}


func _senior_worker_effect_receipt(worker: ChickenState, before: Dictionary) -> Dictionary:
	return {
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"career_xp": worker.career_xp - int(before["career_xp"]),
		"morale": worker.morale - float(before["morale"]),
		"stress": worker.stress - float(before["stress"]),
		"fatigue": worker.fatigue - float(before["fatigue"]),
		"manager_trust": worker.manager_trust - float(before["manager_trust"]),
		"grievance": worker.grievance - float(before["grievance"]),
	}


func staffing_planning_open() -> bool:
	return shift_phase == ShiftPhase.REVIEW


func staffing_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	var action_available := staffing_planning_open() and not _staffing_action_used_today()
	var active_count := active_worker_count()
	var vacant_desk := _lowest_vacant_desk()
	var spendable := spendable_fund_cents()
	for worker in workers:
		var hire_cost := worker.hire_cost_cents()
		var release_cost := worker.release_cost_cents()
		catalog.append({
			"id": worker.id,
			"name": worker.display_name,
			"employed": worker.employed,
			"employment_status": worker.employment_status(),
			"desk_index": worker.desk_index,
			"available_for_hire_day": worker.available_for_hire_day,
			"hire_count": worker.hire_count,
			"employment_start_day": worker.employment_start_day,
			"career_level": worker.career_level(),
			"career_title": worker.career_title(),
			"career_profile": worker.career_profile,
			"specialty": worker.specialty,
			"skill": worker.skill,
			"accuracy": worker.accuracy,
			"daily_wage_cents": worker.daily_wage_cents(),
			"hire_cost_cents": hire_cost,
			"release_cost_cents": release_cost,
			"can_hire": (
				action_available
				and not worker.employed
				and worker.available_for_hire_day <= day
				and active_count < office_capacity
				and vacant_desk >= 0
				and spendable >= hire_cost
			),
			"can_release": (
				action_available
				and worker.employed
				and active_count > MINIMUM_STAFF_COUNT
				and worker.work_state == ChickenState.WorkState.IDLE
				and worker.current_claim == null
				and spendable >= release_cost
			),
			"reason": _staffing_worker_action_reason(worker),
		})
	return catalog


func capacity_upgrade_status() -> Dictionary:
	var planning_open := staffing_planning_open()
	var cost := _capacity_upgrade_cost_cents()
	var available := office_capacity < MAXIMUM_STAFF_CAPACITY and cost >= 0
	var affordable := available and spendable_fund_cents() >= cost
	var reason := ""
	if office_capacity >= MAXIMUM_STAFF_CAPACITY:
		reason = "Every authorized workstation is already open."
	elif cost < 0:
		reason = "No expansion schedule exists for this office tier."
	elif not planning_open:
		reason = "Capacity plans are filed during shift review."
	elif not affordable:
		reason = "Expansion requires $%.2f more spendable Feed Fund." % (
			float(cost - spendable_fund_cents()) / 100.0
		)
	return {
		"available": available,
		"planning_open": planning_open,
		"current_capacity": office_capacity,
		"next_capacity": mini(MAXIMUM_STAFF_CAPACITY, office_capacity + 1),
		"maximum_capacity": MAXIMUM_STAFF_CAPACITY,
		"cost_cents": maxi(0, cost),
		"affordable": affordable,
		"reason": reason,
	}


func purchase_staff_capacity() -> Dictionary:
	if not staffing_planning_open():
		return _rejected_staffing_action("Capacity plans are filed during shift review.")
	if office_capacity >= MAXIMUM_STAFF_CAPACITY:
		return _rejected_staffing_action("Every authorized workstation is already open.")
	var cost := _capacity_upgrade_cost_cents()
	if cost < 0:
		return _rejected_staffing_action("No expansion schedule exists for this office tier.")
	var spendable := spendable_fund_cents()
	if spendable < cost:
		return _rejected_staffing_action(
			"Expansion denied: $%.2f more spendable Feed Fund required." % (
				float(cost - spendable) / 100.0
			)
		)
	var previous_capacity := office_capacity
	revenue_cents -= cost
	office_capacity += 1
	var result := {
		"accepted": true,
		"action_id": "expand_capacity",
		"day": day,
		"cost_cents": cost,
		"previous_capacity": previous_capacity,
		"office_capacity": office_capacity,
		"maximum_capacity": MAXIMUM_STAFF_CAPACITY,
		"active_staff_count": active_worker_count(),
		"spendable_fund_cents": spendable_fund_cents(),
		"outcome": "A new workstation was authorized before anyone asked who would supervise it.",
	}
	office_capacity_changed.emit(office_capacity, cost)
	staffing_action_resolved.emit(result.duplicate(true))
	announcement_posted.emit(String(result["outcome"]))
	snapshot_changed.emit(snapshot())
	return result


func hire_worker(worker_id: int) -> Dictionary:
	if not staffing_planning_open():
		return _rejected_staffing_action("Hiring files are accepted during shift review.")
	if _staffing_action_used_today():
		return _rejected_staffing_action("Today's hire or release file is already closed.")
	if worker_id < 0 or worker_id >= workers.size():
		return _rejected_staffing_action("Select a valid applicant before filing a hire.")
	var worker := workers[worker_id]
	if worker.employed:
		return _rejected_staffing_action("That hen is already on the active roster.")
	if worker.available_for_hire_day > day:
		return _rejected_staffing_action(
			"That applicant may reapply on day %d." % worker.available_for_hire_day
		)
	if active_worker_count() >= office_capacity:
		return _rejected_staffing_action("No authorized workstation is vacant.")
	var desk := _lowest_vacant_desk()
	if desk < 0:
		return _rejected_staffing_action("No authorized workstation is vacant.")
	var cost := worker.hire_cost_cents()
	var spendable := spendable_fund_cents()
	if spendable < cost:
		return _rejected_staffing_action(
			"Hire denied: $%.2f more spendable Feed Fund required." % (
				float(cost - spendable) / 100.0
			)
		)

	revenue_cents -= cost
	worker.employed = true
	worker.desk_index = desk
	worker.available_for_hire_day = 0
	worker.hire_count += 1
	worker.employment_start_day = day
	worker.assigned_lane = AUTO_ASSIGNMENT
	worker.current_claim = null
	worker.work_state = ChickenState.WorkState.IDLE
	worker.work_progress = 0.0
	worker.state_ticks_remaining = 0
	worker.morale = minf(100.0, worker.morale + 5.0)
	worker.manager_trust = minf(100.0, worker.manager_trust + 3.0)
	worker.grievance = maxf(0.0, worker.grievance - 3.0)
	_worker_at_workstation[worker.id] = false
	var outcome := "%s joined workstation %d. Payroll has noticed." % [
		worker.display_name,
		desk + 1,
	]
	var result := {
		"accepted": true,
		"action_id": "hire_worker",
		"day": day,
		"cost_cents": cost,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"desk_index": desk,
		"active_staff_count": active_worker_count(),
		"office_capacity": office_capacity,
		"daily_wage_cents": worker.daily_wage_cents(),
		"spendable_fund_cents": spendable_fund_cents(),
		"outcome": outcome,
	}
	last_staffing_action = result.duplicate(true)
	staffing_action_resolved.emit(result.duplicate(true))
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return result


func release_worker(worker_id: int) -> Dictionary:
	if not staffing_planning_open():
		return _rejected_staffing_action("Release files are accepted during shift review.")
	if _staffing_action_used_today():
		return _rejected_staffing_action("Today's hire or release file is already closed.")
	if worker_id < 0 or worker_id >= workers.size():
		return _rejected_staffing_action("Select a valid active hen before filing a release.")
	var worker := workers[worker_id]
	if not worker.employed:
		return _rejected_staffing_action("That hen is already outside the active roster.")
	if (
		StringName(pending_decision.get("id", &"")) == &"flock_restructuring"
		and int(pending_decision.get("subject_worker_id", -1)) == worker_id
	):
		return _rejected_staffing_action("This hen is locked to the pending restructuring dossier.")
	if active_worker_count() <= MINIMUM_STAFF_COUNT:
		return _rejected_staffing_action("The office must retain at least three active hens.")
	if worker.work_state != ChickenState.WorkState.IDLE or worker.current_claim != null:
		return _rejected_staffing_action("Finish or return the hen's active peckwork first.")
	var cost := worker.release_cost_cents()
	var spendable := spendable_fund_cents()
	if spendable < cost:
		return _rejected_staffing_action(
			"Release denied: $%.2f more spendable Feed Fund required for the package." % (
				float(cost - spendable) / 100.0
			)
		)

	var released_desk := worker.desk_index
	revenue_cents -= cost
	worker.employed = false
	worker.desk_index = -1
	worker.available_for_hire_day = mini(10000, day + 1)
	worker.employment_start_day = 0
	worker.assigned_lane = AUTO_ASSIGNMENT
	worker.current_claim = null
	worker.work_state = ChickenState.WorkState.IDLE
	worker.work_progress = 0.0
	worker.state_ticks_remaining = 0
	_worker_at_workstation[worker.id] = false
	for remaining_worker in workers:
		if not remaining_worker.employed:
			continue
		remaining_worker.morale = maxf(0.0, remaining_worker.morale - 4.0)
		remaining_worker.manager_trust = maxf(0.0, remaining_worker.manager_trust - 6.0)
		remaining_worker.grievance = minf(100.0, remaining_worker.grievance + 8.0)
	solidarity = minf(100.0, solidarity + 5.0)
	var compact_breached := _breach_compact_for_sponsor_release(worker.id)
	var outcome := "%s's chair is now described as an efficiency gain." % worker.display_name
	var result := {
		"accepted": true,
		"action_id": "release_worker",
		"day": day,
		"cost_cents": cost,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"desk_index": released_desk,
		"active_staff_count": active_worker_count(),
		"office_capacity": office_capacity,
		"available_for_hire_day": worker.available_for_hire_day,
		"compact_breached": compact_breached,
		"spendable_fund_cents": spendable_fund_cents(),
		"outcome": outcome,
	}
	last_staffing_action = result.duplicate(true)
	staffing_action_resolved.emit(result.duplicate(true))
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return result


func _rejected_staffing_action(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


func _staffing_action_used_today() -> bool:
	return (
		not last_staffing_action.is_empty()
		and int(last_staffing_action.get("day", 0)) == day
	)


func _staffing_actions_for_day(target_day: int) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if (
		not last_staffing_action.is_empty()
		and int(last_staffing_action.get("day", 0)) == target_day
	):
		actions.append(last_staffing_action.duplicate(true))
	return actions


func _staffing_worker_action_reason(worker: ChickenState) -> String:
	if not staffing_planning_open():
		return "Staffing files are accepted during shift review."
	if _staffing_action_used_today():
		return "Today's hire or release file is already closed."
	if worker.employed:
		if active_worker_count() <= MINIMUM_STAFF_COUNT:
			return "The office must retain at least three active hens."
		if worker.work_state != ChickenState.WorkState.IDLE or worker.current_claim != null:
			return "Finish or return this hen's active peckwork first."
		if spendable_fund_cents() < worker.release_cost_cents():
			return "The release package exceeds spendable Feed Fund."
		return ""
	if worker.available_for_hire_day > day:
		return "This applicant may reapply on day %d." % worker.available_for_hire_day
	if active_worker_count() >= office_capacity or _lowest_vacant_desk() < 0:
		return "No authorized workstation is vacant."
	if spendable_fund_cents() < worker.hire_cost_cents():
		return "The hiring package exceeds spendable Feed Fund."
	return ""


func _lowest_vacant_desk() -> int:
	var occupied: Dictionary[int, bool] = {}
	for worker in workers:
		if worker.employed:
			occupied[worker.desk_index] = true
	for desk_index in office_capacity:
		if not occupied.has(desk_index):
			return desk_index
	return -1


func _capacity_upgrade_cost_cents() -> int:
	return int(CAPACITY_UPGRADE_COSTS.get(office_capacity, -1))


func _peck_assist_charges_available() -> int:
	return clampi(PECK_ASSIST_LIMIT - peck_assists_used_today, 0, PECK_ASSIST_LIMIT)


func _pending_peck_assist_delivery_snapshot() -> Array[Dictionary]:
	var claim_ids: Array[int] = []
	for claim_id in _pending_peck_assist_deliveries:
		claim_ids.append(int(claim_id))
	claim_ids.sort()
	var deliveries: Array[Dictionary] = []
	for claim_id in claim_ids:
		deliveries.append((_pending_peck_assist_deliveries[claim_id] as Dictionary).duplicate(true))
	return deliveries


func _settled_peck_assist_delivery_snapshot() -> Array[int]:
	var claim_ids: Array[int] = []
	for claim_id in _settled_peck_assist_delivery_ids:
		claim_ids.append(int(claim_id))
	claim_ids.sort()
	return claim_ids


func export_save_state() -> Dictionary:
	## This is the authoritative simulation checkpoint. It intentionally contains
	## only primitives so the campaign save remains portable to Web builds.
	var saved_queues: Dictionary = {}
	for lane in CLAIM_LANES:
		var saved_lane: Array[Dictionary] = []
		for claim_value in (_claim_queues.get(lane, []) as Array):
			var claim := claim_value as ClaimState
			if claim != null:
				saved_lane.append(claim.to_save_data())
		saved_queues[String(lane)] = saved_lane
	var saved_rework: Array[Dictionary] = []
	for claim in _pending_rework:
		if claim != null:
			saved_rework.append(claim.to_save_data())
	var saved_workers: Array[Dictionary] = []
	for worker in workers:
		saved_workers.append(worker.to_save_data())
	var saved_upgrades: Dictionary = {}
	for upgrade_id in UPGRADE_ORDER:
		saved_upgrades[String(upgrade_id)] = upgrade_level(upgrade_id)
	var saved_lane_totals: Dictionary = {}
	var saved_lane_today: Dictionary = {}
	for lane in CLAIM_LANES:
		saved_lane_totals[String(lane)] = int(lane_processed_totals.get(lane, 0))
		saved_lane_today[String(lane)] = int(lane_processed_today.get(lane, 0))
	var saved_unlocks: Dictionary = {}
	for unlock_id in CAMPAIGN_UNLOCKS:
		saved_unlocks[String(unlock_id)] = has_campaign_unlock(unlock_id)
	var saved_credit_counts: Dictionary = {}
	for style_id in CREDIT_STYLE_IDS:
		saved_credit_counts[String(style_id)] = maxi(
			0,
			int(credit_choice_counts.get(style_id, 0)),
		)
	var saved_assisted_claim_ids: Array[int] = []
	for claim_id in _assisted_claim_ids:
		saved_assisted_claim_ids.append(int(claim_id))
	saved_assisted_claim_ids.sort()
	var saved_missed_claim_ids: Array[int] = []
	for claim_id in _missed_assist_claim_ids:
		saved_missed_claim_ids.append(int(claim_id))
	saved_missed_claim_ids.sort()
	var saved_assist_quality: Dictionary = {}
	for claim_id in _assist_quality_modifiers:
		saved_assist_quality[str(claim_id)] = float(_assist_quality_modifiers[claim_id])
	var saved_assist_chains: Dictionary = {}
	for claim_id in _assist_chain_by_claim_id:
		saved_assist_chains[str(claim_id)] = int(_assist_chain_by_claim_id[claim_id])
	return {
		"state_version": SAVE_STATE_VERSION,
		"day": day,
		"minute_of_day": minute_of_day,
		"claims_processed": claims_processed,
		"eggs_today": eggs_today,
		"eggs_total": eggs_total,
		"cracked_eggs": cracked_eggs,
		"cracked_today": cracked_today,
		"golden_eggs": golden_eggs,
		"golden_today": golden_today,
		"revenue_cents": revenue_cents,
		"credited_today_cents": credited_today_cents,
		"feed_cents_per_day": feed_cents_per_day,
		"quota_target": quota_target,
		"executive_confidence": executive_confidence,
		"compliance": compliance,
		"solidarity": solidarity,
		"overtime_enabled": overtime_enabled,
		"feed_party_used_today": feed_party_used_today,
		"quality_streak": quality_streak,
		"best_quality_streak": best_quality_streak,
		"last_streak_bonus_cents": last_streak_bonus_cents,
		"shift_phase": shift_phase,
		"active_directive_id": String(active_directive_id),
		"pending_decision": pending_decision.duplicate(true),
		"incidents_resolved_today": incidents_resolved_today,
		"upgrade_levels": saved_upgrades,
		"lane_processed_totals": saved_lane_totals,
		"lane_processed_today": saved_lane_today,
		"campaign_unlocks": saved_unlocks,
		"office_capacity": office_capacity,
		"wage_arrears_cents": wage_arrears_cents,
		"last_staffing_action": last_staffing_action.duplicate(true),
		"worker_shift_stats": _worker_shift_stats.duplicate(true),
		"last_pecking_order": last_pecking_order.duplicate(true),
		"last_pecking_order_day": last_pecking_order_day,
		"last_credit_allocation": last_credit_allocation.duplicate(true),
		"credit_choice_counts": saved_credit_counts,
		"golden_dossier_resolved": golden_dossier_resolved,
		"golden_dossier_day": golden_dossier_day,
		"flock_restructuring_resolved": flock_restructuring_resolved,
		"flock_restructuring_day": flock_restructuring_day,
		"flock_restructuring_record": flock_restructuring_record.duplicate(true),
		"last_flock_petition": last_flock_petition.duplicate(true),
		"flock_petition_history": flock_petition_history.duplicate(true),
		"active_flock_compact": active_flock_compact.duplicate(true),
		"last_flock_compact_receipt": last_flock_compact_receipt.duplicate(true),
		"work_to_rule_day": work_to_rule_day,
		"last_work_to_rule_record": last_work_to_rule_record.duplicate(true),
		"queued_work_to_rule_day": queued_work_to_rule_day,
		"queued_work_to_rule_record": queued_work_to_rule_record.duplicate(true),
		"peck_assists_used_today": peck_assists_used_today,
		"peck_assist_interventions_today": peck_assist_interventions_today,
		"peck_assist_refunds_today": peck_assist_refunds_today,
		"peck_assist_streak": peck_assist_streak,
		"best_peck_assist_streak": best_peck_assist_streak,
		"last_peck_assist": last_peck_assist.duplicate(true),
		"last_peck_assist_delivery": last_peck_assist_delivery.duplicate(true),
		"priority_credit_today_cents": priority_credit_today_cents,
		"priority_credit_total_cents": priority_credit_total_cents,
		"assisted_claim_ids": saved_assisted_claim_ids,
		"missed_assist_claim_ids": saved_missed_claim_ids,
		"assist_quality_modifiers": saved_assist_quality,
		"assist_chain_by_claim_id": saved_assist_chains,
		"pending_peck_assist_deliveries": _pending_peck_assist_delivery_snapshot(),
		"settled_peck_assist_delivery_ids": _settled_peck_assist_delivery_snapshot(),
		"tick_count": _tick_count,
		"next_claim_id": _next_claim_id,
		"rework_total_created": _rework_total_created,
		"decision_serial": _decision_serial,
		"incident_slot": _incident_slot,
		"rng_state": str(_rng.state),
		"claim_rng_state": str(_claim_rng.state),
		"decision_modifiers": {
			"directive_work_multiplier": _directive_work_multiplier,
			"directive_fatigue_multiplier": _directive_fatigue_multiplier,
			"directive_stress_multiplier": _directive_stress_multiplier,
			"directive_morale_drain_multiplier": _directive_morale_drain_multiplier,
			"directive_crack_modifier": _directive_crack_modifier,
			"daily_feed_adjustment_cents": _daily_feed_adjustment_cents,
			"incident_work_multiplier": _incident_work_multiplier,
			"incident_strain_multiplier": _incident_strain_multiplier,
			"incident_crack_modifier": _incident_crack_modifier,
			"incident_golden_modifier": _incident_golden_modifier,
			"incident_feed_adjustment_cents": _incident_feed_adjustment_cents,
			"pending_quota_adjustment": _pending_quota_adjustment,
		},
		"claim_queues": saved_queues,
		"pending_rework": saved_rework,
		"workers": saved_workers,
	}


func restore_save_state(data: Dictionary) -> bool:
	## Rebuild reference data before mutating this simulation. A damaged checkpoint
	## therefore fails closed and leaves the current session playable.
	var migrated_data := _migrate_save_state(data)
	if migrated_data.is_empty():
		return false
	data = migrated_data
	var worker_values: Variant = data.get("workers", [])
	var queue_values: Variant = data.get("claim_queues", {})
	var rework_values: Variant = data.get("pending_rework", [])
	if not worker_values is Array or not queue_values is Dictionary or not rework_values is Array:
		return false
	var worker_data: Array = worker_values as Array
	if worker_data.size() != workers.size():
		return false
	if not _is_integral_number(data.get("day", null)):
		return false
	var saved_day := int(data.get("day", 1))
	if saved_day < 1 or saved_day > 9999:
		return false
	if not _is_integral_number(data.get("office_capacity", null)):
		return false
	var saved_office_capacity := int(data.get("office_capacity", -1))
	if (
		saved_office_capacity < MINIMUM_STAFF_COUNT
		or saved_office_capacity > MAXIMUM_STAFF_CAPACITY
	):
		return false
	if not _is_integral_number(data.get("wage_arrears_cents", null)):
		return false
	var saved_wage_arrears := int(data.get("wage_arrears_cents", -1))
	if saved_wage_arrears < 0 or saved_wage_arrears > 2_000_000_000:
		return false
	var saved_staffing_action_value: Variant = data.get("last_staffing_action", {})
	if not saved_staffing_action_value is Dictionary:
		return false
	var restored_staffing_action := (
		(saved_staffing_action_value as Dictionary).duplicate(true)
	)
	if not _is_valid_staffing_action_data(restored_staffing_action, saved_day):
		return false
	restored_staffing_action = _normalized_staffing_action_data(restored_staffing_action)
	var restored_shift_stats := _restore_worker_shift_stats(data.get("worker_shift_stats", []))
	if restored_shift_stats.size() != workers.size():
		return false
	if not _is_integral_number(data.get("last_pecking_order_day", null)):
		return false
	var restored_order_day := int(data.get("last_pecking_order_day", -1))
	var validated_order := _validated_pecking_order_data(
		data.get("last_pecking_order", []),
	)
	if not bool(validated_order.get("valid", false)):
		return false
	var restored_order := validated_order.get("rows", []) as Array[Dictionary]
	if (
		(restored_order.is_empty() and restored_order_day != 0)
		or (not restored_order.is_empty() and (
			restored_order_day < 1 or restored_order_day > saved_day
		))
	):
		return false
	var restored_credit_counts := _validated_credit_counts(
		data.get("credit_choice_counts", {}),
	)
	if restored_credit_counts.size() != CREDIT_STYLE_IDS.size():
		return false
	var validated_allocation := _validated_credit_allocation(
		data.get("last_credit_allocation", {}),
		saved_day,
	)
	if not bool(validated_allocation.get("valid", false)):
		return false
	var restored_credit_allocation := (
		validated_allocation.get("record", {}) as Dictionary
	)
	if (
		not restored_credit_allocation.is_empty()
		and restored_order_day > 0
		and int(restored_credit_allocation.get("day", 0)) > restored_order_day
	):
		return false
	if typeof(data.get("golden_dossier_resolved", null)) != TYPE_BOOL:
		return false
	if not _is_integral_number(data.get("golden_dossier_day", null)):
		return false
	var restored_golden_resolved := bool(data.get("golden_dossier_resolved", false))
	var restored_golden_day := int(data.get("golden_dossier_day", -1))
	if (
		(restored_golden_resolved and (
			restored_golden_day < 1 or restored_golden_day > saved_day
		))
		or (not restored_golden_resolved and restored_golden_day != 0)
	):
		return false
	var restored_restructuring_resolved_value: Variant = data.get(
		"flock_restructuring_resolved",
		false,
	)
	var restored_restructuring_day_value: Variant = data.get("flock_restructuring_day", 0)
	var restored_restructuring_record_value: Variant = data.get("flock_restructuring_record", {})
	if (
		typeof(restored_restructuring_resolved_value) != TYPE_BOOL
		or not _is_integral_number(restored_restructuring_day_value)
		or not restored_restructuring_record_value is Dictionary
	):
		return false
	var restored_restructuring_resolved := bool(restored_restructuring_resolved_value)
	var restored_restructuring_day := int(restored_restructuring_day_value)
	var validated_restructuring := _validated_restructuring_record(
		restored_restructuring_record_value,
		saved_day,
	)
	if not bool(validated_restructuring.get("valid", false)):
		return false
	var restored_restructuring_record := (
		validated_restructuring.get("record", {}) as Dictionary
	)
	if (
		(restored_restructuring_resolved and (
			restored_restructuring_day != FLOCK_RESTRUCTURING_SHIFT
			or restored_restructuring_record.is_empty()
			or int(restored_restructuring_record.get("day", 0)) != restored_restructuring_day
		))
		or (not restored_restructuring_resolved and (
			restored_restructuring_day != 0
			or not restored_restructuring_record.is_empty()
		))
	):
		return false
	var validated_petition := _validated_flock_petition_record(
		data.get("last_flock_petition", {}),
		saved_day,
	)
	var validated_petition_history := _validated_flock_petition_history(
		data.get("flock_petition_history", []),
		saved_day,
	)
	var validated_compact := _validated_flock_compact(
		data.get("active_flock_compact", {}),
		saved_day,
	)
	var validated_compact_receipt := _validated_flock_compact_receipt(
		data.get("last_flock_compact_receipt", {}),
		saved_day,
	)
	var validated_work_record := _validated_work_to_rule_record(
		data.get("last_work_to_rule_record", {}),
		saved_day,
	)
	var validated_queued_work_record := _validated_work_to_rule_record(
		data.get("queued_work_to_rule_record", {}),
		saved_day,
	)
	if (
		not bool(validated_petition.get("valid", false))
		or not bool(validated_petition_history.get("valid", false))
		or not bool(validated_compact.get("valid", false))
		or not bool(validated_compact_receipt.get("valid", false))
		or not bool(validated_work_record.get("valid", false))
		or not bool(validated_queued_work_record.get("valid", false))
		or not _is_integral_number(data.get("work_to_rule_day", null))
		or not _is_integral_number(data.get("queued_work_to_rule_day", null))
	):
		return false
	var restored_petition := validated_petition.get("record", {}) as Dictionary
	var restored_petition_history := (
		validated_petition_history.get("records", []) as Array[Dictionary]
	)
	var restored_compact := validated_compact.get("record", {}) as Dictionary
	var restored_compact_receipt := validated_compact_receipt.get("record", {}) as Dictionary
	var restored_work_record := validated_work_record.get("record", {}) as Dictionary
	var restored_queued_work_record := validated_queued_work_record.get("record", {}) as Dictionary
	var restored_work_day := int(data.get("work_to_rule_day", -1))
	var restored_queued_work_day := int(data.get("queued_work_to_rule_day", -1))
	if (
		restored_work_day < 0 or restored_work_day > 9999
		or restored_queued_work_day < 0 or restored_queued_work_day > 9999
		or (restored_petition.is_empty() != restored_petition_history.is_empty())
		or (
			not restored_petition_history.is_empty()
			and restored_petition != restored_petition_history[restored_petition_history.size() - 1]
		)
	):
		return false
	if restored_work_day == 0:
		if not restored_work_record.is_empty() and StringName(restored_work_record.get("status", &"")) != &"completed":
			return false
	else:
		if (
			restored_work_record.is_empty()
			or int(restored_work_record.get("effective_day", 0)) != restored_work_day
			or restored_work_day < saved_day
		):
			return false
	if restored_queued_work_day == 0:
		if not restored_queued_work_record.is_empty():
			return false
	else:
		if (
			restored_queued_work_record.is_empty()
			or int(restored_queued_work_record.get("effective_day", 0)) != restored_queued_work_day
			or restored_queued_work_day <= saved_day
			or restored_work_day != saved_day
		):
			return false
	for assist_integer_field in [
		"peck_assists_used_today", "peck_assist_streak", "best_peck_assist_streak",
		"priority_credit_today_cents", "priority_credit_total_cents",
	]:
		if not _is_integral_number(data.get(assist_integer_field, null)):
			return false
	var restored_assist_uses := int(data.get("peck_assists_used_today", -1))
	var restored_assist_streak := int(data.get("peck_assist_streak", -1))
	var restored_best_assist_streak := int(data.get("best_peck_assist_streak", -1))
	var restored_priority_today := int(data.get("priority_credit_today_cents", -1))
	var restored_priority_total := int(data.get("priority_credit_total_cents", -1))
	var restored_interventions_value: Variant = data.get(
		"peck_assist_interventions_today",
		restored_assist_uses,
	)
	var restored_refunds_value: Variant = data.get("peck_assist_refunds_today", 0)
	if (
		not _is_integral_number(restored_interventions_value)
		or not _is_integral_number(restored_refunds_value)
	):
		return false
	var restored_interventions := int(restored_interventions_value)
	var restored_refunds := int(restored_refunds_value)
	if (
		restored_assist_uses < 0 or restored_assist_uses > PECK_ASSIST_LIMIT
		or restored_interventions < 0 or restored_interventions > 9999
		or restored_refunds < 0 or restored_refunds > restored_interventions
		or restored_interventions - restored_refunds != restored_assist_uses
		or restored_assist_streak < 0 or restored_assist_streak > 9999
		or restored_best_assist_streak < restored_assist_streak
		or restored_best_assist_streak > 9999
		or restored_priority_today < 0
		or restored_priority_total < restored_priority_today
		or restored_priority_total > 2_000_000_000
	):
		return false
	var restored_last_assist_value: Variant = data.get("last_peck_assist", {})
	var restored_assisted_ids_value: Variant = data.get("assisted_claim_ids", [])
	var restored_missed_ids_value: Variant = data.get("missed_assist_claim_ids", [])
	var restored_assist_quality_value: Variant = data.get("assist_quality_modifiers", {})
	var restored_assist_chains_value: Variant = data.get("assist_chain_by_claim_id", {})
	var restored_pending_deliveries_value: Variant = data.get(
		"pending_peck_assist_deliveries",
		[],
	)
	var restored_settled_delivery_ids_value: Variant = data.get(
		"settled_peck_assist_delivery_ids",
		[],
	)
	var restored_last_delivery_value: Variant = data.get("last_peck_assist_delivery", {})
	if (
		not restored_last_assist_value is Dictionary
		or not restored_assisted_ids_value is Array
		or not restored_missed_ids_value is Array
		or not restored_assist_quality_value is Dictionary
		or not restored_assist_chains_value is Dictionary
		or not restored_pending_deliveries_value is Array
		or not restored_settled_delivery_ids_value is Array
		or not restored_last_delivery_value is Dictionary
	):
		return false
	var restored_last_assist := (restored_last_assist_value as Dictionary).duplicate(true)
	if not _is_valid_peck_assist_record(restored_last_assist, saved_day):
		return false
	restored_last_assist = _normalized_peck_assist_record(restored_last_assist)
	var restored_last_delivery := (restored_last_delivery_value as Dictionary).duplicate(true)
	if not _is_valid_peck_assist_delivery_receipt(restored_last_delivery, saved_day):
		return false
	restored_last_delivery = _normalized_peck_assist_delivery_receipt(restored_last_delivery)

	var seen_claim_ids: Dictionary[int, bool] = {}
	var seen_personnel_days: Dictionary[int, bool] = {}
	var occupied_desks: Dictionary[int, bool] = {}
	var restored_active_count := 0
	var restored_workers: Array[ChickenState] = []
	for index in workers.size():
		if not worker_data[index] is Dictionary:
			return false
		var saved_worker := worker_data[index] as Dictionary
		if not _is_integral_number(saved_worker.get("id", null)) or int(saved_worker.get("id", -1)) != index:
			return false
		if typeof(saved_worker.get("employed", null)) != TYPE_BOOL:
			return false
		var saved_employed := bool(saved_worker.get("employed", false))
		var expected_status := (
			ChickenState.EMPLOYMENT_STATUS_EMPLOYED
			if saved_employed else ChickenState.EMPLOYMENT_STATUS_APPLICANT
		)
		if StringName(String(saved_worker.get("employment_status", ""))) != expected_status:
			return false
		for integer_field in [
			"desk_index", "available_for_hire_day", "hire_count",
			"employment_start_day",
		]:
			if not _is_integral_number(saved_worker.get(integer_field, null)):
				return false
		var raw_desk_index := int(saved_worker.get("desk_index", -2))
		var raw_available_day := int(saved_worker.get("available_for_hire_day", -1))
		var raw_hire_count := int(saved_worker.get("hire_count", -1))
		var raw_employment_start := int(saved_worker.get("employment_start_day", -1))
		if raw_desk_index < -1 or raw_desk_index >= MAXIMUM_STAFF_CAPACITY:
			return false
		if raw_available_day < 0 or raw_available_day > 10000:
			return false
		if raw_hire_count < 0 or raw_hire_count > 9999:
			return false
		if raw_employment_start < 0 or raw_employment_start > 9999:
			return false
		var original := workers[index]
		var saved_profile := StringName(String(saved_worker.get(
			"career_profile",
			ChickenState.default_career_profile(original.id)
		)))
		if not ChickenState.is_valid_career_profile(saved_profile):
			return false
		var saved_action := StringName(String(saved_worker.get("last_personnel_action", "")))
		var saved_action_day := int(saved_worker.get("last_personnel_action_day", 0))
		for specialty_field in ["secondary_specialty", "cross_training_target"]:
			if typeof(saved_worker.get(specialty_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return false
		if typeof(saved_worker.get("cross_training_worked_this_shift", null)) != TYPE_BOOL:
			return false
		if not ChickenState.is_valid_personnel_action(saved_action):
			return false
		if (saved_action == &"") != (saved_action_day == 0):
			return false
		var restored := ChickenState.new(
			original.id,
			original.display_name,
			original.desk_index,
			original.skill,
			original.accuracy,
			original.specialty
		)
		if not restored.apply_save_data(saved_worker):
			return false
		if not ChickenState.is_valid_career_profile(restored.career_profile):
			return false
		if not ChickenState.is_valid_personnel_action(restored.last_personnel_action):
			return false
		if restored.last_personnel_action_day > saved_day:
			return false
		if restored.last_personnel_action_day > 0:
			if seen_personnel_days.has(restored.last_personnel_action_day):
				return false
			seen_personnel_days[restored.last_personnel_action_day] = true
		if restored.specialty not in CLAIM_LANES:
			return false
		if (
			restored.secondary_specialty != &""
			and restored.secondary_specialty not in CLAIM_LANES
		):
			return false
		if (
			restored.cross_training_target != &""
			and restored.cross_training_target not in CLAIM_LANES
		):
			return false
		if restored.assigned_lane != AUTO_ASSIGNMENT and restored.assigned_lane not in CLAIM_LANES:
			return false
		if restored.cross_training_worked_this_shift and (
			not restored.employed
			or int(data.get("shift_phase", -1)) not in [
				ShiftPhase.RUNNING,
				ShiftPhase.AWAITING_INCIDENT,
			]
		):
			return false
		if restored.employed:
			if (
				restored.desk_index < 0
				or restored.desk_index >= saved_office_capacity
				or occupied_desks.has(restored.desk_index)
				or restored.available_for_hire_day != 0
				or restored.employment_start_day < 1
				or restored.employment_start_day > saved_day
			):
				return false
			occupied_desks[restored.desk_index] = true
			restored_active_count += 1
		else:
			if (
				restored.desk_index != -1
				or restored.available_for_hire_day < 1
				or restored.available_for_hire_day > 10000
				or restored.employment_start_day != 0
				or restored.work_state != ChickenState.WorkState.IDLE
				or not is_zero_approx(restored.work_progress)
				or restored.state_ticks_remaining != 0
				or restored.current_claim != null
			):
				return false
		if restored.current_claim != null:
			if restored.current_claim.lane not in CLAIM_LANES or seen_claim_ids.has(restored.current_claim.id):
				return false
			seen_claim_ids[restored.current_claim.id] = true
		restored_workers.append(restored)
	if (
		restored_active_count < MINIMUM_STAFF_COUNT
		or restored_active_count > saved_office_capacity
	):
		return false
	var pending_value: Variant = data.get("pending_decision", {})
	if not pending_value is Dictionary or not _is_valid_pending_flock_petition(pending_value, saved_day):
		return false
	var pending_source := pending_value as Dictionary
	if StringName(pending_source.get("id", &"")) == FLOCK_PETITION_INCIDENT_ID:
		var pending_sponsor_id := int(pending_source.get("sponsor_worker_id", -1))
		if (
			int(data.get("shift_phase", -1)) != ShiftPhase.AWAITING_INCIDENT
			or int(data.get("incident_slot", -1)) != FLOCK_PETITION_INCIDENT_SLOT + 1
			or pending_sponsor_id < 0 or pending_sponsor_id >= restored_workers.size()
			or not restored_workers[pending_sponsor_id].employed
			or restored_workers[pending_sponsor_id].display_name != String(pending_source.get("sponsor_worker_name", ""))
			or not restored_compact.is_empty()
		):
			return false
	var historical_records: Array[Dictionary] = restored_petition_history.duplicate(true)
	var named_records: Array[Dictionary] = []
	if not restored_compact.is_empty():
		named_records.append(restored_compact)
	if not restored_compact_receipt.is_empty():
		named_records.append(restored_compact_receipt)
	if not restored_work_record.is_empty():
		named_records.append(restored_work_record)
	if not restored_queued_work_record.is_empty():
		named_records.append(restored_queued_work_record)
	for named_record in named_records:
		var sponsor_id := int(named_record.get("sponsor_worker_id", -1))
		if (
			sponsor_id < 0 or sponsor_id >= restored_workers.size()
			or restored_workers[sponsor_id].display_name != String(named_record.get("sponsor_worker_name", ""))
		):
			return false
	if not restored_compact.is_empty():
		var compact_sponsor_id := int(restored_compact.get("sponsor_worker_id", -1))
		if not restored_workers[compact_sponsor_id].employed:
			return false
		var compact_type := StringName(restored_compact.get("petition_type", &""))
		if (
			StringName(restored_compact.get("status", &"")) == &"active"
			and compact_type == &"specialty_respect"
			and restored_workers[compact_sponsor_id].assigned_lane != restored_workers[compact_sponsor_id].specialty
		):
			return false
		if (
			StringName(restored_compact.get("status", &"")) == &"active"
			and compact_type == &"safe_pace"
			and bool(data.get("overtime_enabled", false))
		):
			return false
		var compact_has_petition := false
		for petition_record in historical_records:
			if (
				int(petition_record.get("day", 0)) == int(restored_compact.get("petition_day", 0))
				and int(petition_record.get("sponsor_worker_id", -1)) == compact_sponsor_id
				and StringName(petition_record.get("petition_type", &"")) == compact_type
				and StringName(petition_record.get("response_id", &"")) == &"sign_compact"
			):
				compact_has_petition = true
				break
		if not compact_has_petition:
			return false

	var restored_queues: Dictionary = {}
	var saved_queues := queue_values as Dictionary
	var outstanding_count := 0
	for lane in CLAIM_LANES:
		var lane_values: Variant = saved_queues.get(String(lane), [])
		if not lane_values is Array:
			return false
		var restored_lane: Array[ClaimState] = []
		for claim_value in (lane_values as Array):
			if not claim_value is Dictionary:
				return false
			var claim := ClaimState.from_save_data(claim_value as Dictionary)
			if claim == null or claim.lane != lane or seen_claim_ids.has(claim.id):
				return false
			seen_claim_ids[claim.id] = true
			restored_lane.append(claim)
			outstanding_count += 1
		restored_queues[lane] = restored_lane

	var restored_rework: Array[ClaimState] = []
	for claim_value in (rework_values as Array):
		if not claim_value is Dictionary:
			return false
		var claim := ClaimState.from_save_data(claim_value as Dictionary)
		if claim == null or claim.lane not in CLAIM_LANES or seen_claim_ids.has(claim.id):
			return false
		seen_claim_ids[claim.id] = true
		restored_rework.append(claim)
		outstanding_count += 1
	for restored in restored_workers:
		if restored.current_claim != null:
			outstanding_count += 1
	if outstanding_count > MAX_CLAIM_QUEUE:
		return false

	var active_claim_ids: Dictionary[int, bool] = {}
	for restored in restored_workers:
		if restored.current_claim != null:
			active_claim_ids[restored.current_claim.id] = true
	var restored_assisted_ids: Dictionary[int, bool] = {}
	for claim_id_value in (restored_assisted_ids_value as Array):
		if not _is_integral_number(claim_id_value):
			return false
		var assisted_claim_id := int(claim_id_value)
		if assisted_claim_id < 1 or not active_claim_ids.has(assisted_claim_id) or restored_assisted_ids.has(assisted_claim_id):
			return false
		restored_assisted_ids[assisted_claim_id] = true
	var restored_missed_ids: Dictionary[int, bool] = {}
	for claim_id_value in (restored_missed_ids_value as Array):
		if not _is_integral_number(claim_id_value):
			return false
		var missed_claim_id := int(claim_id_value)
		if (
			missed_claim_id < 1
			or not active_claim_ids.has(missed_claim_id)
			or restored_missed_ids.has(missed_claim_id)
			or restored_assisted_ids.has(missed_claim_id)
		):
			return false
		restored_missed_ids[missed_claim_id] = true
	var restored_assist_quality: Dictionary[int, float] = {}
	for key_value in (restored_assist_quality_value as Dictionary):
		var quality_key_text := String(key_value)
		if not quality_key_text.is_valid_int():
			return false
		var quality_claim_id := quality_key_text.to_int()
		var modifier_value: Variant = (restored_assist_quality_value as Dictionary)[key_value]
		if (
			typeof(modifier_value) not in [TYPE_FLOAT, TYPE_INT]
			or not restored_assisted_ids.has(quality_claim_id)
			or restored_assist_quality.has(quality_claim_id)
		):
			return false
		var modifier := float(modifier_value)
		if modifier < -0.10 or modifier > 0.10:
			return false
		restored_assist_quality[quality_claim_id] = modifier
	var restored_assist_chains: Dictionary[int, int] = {}
	for key_value in (restored_assist_chains_value as Dictionary):
		var chain_key_text := String(key_value)
		if not chain_key_text.is_valid_int():
			return false
		var chain_claim_id := chain_key_text.to_int()
		var chain_value: Variant = (restored_assist_chains_value as Dictionary)[key_value]
		if (
			not _is_integral_number(chain_value)
			or not restored_assisted_ids.has(chain_claim_id)
			or restored_assist_chains.has(chain_claim_id)
		):
			return false
		var chain := int(chain_value)
		if chain < 0 or chain > restored_best_assist_streak:
			return false
		restored_assist_chains[chain_claim_id] = chain
	var restored_pending_deliveries: Dictionary[int, Dictionary] = {}
	for delivery_value in (restored_pending_deliveries_value as Array):
		if not delivery_value is Dictionary:
			return false
		var delivery := (delivery_value as Dictionary).duplicate(true)
		if not _is_valid_peck_assist_delivery_token(delivery, saved_day):
			return false
		delivery = _normalized_peck_assist_delivery_token(delivery)
		var delivery_claim_id := int(delivery.get("claim_id", -1))
		if (
			restored_pending_deliveries.has(delivery_claim_id)
			or seen_claim_ids.has(delivery_claim_id)
		):
			return false
		restored_pending_deliveries[delivery_claim_id] = delivery
	var restored_settled_delivery_ids: Dictionary[int, bool] = {}
	for claim_id_value in (restored_settled_delivery_ids_value as Array):
		if not _is_integral_number(claim_id_value):
			return false
		var settled_claim_id := int(claim_id_value)
		if (
			settled_claim_id < 1
			or restored_settled_delivery_ids.has(settled_claim_id)
			or restored_pending_deliveries.has(settled_claim_id)
			or seen_claim_ids.has(settled_claim_id)
		):
			return false
		restored_settled_delivery_ids[settled_claim_id] = true
	if (
		restored_assist_quality.size() != restored_assisted_ids.size()
		or restored_assist_chains.size() != restored_assisted_ids.size()
		or restored_assisted_ids.size() > restored_assist_uses
		or restored_pending_deliveries.size() > restored_assist_uses
		or restored_settled_delivery_ids.size() != restored_refunds
		or (restored_refunds == 0 and not restored_last_delivery.is_empty())
		or (
			restored_refunds > 0
			and (
				restored_last_delivery.is_empty()
				or not restored_settled_delivery_ids.has(int(restored_last_delivery.get("claim_id", -1)))
			)
		)
	):
		return false

	workers = restored_workers
	_claim_queues = restored_queues
	_pending_rework = restored_rework
	office_capacity = saved_office_capacity
	wage_arrears_cents = saved_wage_arrears
	last_staffing_action = restored_staffing_action
	_worker_shift_stats = restored_shift_stats
	last_pecking_order = restored_order
	last_pecking_order_day = restored_order_day
	last_credit_allocation = restored_credit_allocation
	credit_choice_counts = restored_credit_counts
	golden_dossier_resolved = restored_golden_resolved
	golden_dossier_day = restored_golden_day
	flock_restructuring_resolved = restored_restructuring_resolved
	flock_restructuring_day = restored_restructuring_day
	flock_restructuring_record = restored_restructuring_record
	last_flock_petition = restored_petition
	flock_petition_history = restored_petition_history
	active_flock_compact = restored_compact
	last_flock_compact_receipt = restored_compact_receipt
	work_to_rule_day = restored_work_day
	last_work_to_rule_record = restored_work_record
	queued_work_to_rule_day = restored_queued_work_day
	queued_work_to_rule_record = restored_queued_work_record
	peck_assists_used_today = restored_assist_uses
	peck_assist_interventions_today = restored_interventions
	peck_assist_refunds_today = restored_refunds
	peck_assist_streak = restored_assist_streak
	best_peck_assist_streak = restored_best_assist_streak
	last_peck_assist = restored_last_assist
	last_peck_assist_delivery = restored_last_delivery
	priority_credit_today_cents = restored_priority_today
	priority_credit_total_cents = restored_priority_total
	_assisted_claim_ids = restored_assisted_ids
	_missed_assist_claim_ids = restored_missed_ids
	_assist_quality_modifiers = restored_assist_quality
	_assist_chain_by_claim_id = restored_assist_chains
	_pending_peck_assist_deliveries = restored_pending_deliveries
	_settled_peck_assist_delivery_ids = restored_settled_delivery_ids
	day = clampi(int(data.get("day", 1)), 1, 9999)
	minute_of_day = clampi(int(data.get("minute_of_day", SHIFT_START_MINUTE)), SHIFT_START_MINUTE, SHIFT_END_MINUTE)
	claims_processed = maxi(0, int(data.get("claims_processed", 0)))
	eggs_today = maxi(0, int(data.get("eggs_today", 0)))
	eggs_total = maxi(0, int(data.get("eggs_total", eggs_today)))
	cracked_eggs = clampi(int(data.get("cracked_eggs", 0)), 0, eggs_total)
	cracked_today = clampi(int(data.get("cracked_today", 0)), 0, eggs_today)
	golden_eggs = clampi(int(data.get("golden_eggs", 0)), 0, eggs_total)
	golden_today = clampi(int(data.get("golden_today", 0)), 0, eggs_today)
	revenue_cents = clampi(int(data.get("revenue_cents", 5000)), 0, 2000000000)
	credited_today_cents = clampi(int(data.get("credited_today_cents", 0)), 0, 2000000000)
	feed_cents_per_day = clampi(int(data.get("feed_cents_per_day", 1800)), 0, 1000000)
	quota_target = clampi(int(data.get("quota_target", 24)), 1, 10000)
	executive_confidence = clampf(float(data.get("executive_confidence", 52.0)), 0.0, 100.0)
	compliance = clampf(float(data.get("compliance", 78.0)), 0.0, 100.0)
	solidarity = clampf(float(data.get("solidarity", 18.0)), 0.0, 100.0)
	overtime_enabled = bool(data.get("overtime_enabled", false))
	feed_party_used_today = bool(data.get("feed_party_used_today", false))
	quality_streak = maxi(0, int(data.get("quality_streak", 0)))
	best_quality_streak = maxi(quality_streak, int(data.get("best_quality_streak", quality_streak)))
	last_streak_bonus_cents = maxi(0, int(data.get("last_streak_bonus_cents", 0)))
	shift_phase = clampi(int(data.get("shift_phase", ShiftPhase.AWAITING_DIRECTIVE)), ShiftPhase.AWAITING_DIRECTIVE, ShiftPhase.REVIEW)
	active_directive_id = StringName(String(data.get("active_directive_id", "")))
	pending_decision = _decision_from_save_data(data.get("pending_decision", {}) as Dictionary)
	incidents_resolved_today = clampi(int(data.get("incidents_resolved_today", 0)), 0, INCIDENT_MINUTES.size())

	var saved_upgrades := data.get("upgrade_levels", {}) as Dictionary
	for upgrade_id in UPGRADE_ORDER:
		upgrade_levels[upgrade_id] = clampi(int(saved_upgrades.get(String(upgrade_id), 0)), 0, MAX_UPGRADE_LEVEL)
	var saved_lane_totals := data.get("lane_processed_totals", {}) as Dictionary
	var saved_lane_today := data.get("lane_processed_today", {}) as Dictionary
	for lane in CLAIM_LANES:
		lane_processed_totals[lane] = maxi(0, int(saved_lane_totals.get(String(lane), 0)))
		lane_processed_today[lane] = maxi(0, int(saved_lane_today.get(String(lane), 0)))
	var saved_unlocks := data.get("campaign_unlocks", {}) as Dictionary
	for unlock_id in CAMPAIGN_UNLOCKS:
		campaign_unlocks[unlock_id] = bool(saved_unlocks.get(String(unlock_id), false))

	_tick_count = maxi(0, int(data.get("tick_count", 0)))
	_next_claim_id = maxi(_highest_claim_id() + 1, int(data.get("next_claim_id", 1)))
	_rework_total_created = maxi(0, int(data.get("rework_total_created", 0)))
	_decision_serial = maxi(0, int(data.get("decision_serial", 0)))
	_incident_slot = clampi(int(data.get("incident_slot", 0)), 0, INCIDENT_MINUTES.size())
	_rng.state = String(data.get("rng_state", str(_rng.state))).to_int()
	_claim_rng.state = String(data.get("claim_rng_state", str(_claim_rng.state))).to_int()
	var modifiers := data.get("decision_modifiers", {}) as Dictionary
	_directive_work_multiplier = clampf(float(modifiers.get("directive_work_multiplier", 1.0)), 0.25, 3.0)
	_directive_fatigue_multiplier = clampf(float(modifiers.get("directive_fatigue_multiplier", 1.0)), 0.25, 3.0)
	_directive_stress_multiplier = clampf(float(modifiers.get("directive_stress_multiplier", 1.0)), 0.25, 3.0)
	_directive_morale_drain_multiplier = clampf(float(modifiers.get("directive_morale_drain_multiplier", 1.0)), 0.25, 3.0)
	_directive_crack_modifier = clampf(float(modifiers.get("directive_crack_modifier", 0.0)), -0.50, 0.50)
	_daily_feed_adjustment_cents = clampi(int(modifiers.get("daily_feed_adjustment_cents", 0)), -100000, 100000)
	_incident_work_multiplier = clampf(float(modifiers.get("incident_work_multiplier", 1.0)), 0.25, 3.0)
	_incident_strain_multiplier = clampf(float(modifiers.get("incident_strain_multiplier", 1.0)), 0.25, 3.0)
	_incident_crack_modifier = clampf(float(modifiers.get("incident_crack_modifier", 0.0)), -0.50, 0.50)
	_incident_golden_modifier = clampf(float(modifiers.get("incident_golden_modifier", 0.0)), -0.25, 0.25)
	_incident_feed_adjustment_cents = clampi(int(modifiers.get("incident_feed_adjustment_cents", 0)), -100000, 100000)
	_pending_quota_adjustment = clampi(int(modifiers.get("pending_quota_adjustment", 0)), -100, 100)
	_worker_at_workstation.clear()
	for worker in workers:
		_worker_at_workstation[worker.id] = false
	_sync_claims_waiting()
	snapshot_changed.emit(snapshot())
	return true


func _migrate_save_state(source: Dictionary) -> Dictionary:
	## Simulation checkpoints are nested inside the campaign save. Keep migration
	## local and pure so a rejected checkpoint cannot partially mutate the office.
	if not _is_integral_number(source.get("state_version", null)):
		return {}
	var source_version := int(source.get("state_version", -1))
	if source_version < 1 or source_version > SAVE_STATE_VERSION:
		return {}
	var migrated := source.duplicate(true)
	while source_version < SAVE_STATE_VERSION:
		var worker_values: Variant = migrated.get("workers", [])
		if not worker_values is Array:
			return {}
		var migrated_workers: Array[Dictionary] = []
		match source_version:
			1:
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					var worker := (worker_value as Dictionary).duplicate(true)
					var worker_id := int(worker.get("id", index))
					worker["career_profile"] = String(ChickenState.default_career_profile(worker_id))
					worker["manager_trust"] = 58.0
					worker["grievance"] = 6.0
					worker["career_xp"] = maxi(0, int(worker.get("eggs_laid", 0))) * 3
					worker["last_personnel_action"] = ""
					worker["last_personnel_action_day"] = 0
					migrated_workers.append(worker)
				migrated["workers"] = migrated_workers
				source_version = 2
				migrated["state_version"] = source_version
			2:
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					var worker := (worker_value as Dictionary).duplicate(true)
					worker["employed"] = true
					worker["employment_status"] = String(ChickenState.EMPLOYMENT_STATUS_EMPLOYED)
					worker["available_for_hire_day"] = 0
					worker["hire_count"] = 0
					worker["employment_start_day"] = 1
					migrated_workers.append(worker)
				migrated["workers"] = migrated_workers
				migrated["office_capacity"] = MAXIMUM_STAFF_CAPACITY
				migrated["wage_arrears_cents"] = 0
				migrated["last_staffing_action"] = {}
				source_version = 3
				migrated["state_version"] = source_version
			3:
				var migrated_stats: Array[Dictionary] = []
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					migrated_stats.append({
						"worker_id": int((worker_value as Dictionary).get("id", index)),
						"eggs": 0,
						"sound": 0,
						"cracked": 0,
						"golden": 0,
						"credit_cents": 0,
					})
				migrated["worker_shift_stats"] = migrated_stats
				migrated["last_pecking_order"] = []
				migrated["last_pecking_order_day"] = 0
				migrated["last_credit_allocation"] = {}
				migrated["credit_choice_counts"] = {
					"individual_merit": 0,
					"shared_scoop": 0,
					"management_innovation": 0,
				}
				migrated["golden_dossier_resolved"] = false
				migrated["golden_dossier_day"] = 0
				source_version = 4
				migrated["state_version"] = source_version
			4:
				migrated["peck_assists_used_today"] = 0
				migrated["peck_assist_streak"] = 0
				migrated["best_peck_assist_streak"] = 0
				migrated["last_peck_assist"] = {}
				migrated["priority_credit_today_cents"] = 0
				migrated["priority_credit_total_cents"] = 0
				migrated["assisted_claim_ids"] = []
				migrated["missed_assist_claim_ids"] = []
				migrated["assist_quality_modifiers"] = {}
				migrated["assist_chain_by_claim_id"] = {}
				migrated["flock_restructuring_resolved"] = false
				migrated["flock_restructuring_day"] = 0
				migrated["flock_restructuring_record"] = {}
				source_version = 5
				migrated["state_version"] = source_version
			5:
				migrated["last_flock_petition"] = {}
				migrated["flock_petition_history"] = []
				migrated["active_flock_compact"] = {}
				migrated["last_flock_compact_receipt"] = {}
				migrated["work_to_rule_day"] = 0
				migrated["last_work_to_rule_record"] = {}
				migrated["queued_work_to_rule_day"] = 0
				migrated["queued_work_to_rule_record"] = {}
				source_version = 6
				migrated["state_version"] = source_version
			6:
				for index in (worker_values as Array).size():
					var worker_value: Variant = (worker_values as Array)[index]
					if not worker_value is Dictionary:
						return {}
					var worker := (worker_value as Dictionary).duplicate(true)
					worker["secondary_specialty"] = ""
					worker["cross_training_target"] = ""
					worker["cross_training_worked_this_shift"] = false
					migrated_workers.append(worker)
				migrated["workers"] = migrated_workers
				# Renewable delivery refunds extend the v7 assist ledger without
				# invalidating earlier v7 checkpoints. Legacy schemas preserve their
				# known unavailable charges as gross interventions and invent no refunds.
				migrated["peck_assist_interventions_today"] = maxi(
					0,
					int(migrated.get("peck_assists_used_today", 0)),
				)
				migrated["peck_assist_refunds_today"] = 0
				migrated["last_peck_assist_delivery"] = {}
				migrated["pending_peck_assist_deliveries"] = []
				migrated["settled_peck_assist_delivery_ids"] = []
				source_version = 7
				migrated["state_version"] = source_version
			_:
				return {}
	return migrated


func _decision_from_save_data(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var restored := value.duplicate(true)
	for key in ["kind", "id", "category", "petition_type"]:
		if restored.has(key):
			restored[key] = StringName(String(restored[key]))
	var restored_options: Array[Dictionary] = []
	var option_values: Variant = restored.get("options", [])
	if option_values is Array:
		for option_value in (option_values as Array):
			if not option_value is Dictionary:
				continue
			var option := (option_value as Dictionary).duplicate(true)
			for key in ["id", "tone", "response_tier"]:
				if option.has(key):
					option[key] = StringName(String(option[key]))
			restored_options.append(option)
	restored["options"] = restored_options
	var petition_value: Variant = restored.get("petition", {})
	if petition_value is Dictionary:
		var petition := (petition_value as Dictionary).duplicate(true)
		if petition.has("petition_type"):
			petition["petition_type"] = StringName(String(petition["petition_type"]))
		restored["petition"] = petition
	return restored


func _is_valid_peck_assist_record(value: Dictionary, saved_day: int) -> bool:
	if value.is_empty():
		return true
	if typeof(value.get("accepted", null)) != TYPE_BOOL or not bool(value.get("accepted", false)):
		return false
	for field in ["day", "worker_id", "claim_id", "streak", "best_streak", "remaining"]:
		if not _is_integral_number(value.get(field, null)):
			return false
	if int(value.get("day", 0)) < 1 or int(value.get("day", 0)) > saved_day:
		return false
	if int(value.get("worker_id", -1)) < 0 or int(value.get("worker_id", -1)) >= WORKER_NAMES.size():
		return false
	if int(value.get("claim_id", 0)) < 1:
		return false
	if int(value.get("streak", -1)) < 0 or int(value.get("best_streak", -1)) < int(value.get("streak", 0)):
		return false
	if int(value.get("remaining", -1)) < 0 or int(value.get("remaining", -1)) > PECK_ASSIST_LIMIT:
		return false
	if (
		not _is_integral_number(value.get("potential_priority_credit_cents", null))
		or int(value.get("potential_priority_credit_cents", -1)) < 0
		or int(value.get("potential_priority_credit_cents", -1)) > 100
	):
		return false
	for optional_integer_field in ["charges", "gross_interventions", "refunds"]:
		if value.has(optional_integer_field) and not _is_integral_number(value.get(optional_integer_field)):
			return false
	var rating := StringName(String(value.get("rating", "")))
	if rating not in [&"perfect", &"strong", &"steady", &"scramble"]:
		return false
	for field in [
		"timing_score", "progress_before", "progress_after", "progress_gain",
		"quality_modifier", "stress_delta", "fatigue_delta", "morale_delta",
	]:
		if typeof(value.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return false
	return true


func _normalized_peck_assist_record(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var normalized := value.duplicate(true)
	for field in [
		"day", "worker_id", "claim_id", "streak", "best_streak", "remaining",
		"potential_priority_credit_cents",
	]:
		normalized[field] = int(normalized.get(field, 0))
	for optional_integer_field in ["charges", "gross_interventions", "refunds"]:
		if normalized.has(optional_integer_field):
			normalized[optional_integer_field] = int(normalized.get(optional_integer_field, 0))
	for field in [
		"timing_score", "progress_before", "progress_after", "progress_gain",
		"quality_modifier", "stress_delta", "fatigue_delta", "morale_delta",
	]:
		normalized[field] = snappedf(float(normalized.get(field, 0.0)), 0.0001)
	normalized["accepted"] = bool(normalized.get("accepted", true))
	normalized["worker_name"] = String(normalized.get("worker_name", ""))
	normalized["rating"] = String(normalized.get("rating", ""))
	normalized["timing_label"] = String(normalized.get("timing_label", ""))
	return normalized


func _is_valid_peck_assist_delivery_token(value: Dictionary, saved_day: int) -> bool:
	for field in ["day", "claim_id", "worker_id"]:
		if not _is_integral_number(value.get(field, null)):
			return false
	if int(value.get("day", 0)) != saved_day:
		return false
	if int(value.get("claim_id", 0)) < 1:
		return false
	if int(value.get("worker_id", -1)) < 0 or int(value.get("worker_id", -1)) >= WORKER_NAMES.size():
		return false
	if typeof(value.get("quality", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	return StringName(String(value.get("quality", ""))) in [&"sound", &"golden"]


func _normalized_peck_assist_delivery_token(value: Dictionary) -> Dictionary:
	var normalized := value.duplicate(true)
	for field in ["day", "claim_id", "worker_id"]:
		normalized[field] = int(normalized.get(field, 0))
	normalized["quality"] = String(normalized.get("quality", ""))
	return normalized


func _is_valid_peck_assist_delivery_receipt(value: Dictionary, saved_day: int) -> bool:
	if value.is_empty():
		return true
	if (
		typeof(value.get("accepted", null)) != TYPE_BOOL
		or not bool(value.get("accepted", false))
		or typeof(value.get("refunded", null)) != TYPE_BOOL
		or not bool(value.get("refunded", false))
	):
		return false
	for field in [
		"day", "claim_id", "refund_amount", "charges_before", "charges_after", "remaining",
		"gross_interventions", "refunds", "pending_delivery_count",
	]:
		if not _is_integral_number(value.get(field, null)):
			return false
	var charges_before := int(value.get("charges_before", -1))
	var charges_after := int(value.get("charges_after", -1))
	var gross_interventions := int(value.get("gross_interventions", -1))
	var refunds := int(value.get("refunds", -1))
	if (
		int(value.get("day", 0)) != saved_day
		or int(value.get("claim_id", 0)) < 1
		or int(value.get("refund_amount", -1)) != 1
		or charges_before < 0 or charges_before >= PECK_ASSIST_LIMIT
		or charges_after != charges_before + 1 or charges_after > PECK_ASSIST_LIMIT
		or int(value.get("remaining", -1)) != charges_after
		or gross_interventions < 1 or gross_interventions > 9999
		or refunds < 1 or refunds > gross_interventions
		or gross_interventions - refunds != PECK_ASSIST_LIMIT - charges_after
		or int(value.get("pending_delivery_count", -1)) < 0
		or int(value.get("pending_delivery_count", -1)) > PECK_ASSIST_LIMIT
		or int(value.get("pending_delivery_count", -1)) > PECK_ASSIST_LIMIT - charges_after
	):
		return false
	if typeof(value.get("quality", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if StringName(String(value.get("quality", ""))) not in [&"sound", &"golden"]:
		return false
	return typeof(value.get("reason", null)) == TYPE_STRING


func _normalized_peck_assist_delivery_receipt(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var normalized := value.duplicate(true)
	for field in [
		"day", "claim_id", "refund_amount", "charges_before", "charges_after", "remaining",
		"gross_interventions", "refunds", "pending_delivery_count",
	]:
		normalized[field] = int(normalized.get(field, 0))
	normalized["accepted"] = bool(normalized.get("accepted", true))
	normalized["refunded"] = bool(normalized.get("refunded", true))
	normalized["quality"] = String(normalized.get("quality", ""))
	normalized["reason"] = String(normalized.get("reason", ""))
	return normalized


func _is_valid_staffing_action_data(value: Dictionary, saved_day: int) -> bool:
	if value.is_empty():
		return true
	if typeof(value.get("accepted", null)) != TYPE_BOOL or not bool(value.get("accepted", false)):
		return false
	if typeof(value.get("action_id", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if typeof(value.get("worker_name", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if value.has("outcome") and typeof(value.get("outcome")) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	if StringName(String(value.get("action_id", ""))) not in [&"hire_worker", &"release_worker"]:
		return false
	for field in [
		"day", "cost_cents", "worker_id", "desk_index",
		"active_staff_count", "office_capacity",
	]:
		if not _is_integral_number(value.get(field, null)):
			return false
	var action_day := int(value.get("day", 0))
	if action_day < 1 or action_day > saved_day:
		return false
	if int(value.get("cost_cents", -1)) < 0:
		return false
	if int(value.get("worker_id", -1)) < 0 or int(value.get("worker_id", -1)) >= MAXIMUM_STAFF_CAPACITY:
		return false
	if String(value.get("worker_name", "")).is_empty():
		return false
	if int(value.get("desk_index", -2)) < -1 or int(value.get("desk_index", -2)) >= MAXIMUM_STAFF_CAPACITY:
		return false
	if (
		int(value.get("active_staff_count", 0)) < MINIMUM_STAFF_COUNT
		or int(value.get("active_staff_count", 0)) > MAXIMUM_STAFF_CAPACITY
	):
		return false
	if (
		int(value.get("office_capacity", 0)) < MINIMUM_STAFF_COUNT
		or int(value.get("office_capacity", 0)) > MAXIMUM_STAFF_CAPACITY
	):
		return false
	return true


func _is_integral_number(value: Variant) -> bool:
	if typeof(value) == TYPE_INT:
		return true
	if typeof(value) != TYPE_FLOAT:
		return false
	var number := float(value)
	return is_finite(number) and number == floor(number)


func _normalized_staffing_action_data(value: Dictionary) -> Dictionary:
	if value.is_empty():
		return {}
	var normalized := value.duplicate(true)
	normalized["accepted"] = bool(normalized.get("accepted", true))
	normalized["action_id"] = String(normalized.get("action_id", ""))
	normalized["worker_name"] = String(normalized.get("worker_name", ""))
	if normalized.has("outcome"):
		normalized["outcome"] = String(normalized["outcome"])
	for field in [
		"day", "cost_cents", "worker_id", "desk_index", "active_staff_count",
		"office_capacity", "daily_wage_cents", "spendable_fund_cents",
		"available_for_hire_day",
	]:
		if normalized.has(field):
			normalized[field] = int(normalized[field])
	return normalized


func _restore_worker_shift_stats(value: Variant) -> Array[Dictionary]:
	var restored: Array[Dictionary] = []
	if not value is Array or (value as Array).size() != workers.size():
		return restored
	for index in (value as Array).size():
		var entry_value: Variant = (value as Array)[index]
		if not entry_value is Dictionary:
			return []
		var entry := entry_value as Dictionary
		for field in ["worker_id", "eggs", "sound", "cracked", "golden", "credit_cents"]:
			if not _is_integral_number(entry.get(field, null)):
				return []
		var worker_id := int(entry.get("worker_id", -1))
		var eggs := int(entry.get("eggs", -1))
		var sound := int(entry.get("sound", -1))
		var cracked := int(entry.get("cracked", -1))
		var golden := int(entry.get("golden", -1))
		var credit_cents := int(entry.get("credit_cents", -1))
		if (
			worker_id != index
			or eggs < 0 or eggs > 100_000
			or sound < 0 or cracked < 0 or golden < 0
			or sound + cracked + golden != eggs
			or credit_cents < 0 or credit_cents > 2_000_000_000
		):
			return []
		restored.append({
			"worker_id": worker_id,
			"eggs": eggs,
			"sound": sound,
			"cracked": cracked,
			"golden": golden,
			"credit_cents": credit_cents,
		})
	return restored


func _validated_pecking_order_data(value: Variant) -> Dictionary:
	if not value is Array:
		return {"valid": false, "rows": []}
	var source := value as Array
	if source.size() > workers.size():
		return {"valid": false, "rows": []}
	var restored: Array[Dictionary] = []
	var seen_ids: Dictionary[int, bool] = {}
	for index in source.size():
		var row_value: Variant = source[index]
		if not row_value is Dictionary:
			return {"valid": false, "rows": []}
		var row := row_value as Dictionary
		for field in [
			"rank", "worker_id", "eggs", "sound", "cracked", "golden",
			"credit_cents", "score",
		]:
			if not _is_integral_number(row.get(field, null)):
				return {"valid": false, "rows": []}
		if typeof(row.get("worker_name", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "rows": []}
		if typeof(row.get("employed", null)) != TYPE_BOOL:
			return {"valid": false, "rows": []}
		var worker_id := int(row.get("worker_id", -1))
		var eggs := int(row.get("eggs", -1))
		var sound := int(row.get("sound", -1))
		var cracked := int(row.get("cracked", -1))
		var golden := int(row.get("golden", -1))
		var credit_cents := int(row.get("credit_cents", -1))
		if (
			int(row.get("rank", 0)) != index + 1
			or worker_id < 0 or worker_id >= workers.size()
			or seen_ids.has(worker_id)
			or eggs < 0 or eggs > 100_000
			or sound < 0 or cracked < 0 or golden < 0
			or sound + cracked + golden != eggs
			or credit_cents < 0 or credit_cents > 2_000_000_000
			or int(row.get("score", -1)) != credit_cents
			or String(row.get("worker_name", "")).is_empty()
		):
			return {"valid": false, "rows": []}
		seen_ids[worker_id] = true
		restored.append({
			"rank": index + 1,
			"worker_id": worker_id,
			"worker_name": String(row.get("worker_name", "")),
			"employed": bool(row.get("employed", true)),
			"eggs": eggs,
			"sound": sound,
			"cracked": cracked,
			"golden": golden,
			"credit_cents": credit_cents,
			"score": credit_cents,
		})
	return {"valid": true, "rows": restored}


func _validated_credit_counts(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var restored: Dictionary = {}
	for style_id in CREDIT_STYLE_IDS:
		var raw: Variant = (value as Dictionary).get(String(style_id), null)
		if not _is_integral_number(raw):
			return {}
		var count := int(raw)
		if count < 0 or count > 9999:
			return {}
		restored[style_id] = count
	return restored


func _validated_credit_allocation(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["day", "worker_id", "cost_cents"]:
		if not _is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["decision_id", "option_id", "style_id", "worker_name", "outcome"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	for field in ["special_event", "projected"]:
		if typeof(source.get(field, null)) != TYPE_BOOL:
			return {"valid": false, "record": {}}
	var record_day := int(source.get("day", 0))
	var worker_id := int(source.get("worker_id", -1))
	var cost_cents := int(source.get("cost_cents", -1))
	var option_id := StringName(String(source.get("option_id", "")))
	var style_id := StringName(String(source.get("style_id", "")))
	if (
		record_day < 1 or record_day > saved_day
		or worker_id < -1 or worker_id >= workers.size()
		or cost_cents < 0 or cost_cents > 2_000_000_000
		or option_id not in CREDIT_OPTION_IDS
		or style_id not in CREDIT_STYLE_IDS
		or String(source.get("outcome", "")).is_empty()
	):
		return {"valid": false, "record": {}}
	return {
		"valid": true,
		"record": {
			"day": record_day,
			"decision_id": String(source.get("decision_id", "")),
			"option_id": String(option_id),
			"style_id": String(style_id),
			"worker_id": worker_id,
			"worker_name": String(source.get("worker_name", "")),
			"cost_cents": cost_cents,
			"outcome": String(source.get("outcome", "")),
			"special_event": bool(source.get("special_event", false)),
			"projected": bool(source.get("projected", false)),
		},
	}


func _validated_restructuring_record(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	var validated_base := _validated_credit_allocation(source, saved_day)
	if not bool(validated_base.get("valid", false)):
		return {"valid": false, "record": {}}
	var record := (validated_base.get("record", {}) as Dictionary).duplicate(true)
	var option_id := StringName(String(record.get("option_id", "")))
	if (
		StringName(String(record.get("decision_id", ""))) != &"flock_restructuring"
		or option_id not in [&"nominate_variance", &"fund_redeployment", &"contest_ranking"]
		or int(record.get("day", 0)) != FLOCK_RESTRUCTURING_SHIFT
		or not bool(record.get("special_event", false))
		or bool(record.get("projected", true))
	):
		return {"valid": false, "record": {}}
	for field in [
		"candidate_rank", "candidate_eggs", "candidate_cracked",
		"candidate_credit_cents", "replacement_worker_id",
	]:
		if not _is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["choice_label", "replacement_worker_name"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	if typeof(source.get("candidate_employed_after", null)) != TYPE_BOOL:
		return {"valid": false, "record": {}}
	var candidate_before_value: Variant = source.get("candidate_before", {})
	if not candidate_before_value is Dictionary:
		return {"valid": false, "record": {}}
	var candidate_before := candidate_before_value as Dictionary
	for field in ["career_title", "specialty", "assignment"]:
		if typeof(candidate_before.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	if not _is_integral_number(candidate_before.get("career_xp", null)):
		return {"valid": false, "record": {}}
	for field in ["manager_trust", "grievance", "morale", "stress", "fatigue"]:
		if typeof(candidate_before.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return {"valid": false, "record": {}}
		if float(candidate_before.get(field, -1.0)) < 0.0 or float(candidate_before.get(field, 101.0)) > 100.0:
			return {"valid": false, "record": {}}
	var candidate_rank := int(source.get("candidate_rank", 0))
	var candidate_eggs := int(source.get("candidate_eggs", -1))
	var candidate_cracked := int(source.get("candidate_cracked", -1))
	var candidate_credit_cents := int(source.get("candidate_credit_cents", -1))
	var replacement_worker_id := int(source.get("replacement_worker_id", -2))
	var candidate_employed_after := bool(source.get("candidate_employed_after", true))
	if (
		candidate_rank < 1 or candidate_rank > workers.size()
		or candidate_eggs < 0 or candidate_cracked < 0 or candidate_cracked > candidate_eggs
		or candidate_credit_cents < 0
		or replacement_worker_id < -1 or replacement_worker_id >= workers.size()
		or int(candidate_before.get("career_xp", -1)) < 0
		or String(source.get("choice_label", "")).is_empty()
		or (option_id == &"nominate_variance" and candidate_employed_after)
		or (option_id != &"nominate_variance" and not candidate_employed_after)
		or (option_id != &"nominate_variance" and replacement_worker_id != -1)
	):
		return {"valid": false, "record": {}}
	var normalized_before := {
		"career_title": String(candidate_before.get("career_title", "")),
		"career_xp": int(candidate_before.get("career_xp", 0)),
		"specialty": String(candidate_before.get("specialty", "")),
		"assignment": String(candidate_before.get("assignment", "")),
		"manager_trust": snappedf(float(candidate_before.get("manager_trust", 0.0)), 0.0001),
		"grievance": snappedf(float(candidate_before.get("grievance", 0.0)), 0.0001),
		"morale": snappedf(float(candidate_before.get("morale", 0.0)), 0.0001),
		"stress": snappedf(float(candidate_before.get("stress", 0.0)), 0.0001),
		"fatigue": snappedf(float(candidate_before.get("fatigue", 0.0)), 0.0001),
	}
	record.merge({
		"choice_label": String(source.get("choice_label", "")),
		"candidate_rank": candidate_rank,
		"candidate_eggs": candidate_eggs,
		"candidate_cracked": candidate_cracked,
		"candidate_credit_cents": candidate_credit_cents,
		"candidate_before": normalized_before,
		"candidate_employed_after": candidate_employed_after,
		"replacement_worker_id": replacement_worker_id,
		"replacement_worker_name": String(source.get("replacement_worker_name", "")),
	}, true)
	return {"valid": true, "record": record}


func _validated_flock_petition_record(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["version", "day", "sponsor_worker_id", "cost_cents", "effective_day"]:
		if not _is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in [
		"petition_type", "petition_title", "sponsor_worker_name", "response_id",
		"response_tier", "outcome",
	]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	for field in ["compact_scheduled", "work_to_rule_scheduled"]:
		if typeof(source.get(field, null)) != TYPE_BOOL:
			return {"valid": false, "record": {}}
	for field in ["solidarity_before", "solidarity_after"]:
		if typeof(source.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return {"valid": false, "record": {}}
		var solidarity_value := float(source.get(field, -1.0))
		if not is_finite(solidarity_value) or solidarity_value < 0.0 or solidarity_value > 100.0:
			return {"valid": false, "record": {}}
	var evidence_value: Variant = source.get("evidence", [])
	if not evidence_value is Array or (evidence_value as Array).is_empty() or (evidence_value as Array).size() > 8:
		return {"valid": false, "record": {}}
	var evidence: Array[String] = []
	for entry in (evidence_value as Array):
		if typeof(entry) not in [TYPE_STRING, TYPE_STRING_NAME] or String(entry).is_empty():
			return {"valid": false, "record": {}}
		evidence.append(String(entry))
	var record_day := int(source.get("day", 0))
	var petition_type := StringName(String(source.get("petition_type", "")))
	var response_id := StringName(String(source.get("response_id", "")))
	var response_tier := StringName(String(source.get("response_tier", "")))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or record_day not in FLOCK_PETITION_DAYS
		or record_day > saved_day
		or int(source.get("effective_day", 0)) != record_day + 1
		or petition_type not in FLOCK_PETITION_TYPES
		or response_id not in FLOCK_PETITION_RESPONSE_IDS
		or sponsor_id < 0 or sponsor_id >= workers.size()
		or String(source.get("sponsor_worker_name", "")).is_empty()
		or String(source.get("petition_title", "")).is_empty()
		or String(source.get("outcome", "")).is_empty()
	):
		return {"valid": false, "record": {}}
	var expected_tier: StringName = &""
	var expected_cost := 0
	var expected_compact := false
	match response_id:
		&"sign_compact":
			expected_tier = &"binding"
			expected_cost = int((FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary).get("sign_cost_cents", -1))
			expected_compact = true
		&"offer_concession":
			expected_tier = &"concession"
			expected_cost = 400
		&"deny_and_monitor":
			expected_tier = &"denial"
			expected_cost = 0
	if (
		response_tier != expected_tier
		or int(source.get("cost_cents", -1)) != expected_cost
		or bool(source.get("compact_scheduled", false)) != expected_compact
		or (bool(source.get("work_to_rule_scheduled", false)) and response_id != &"deny_and_monitor")
	):
		return {"valid": false, "record": {}}
	return {
		"valid": true,
		"record": {
			"version": 1,
			"day": record_day,
			"petition_type": String(petition_type),
			"petition_title": String(source.get("petition_title", "")),
			"sponsor_worker_id": sponsor_id,
			"sponsor_worker_name": String(source.get("sponsor_worker_name", "")),
			"evidence": evidence,
			"response_id": String(response_id),
			"response_tier": String(response_tier),
			"cost_cents": expected_cost,
			"outcome": String(source.get("outcome", "")),
			"effective_day": record_day + 1,
			"compact_scheduled": expected_compact,
			"work_to_rule_scheduled": bool(source.get("work_to_rule_scheduled", false)),
			"solidarity_before": snappedf(float(source.get("solidarity_before", 0.0)), 0.0001),
			"solidarity_after": snappedf(float(source.get("solidarity_after", 0.0)), 0.0001),
		},
	}


func _validated_flock_petition_history(value: Variant, saved_day: int) -> Dictionary:
	if not value is Array or (value as Array).size() > FLOCK_PETITION_HISTORY_LIMIT:
		return {"valid": false, "records": []}
	var records: Array[Dictionary] = []
	var previous_day := 0
	for record_value in (value as Array):
		var validated := _validated_flock_petition_record(record_value, saved_day)
		if not bool(validated.get("valid", false)):
			return {"valid": false, "records": []}
		var record := validated.get("record", {}) as Dictionary
		if record.is_empty() or int(record.get("day", 0)) <= previous_day:
			return {"valid": false, "records": []}
		previous_day = int(record.get("day", 0))
		records.append(record)
	return {"valid": true, "records": records}


func _validated_flock_compact(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["version", "petition_day", "effective_day", "sponsor_worker_id"]:
		if not _is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in [
		"compact_id", "status", "petition_type", "compact_name",
		"sponsor_worker_name", "promise", "condition",
	]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	var petition_day := int(source.get("petition_day", 0))
	var effective_day := int(source.get("effective_day", 0))
	var petition_type := StringName(String(source.get("petition_type", "")))
	var status := StringName(String(source.get("status", "")))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or petition_day not in FLOCK_PETITION_DAYS
		or effective_day != petition_day + 1
		or petition_type not in FLOCK_PETITION_TYPES
		or status not in [&"scheduled", &"active"]
		or sponsor_id < 0 or sponsor_id >= workers.size()
		or String(source.get("compact_id", "")) != "D%d-%s-%d" % [petition_day, String(petition_type), sponsor_id]
		or String(source.get("sponsor_worker_name", "")).is_empty()
	):
		return {"valid": false, "record": {}}
	if (
		(status == &"scheduled" and saved_day != petition_day)
		or (status == &"active" and saved_day != effective_day)
	):
		return {"valid": false, "record": {}}
	var definition := FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	if (
		String(source.get("compact_name", "")) != String(definition.get("compact_name", ""))
		or String(source.get("promise", "")) != String(definition.get("promise", ""))
		or String(source.get("condition", "")) != String(definition.get("condition", ""))
	):
		return {"valid": false, "record": {}}
	var record := source.duplicate(true)
	record["version"] = 1
	record["petition_day"] = petition_day
	record["effective_day"] = effective_day
	record["sponsor_worker_id"] = sponsor_id
	for field in [
		"compact_id", "status", "petition_type", "compact_name",
		"sponsor_worker_name", "promise", "condition",
	]:
		record[field] = String(record.get(field, ""))
	return {"valid": true, "record": record}


func _validated_flock_compact_receipt(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in [
		"version", "petition_day", "effective_day", "resolved_day", "sponsor_worker_id",
	]:
		if not _is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in [
		"compact_id", "status", "petition_type", "compact_name", "sponsor_worker_name",
		"promise", "condition", "reason", "outcome",
	]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	if typeof(source.get("work_to_rule_scheduled", null)) != TYPE_BOOL:
		return {"valid": false, "record": {}}
	var petition_day := int(source.get("petition_day", 0))
	var effective_day := int(source.get("effective_day", 0))
	var resolved_day := int(source.get("resolved_day", 0))
	var petition_type := StringName(String(source.get("petition_type", "")))
	var status := StringName(String(source.get("status", "")))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or petition_day not in FLOCK_PETITION_DAYS
		or effective_day != petition_day + 1
		or resolved_day < effective_day or resolved_day > saved_day
		or petition_type not in FLOCK_PETITION_TYPES
		or status not in [&"fulfilled", &"breached"]
		or sponsor_id < 0 or sponsor_id >= workers.size()
		or String(source.get("compact_id", "")) != "D%d-%s-%d" % [petition_day, String(petition_type), sponsor_id]
		or String(source.get("sponsor_worker_name", "")).is_empty()
		or String(source.get("reason", "")).is_empty()
		or String(source.get("outcome", "")).is_empty()
		or (status == &"fulfilled" and bool(source.get("work_to_rule_scheduled", true)))
	):
		return {"valid": false, "record": {}}
	var definition := FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	if (
		String(source.get("compact_name", "")) != String(definition.get("compact_name", ""))
		or String(source.get("promise", "")) != String(definition.get("promise", ""))
		or String(source.get("condition", "")) != String(definition.get("condition", ""))
	):
		return {"valid": false, "record": {}}
	var record := source.duplicate(true)
	for field in [
		"version", "petition_day", "effective_day", "resolved_day", "sponsor_worker_id",
	]:
		record[field] = int(record.get(field, 0))
	for field in [
		"compact_id", "status", "petition_type", "compact_name", "sponsor_worker_name",
		"promise", "condition", "reason", "outcome",
	]:
		record[field] = String(record.get(field, ""))
	record["work_to_rule_scheduled"] = bool(record.get("work_to_rule_scheduled", false))
	return {"valid": true, "record": record}


func _validated_work_to_rule_record(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for field in ["version", "petition_day", "effective_day", "sponsor_worker_id"]:
		if not _is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["trigger", "status", "sponsor_worker_name", "outcome"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	for field in ["work_multiplier", "crack_modifier"]:
		if typeof(source.get(field, null)) not in [TYPE_FLOAT, TYPE_INT]:
			return {"valid": false, "record": {}}
	var status := StringName(String(source.get("status", "")))
	var trigger := StringName(String(source.get("trigger", "")))
	var petition_day := int(source.get("petition_day", 0))
	var effective_day := int(source.get("effective_day", 0))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if (
		int(source.get("version", 0)) != 1
		or trigger not in [&"petition_denied", &"compact_breached"]
		or status not in [&"scheduled", &"active", &"completed"]
		or petition_day not in FLOCK_PETITION_DAYS
		or effective_day <= petition_day or effective_day > mini(9999, petition_day + 2)
		or sponsor_id < 0 or sponsor_id >= workers.size()
		or String(source.get("sponsor_worker_name", "")).is_empty()
		or String(source.get("outcome", "")).is_empty()
		or not is_equal_approx(float(source.get("work_multiplier", 0.0)), WORK_TO_RULE_WORK_MULTIPLIER)
		or not is_equal_approx(float(source.get("crack_modifier", 0.0)), WORK_TO_RULE_CRACK_MODIFIER)
	):
		return {"valid": false, "record": {}}
	if (
		(status == &"scheduled" and effective_day <= saved_day)
		or (status == &"active" and effective_day != saved_day)
	):
		return {"valid": false, "record": {}}
	if status == &"completed":
		if not _is_integral_number(source.get("completed_day", null)):
			return {"valid": false, "record": {}}
		if int(source.get("completed_day", 0)) != effective_day or effective_day > saved_day:
			return {"valid": false, "record": {}}
	var record := source.duplicate(true)
	for field in ["version", "petition_day", "effective_day", "sponsor_worker_id"]:
		record[field] = int(record.get(field, 0))
	if record.has("completed_day"):
		record["completed_day"] = int(record.get("completed_day", 0))
	for field in ["trigger", "status", "sponsor_worker_name", "outcome"]:
		record[field] = String(record.get(field, ""))
	record["work_multiplier"] = WORK_TO_RULE_WORK_MULTIPLIER
	record["crack_modifier"] = WORK_TO_RULE_CRACK_MODIFIER
	return {"valid": true, "record": record}


func _is_valid_pending_flock_petition(value: Variant, saved_day: int) -> bool:
	if not value is Dictionary:
		return false
	var source := value as Dictionary
	if StringName(source.get("id", &"")) != FLOCK_PETITION_INCIDENT_ID:
		return true
	if (
		StringName(source.get("kind", &"")) != &"incident"
		or StringName(source.get("category", &"")) != FLOCK_PETITION_CATEGORY
		or int(source.get("day", 0)) != saved_day
		or saved_day not in FLOCK_PETITION_DAYS
	):
		return false
	var petition_type := StringName(source.get("petition_type", &""))
	var sponsor_id := int(source.get("sponsor_worker_id", -1))
	if petition_type not in FLOCK_PETITION_TYPES or sponsor_id < 0 or sponsor_id >= workers.size():
		return false
	var petition_value: Variant = source.get("petition", {})
	var evidence_value: Variant = source.get("evidence", [])
	if not petition_value is Dictionary or not evidence_value is Array or (evidence_value as Array).is_empty():
		return false
	var petition := petition_value as Dictionary
	if (
		int(petition.get("version", 0)) != 1
		or StringName(petition.get("petition_type", &"")) != petition_type
		or int(petition.get("sponsor_worker_id", -1)) != sponsor_id
		or String(petition.get("sponsor_worker_name", "")) != String(source.get("sponsor_worker_name", ""))
		or int(petition.get("effective_day", 0)) != saved_day + 1
		or not is_equal_approx(float(petition.get("work_to_rule_threshold", -1.0)), WORK_TO_RULE_SOLIDARITY_THRESHOLD)
		or petition.get("evidence", []) != evidence_value
	):
		return false
	var options_value: Variant = source.get("options", [])
	if not options_value is Array or (options_value as Array).size() != FLOCK_PETITION_RESPONSE_IDS.size():
		return false
	var seen: Dictionary[StringName, bool] = {}
	for option_value in (options_value as Array):
		if not option_value is Dictionary:
			return false
		var option := option_value as Dictionary
		var option_id := StringName(option.get("id", &""))
		if option_id not in FLOCK_PETITION_RESPONSE_IDS or seen.has(option_id):
			return false
		seen[option_id] = true
		var expected_cost := 0
		var expected_tier: StringName = &""
		match option_id:
			&"sign_compact":
				expected_cost = int((FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary).get("sign_cost_cents", -1))
				expected_tier = &"binding"
			&"offer_concession":
				expected_cost = 400
				expected_tier = &"concession"
			&"deny_and_monitor":
				expected_tier = &"denial"
		if (
			int(option.get("cost_cents", -1)) != expected_cost
			or StringName(option.get("response_tier", &"")) != expected_tier
		):
			return false
	return true


func _highest_claim_id() -> int:
	var highest := 0
	for lane in CLAIM_LANES:
		for claim_value in (_claim_queues.get(lane, []) as Array):
			var claim := claim_value as ClaimState
			if claim != null:
				highest = maxi(highest, claim.id)
	for claim in _pending_rework:
		if claim != null:
			highest = maxi(highest, claim.id)
	for worker in workers:
		if worker.current_claim != null:
			highest = maxi(highest, worker.current_claim.id)
	return highest


func set_worker_at_workstation(worker_id: int, is_present: bool) -> void:
	if worker_id < 0 or worker_id >= workers.size():
		push_warning("Ignoring workstation presence for unknown worker %d." % worker_id)
		return
	_worker_at_workstation[worker_id] = is_present and workers[worker_id].employed


func is_worker_at_workstation(worker_id: int) -> bool:
	return (
		worker_id >= 0
		and worker_id < workers.size()
		and workers[worker_id].employed
		and bool(_worker_at_workstation.get(worker_id, false))
	)


func routing_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for lane in CLAIM_LANES:
		var definition: Dictionary = CLAIM_LANE_DEFINITIONS[lane]
		catalog.append({
			"id": lane,
			"display_name": String(definition["display_name"]),
			"short_name": String(definition["short_name"]),
			"description": String(definition["description"]),
			"base_difficulty": float(definition["base_difficulty"]),
			"base_value_cents": int(definition["base_value_cents"]),
			"crack_modifier": float(definition["crack_modifier"]),
			"deadline_minutes": int(definition["deadline_minutes"]),
			"arrival_weight": float(definition["arrival_weight"]),
			"accent_hex": String(definition["accent_hex"]),
		})
	return catalog


func set_worker_assignment(worker_id: int, lane: StringName) -> bool:
	if worker_id < 0 or worker_id >= workers.size():
		return false
	if not workers[worker_id].employed:
		return false
	if lane != AUTO_ASSIGNMENT and not CLAIM_LANE_DEFINITIONS.has(lane):
		return false
	var worker := workers[worker_id]
	if worker.assigned_lane == lane:
		return true
	worker.assigned_lane = lane
	_breach_specialty_compact_for_assignment(worker)
	snapshot_changed.emit(snapshot())
	return true


func personnel_action_catalog(worker_id: int = -1) -> Array[Dictionary]:
	var preferred_action: StringName = &""
	if worker_id >= 0 and worker_id < workers.size() and workers[worker_id].employed:
		preferred_action = _preferred_personnel_action(workers[worker_id])
	var catalog: Array[Dictionary] = []
	for action_id in PERSONNEL_ACTION_ORDER:
		var definition: Dictionary = PERSONNEL_ACTION_DEFINITIONS[action_id]
		catalog.append({
			"id": action_id,
			"name": String(definition["name"]),
			"short_name": String(definition["short_name"]),
			"description": String(definition["description"]),
			"preview": String(definition["preview"]),
			"cost_cents": int(definition["cost_cents"]),
			"tone": StringName(definition["tone"]),
			"preferred": preferred_action == action_id,
		})
	return catalog


func personnel_action_used_today() -> bool:
	for worker in workers:
		if not worker.employed:
			continue
		if worker.last_personnel_action_day == day and worker.last_personnel_action != &"":
			return true
	return false


func personnel_action_status() -> Dictionary:
	var action := _personnel_action_for_day(day)
	var available := shift_phase == ShiftPhase.RUNNING and action.is_empty()
	var reason := ""
	if not action.is_empty():
		reason = "Today's flock check-in is already filed."
	elif shift_phase != ShiftPhase.RUNNING:
		reason = "Resolve the current management decision first."
	return {
		"available": available,
		"used_today": not action.is_empty(),
		"day": day,
		"reason": reason,
		"last_action": action,
	}


func perform_personnel_action(worker_id: int, action_id: StringName) -> Dictionary:
	## One consequential check-in is available across the entire flock each shift.
	## Every guard runs before the first mutation so denied actions are atomic.
	if worker_id < 0 or worker_id >= workers.size():
		return _rejected_personnel_action("Select a valid hen before filing a check-in.")
	if not workers[worker_id].employed:
		return _rejected_personnel_action("Applicants cannot receive active-roster check-ins.")
	if not PERSONNEL_ACTION_DEFINITIONS.has(action_id):
		return _rejected_personnel_action("That personnel action is not in the approved handbook.")
	if shift_phase != ShiftPhase.RUNNING:
		return _rejected_personnel_action("Resolve the current management decision first.")
	if personnel_action_used_today():
		return _rejected_personnel_action("Today's flock check-in is already filed.")
	var definition: Dictionary = PERSONNEL_ACTION_DEFINITIONS[action_id]
	var cost_cents := int(definition["cost_cents"])
	var spendable := spendable_fund_cents()
	if spendable < cost_cents:
		return _rejected_personnel_action(
			"Check-in denied: $%.2f more spendable Feed Fund required." % (
				float(cost_cents - spendable) / 100.0
			)
		)

	var worker := workers[worker_id]
	var preferred := _preferred_personnel_action(worker) == action_id
	var before := {
		"trust": worker.manager_trust,
		"grievance": worker.grievance,
		"morale": worker.morale,
		"stress": worker.stress,
		"fatigue": worker.fatigue,
		"career_xp": worker.career_xp,
		"executive_confidence": executive_confidence,
		"compliance": compliance,
		"solidarity": solidarity,
		"career_title": worker.career_title(),
	}
	revenue_cents -= cost_cents
	match action_id:
		&"share_credit":
			worker.manager_trust = clampf(worker.manager_trust + (18.0 if preferred else 14.0), 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - (13.0 if preferred else 10.0), 0.0, 100.0)
			worker.morale = clampf(worker.morale + (10.0 if preferred else 8.0), 0.0, 100.0)
			worker.stress = clampf(worker.stress - 5.0, 0.0, 100.0)
			worker.add_career_xp(6)
			executive_confidence = clampf(executive_confidence - 2.0, 0.0, 100.0)
			solidarity = clampf(solidarity + 2.0, 0.0, 100.0)
		&"career_coaching":
			worker.manager_trust = clampf(worker.manager_trust + (9.0 if preferred else 7.0), 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 3.0, 0.0, 100.0)
			worker.morale = clampf(worker.morale + 3.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 3.0, 0.0, 100.0)
			worker.fatigue = clampf(worker.fatigue + 2.0, 0.0, 100.0)
			worker.add_career_xp(22 if preferred else 18)
			compliance = clampf(compliance + 2.0, 0.0, 100.0)
		&"quota_pressure":
			worker.manager_trust = clampf(worker.manager_trust - 12.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance + (10.0 if preferred else 14.0), 0.0, 100.0)
			worker.morale = clampf(worker.morale - 7.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 8.0, 0.0, 100.0)
			worker.fatigue = clampf(worker.fatigue + 4.0, 0.0, 100.0)
			worker.add_career_xp(5)
			executive_confidence = clampf(executive_confidence + 3.0, 0.0, 100.0)
			compliance = clampf(compliance + 2.0, 0.0, 100.0)
			solidarity = clampf(solidarity + 4.0, 0.0, 100.0)
	worker.last_personnel_action = action_id
	worker.last_personnel_action_day = day
	if action_id == &"quota_pressure":
		_breach_safe_pace_compact(&"quota_pressure")

	var effects := {
		"trust": worker.manager_trust - float(before["trust"]),
		"grievance": worker.grievance - float(before["grievance"]),
		"morale": worker.morale - float(before["morale"]),
		"stress": worker.stress - float(before["stress"]),
		"fatigue": worker.fatigue - float(before["fatigue"]),
		"career_xp": worker.career_xp - int(before["career_xp"]),
		"farmer_favor": executive_confidence - float(before["executive_confidence"]),
		"compliance": compliance - float(before["compliance"]),
		"solidarity": solidarity - float(before["solidarity"]),
		"shift_work_multiplier": _personnel_shift_work_multiplier(worker),
		"shift_crack_modifier": _personnel_shift_crack_modifier(worker),
	}
	var outcome := _personnel_action_outcome(worker, action_id)
	var result := {
		"accepted": true,
		"day": day,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"action_id": action_id,
		"action_name": String(definition["name"]),
		"cost_cents": cost_cents,
		"preferred": preferred,
		"effects": effects,
		"promoted": String(before["career_title"]) != worker.career_title(),
		"career_title": worker.career_title(),
		"outcome": outcome,
	}
	announcement_posted.emit(outcome)
	if bool(result["promoted"]):
		announcement_posted.emit("PROMOTION FILED: %s is now %s." % [worker.display_name.to_upper(), worker.career_title()])
	personnel_action_resolved.emit(result.duplicate(true))
	snapshot_changed.emit(snapshot())
	return result


func _rejected_personnel_action(reason: String) -> Dictionary:
	return {"accepted": false, "reason": reason}


func peck_assist_delivery_status() -> Dictionary:
	var pending_deliveries := _pending_peck_assist_delivery_snapshot()
	var pending_delivery: Dictionary = (
		(pending_deliveries[0] as Dictionary).duplicate(true)
		if not pending_deliveries.is_empty() else
		{}
	)
	var charges := _peck_assist_charges_available()
	var reason := "%d/%d attention charges ready; each clean assisted delivery restores one." % [
		charges,
		PECK_ASSIST_LIMIT,
	]
	if not pending_deliveries.is_empty():
		var charge_prefix := (
			"Management attention is fully allocated; "
			if charges <= 0 else
			"%d/%d attention charges are ready; " % [charges, PECK_ASSIST_LIMIT]
		)
		reason = "%s%d clean assisted %s awaiting farmer delivery, and each presentation restores one charge." % [
			charge_prefix,
			pending_deliveries.size(),
			("egg is" if pending_deliveries.size() == 1 else "eggs are"),
		]
	elif charges <= 0:
		reason = "Management attention is fully allocated this shift; only a pending clean assisted delivery can restore a charge."
	elif charges == PECK_ASSIST_LIMIT:
		reason = "All %d management-attention charges are ready." % PECK_ASSIST_LIMIT
	return {
		"charges": charges,
		"limit": PECK_ASSIST_LIMIT,
		"gross_interventions": peck_assist_interventions_today,
		"refunds": peck_assist_refunds_today,
		"pending_delivery": pending_delivery,
		"pending_delivery_count": pending_deliveries.size(),
		"pending_deliveries": pending_deliveries,
		"last_delivery": last_peck_assist_delivery.duplicate(true),
		"reason": reason,
	}


func peck_assist_status(worker_id: int) -> Dictionary:
	## A short, optional timing intervention. The authoritative claim progress is
	## the timing cursor, so UI refresh rate and input device cannot spoof a score.
	var delivery_status := peck_assist_delivery_status()
	var remaining := int(delivery_status.get("charges", 0))
	var status := {
		"available": false,
		"remaining": remaining,
		"charges": remaining,
		"limit": PECK_ASSIST_LIMIT,
		"gross_interventions": peck_assist_interventions_today,
		"refunds": peck_assist_refunds_today,
		"pending_delivery": (delivery_status.get("pending_delivery", {}) as Dictionary).duplicate(true),
		"pending_delivery_count": int(delivery_status.get("pending_delivery_count", 0)),
		"delivery_reason": String(delivery_status.get("reason", "")),
		"streak": peck_assist_streak,
		"best_streak": best_peck_assist_streak,
		"window_start": PECK_ASSIST_WINDOW_START,
		"window_end": PECK_ASSIST_WINDOW_END,
		"ideal_progress": PECK_ASSIST_IDEAL_PROGRESS,
		"window_state": &"locked",
		"timing_score": 0.0,
		"timing_label": "LOCKED",
		"reason": "Select a working hen to synchronize peckwork.",
		"claim_id": -1,
	}
	if worker_id < 0 or worker_id >= workers.size():
		return status
	var worker := workers[worker_id]
	if not worker.employed:
		status["reason"] = "Applicants do not have active peckwork."
		return status
	if shift_phase != ShiftPhase.RUNNING or not pending_decision.is_empty():
		status["reason"] = "Resolve the current management file first."
		return status
	if remaining <= 0:
		status["window_state"] = &"spent"
		status["reason"] = String(delivery_status.get(
			"reason",
			"Management attention is fully allocated this shift.",
		))
		return status
	if not is_worker_at_workstation(worker_id):
		status["reason"] = "%s must be visibly seated before peck support can begin." % worker.display_name
		return status
	if worker.work_state != ChickenState.WorkState.WORKING or worker.current_claim == null:
		status["window_state"] = &"waiting"
		status["reason"] = "Wait until %s is actively pecking a claim." % worker.display_name
		return status
	var claim_id := worker.current_claim.id
	status["claim_id"] = claim_id
	if _assisted_claim_ids.has(claim_id):
		status["window_state"] = &"used"
		status["reason"] = "This claim already carries a Priority Peck stamp."
		return status
	if _missed_assist_claim_ids.has(claim_id):
		status["window_state"] = &"missed"
		status["reason"] = "The synchronization window closed; the next claim can restart the chain."
		return status
	var progress := worker.work_progress
	var score := _peck_assist_timing_score(progress)
	status["timing_score"] = score
	status["timing_label"] = _peck_assist_timing_label(score)
	if progress < PECK_ASSIST_WINDOW_START:
		status["window_state"] = &"not_ready"
		status["reason"] = "Build the claim rhythm to %d%% before stamping." % int(PECK_ASSIST_WINDOW_START)
		return status
	if progress > PECK_ASSIST_WINDOW_END:
		status["window_state"] = &"passed"
		status["reason"] = "The safe synchronization window has passed for this claim."
		return status
	status["available"] = true
	status["window_state"] = &"open"
	status["reason"] = "Stamp near %d%% for the strongest speed and shell-quality bonus." % int(PECK_ASSIST_IDEAL_PROGRESS)
	return status


func recommended_peck_assist_worker_id() -> int:
	var recommended_id := -1
	var recommended_deadline := 2_000_000_000
	for worker in workers:
		if not bool(peck_assist_status(worker.id).get("available", false)):
			continue
		if worker.current_claim == null:
			continue
		var deadline := worker.current_claim.deadline_operational_minute
		if deadline < recommended_deadline or (deadline == recommended_deadline and worker.id < recommended_id):
			recommended_deadline = deadline
			recommended_id = worker.id
	return recommended_id


func perform_peck_assist(worker_id: int) -> Dictionary:
	## One input, one exact claim, one atomic result. Progress caps below LAYING,
	## preserving the normal seated work, laying, and farmer-collection pipeline.
	var status := peck_assist_status(worker_id)
	if not bool(status.get("available", false)):
		return {
			"accepted": false,
			"reason": String(status.get("reason", "Priority Peck is unavailable.")),
			"status": status,
		}
	var worker := workers[worker_id]
	var claim_id := int(status.get("claim_id", -1))
	if worker.current_claim == null or worker.current_claim.id != claim_id:
		return {"accepted": false, "reason": "The active claim changed before the stamp landed."}

	var progress_before := worker.work_progress
	var stress_before := worker.stress
	var fatigue_before := worker.fatigue
	var morale_before := worker.morale
	var timing_score := float(status.get("timing_score", 0.0))
	var rating := _peck_assist_rating(timing_score)
	var quality_modifier := 0.01
	var progress_gain := 10.0
	match rating:
		&"perfect":
			quality_modifier = -0.06
			progress_gain = 24.0
			worker.morale = minf(100.0, worker.morale + 2.0)
			worker.stress = minf(100.0, worker.stress + 1.0)
		&"strong":
			quality_modifier = -0.04
			progress_gain = 20.0
			worker.morale = minf(100.0, worker.morale + 1.0)
			worker.stress = minf(100.0, worker.stress + 1.5)
		&"steady":
			quality_modifier = -0.025
			progress_gain = 15.0
			worker.stress = minf(100.0, worker.stress + 2.0)
		_:
			worker.stress = minf(100.0, worker.stress + 4.0)
			worker.fatigue = minf(100.0, worker.fatigue + 2.0)
			worker.morale = maxf(0.0, worker.morale - 1.0)

	if rating in [&"perfect", &"strong"]:
		peck_assist_streak += 1
	else:
		peck_assist_streak = 0
	best_peck_assist_streak = maxi(best_peck_assist_streak, peck_assist_streak)
	var chain_bonus_progress := mini(peck_assist_streak, 5) * 2.0
	progress_gain += chain_bonus_progress
	# UI intervention may rescue a file, but it never lays or credits an egg.
	# The normal seated worker tick must still cross the finish line.
	worker.work_progress = minf(99.0, worker.work_progress + progress_gain)

	peck_assists_used_today += 1
	peck_assist_interventions_today += 1
	_assisted_claim_ids[claim_id] = true
	_assist_quality_modifiers[claim_id] = quality_modifier
	_assist_chain_by_claim_id[claim_id] = peck_assist_streak
	var result := {
		"accepted": true,
		"day": day,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"claim_id": claim_id,
		"rating": rating,
		"timing_score": timing_score,
		"timing_label": _peck_assist_timing_label(timing_score),
		"progress_before": progress_before,
		"progress_after": worker.work_progress,
		"progress_gain": worker.work_progress - progress_before,
		"quality_modifier": quality_modifier,
		"stress_delta": worker.stress - stress_before,
		"fatigue_delta": worker.fatigue - fatigue_before,
		"morale_delta": worker.morale - morale_before,
		"streak": peck_assist_streak,
		"best_streak": best_peck_assist_streak,
		"remaining": _peck_assist_charges_available(),
		"charges": _peck_assist_charges_available(),
		"gross_interventions": peck_assist_interventions_today,
		"refunds": peck_assist_refunds_today,
		"potential_priority_credit_cents": 20 * mini(peck_assist_streak, 5),
	}
	result = _normalized_peck_assist_record(result)
	last_peck_assist = result.duplicate(true)
	announcement_posted.emit(
		"PRIORITY PECK %s: %s synchronized claim #%04d. Chain x%d." % [
			String(rating).to_upper(), worker.display_name, claim_id, peck_assist_streak,
		]
	)
	peck_assist_resolved.emit(result.duplicate(true))
	snapshot_changed.emit(snapshot())
	return result


func settle_peck_assist_delivery(claim_id: int, quality: StringName) -> Dictionary:
	## Presentation is the exact-once settlement boundary. Egg completion may mint
	## one clean-delivery token, but only this API can turn that token back into a
	## management-attention charge.
	var normalized_quality := StringName(String(quality))
	if claim_id < 1:
		return _rejected_peck_assist_delivery(
			claim_id,
			normalized_quality,
			"A valid completed claim is required before attention can be restored.",
		)
	if _settled_peck_assist_delivery_ids.has(claim_id):
		return _rejected_peck_assist_delivery(
			claim_id,
			normalized_quality,
			"This assisted delivery already restored its one attention charge.",
		)
	var token_value: Variant = _pending_peck_assist_deliveries.get(claim_id, {})
	if not token_value is Dictionary or (token_value as Dictionary).is_empty():
		var missing_reason := (
			"Cracked assisted work breaks the chain and cannot restore attention."
			if normalized_quality == &"cracked" else
			"No clean assisted delivery is pending for claim #%04d." % claim_id
		)
		return _rejected_peck_assist_delivery(claim_id, normalized_quality, missing_reason)
	var token := token_value as Dictionary
	var expected_quality := StringName(String(token.get("quality", "")))
	if normalized_quality != expected_quality:
		return _rejected_peck_assist_delivery(
			claim_id,
			normalized_quality,
			"Claim #%04d was graded %s, not %s; the delivery token remains pending." % [
				claim_id,
				String(expected_quality).to_upper(),
				String(normalized_quality).to_upper(),
			],
		)
	if normalized_quality not in [&"sound", &"golden"]:
		return _rejected_peck_assist_delivery(
			claim_id,
			normalized_quality,
			"Only a sound or golden assisted delivery can restore attention.",
		)
	if peck_assists_used_today <= 0:
		return _rejected_peck_assist_delivery(
			claim_id,
			normalized_quality,
			"All attention charges are already available; the pending token was left intact.",
		)

	var charges_before := _peck_assist_charges_available()
	_pending_peck_assist_deliveries.erase(claim_id)
	_settled_peck_assist_delivery_ids[claim_id] = true
	peck_assists_used_today = maxi(0, peck_assists_used_today - 1)
	peck_assist_refunds_today += 1
	var charges_after := _peck_assist_charges_available()
	var receipt := {
		"accepted": true,
		"refunded": true,
		"refund_amount": charges_after - charges_before,
		"day": day,
		"claim_id": claim_id,
		"quality": String(normalized_quality),
		"charges_before": charges_before,
		"charges_after": charges_after,
		"remaining": charges_after,
		"gross_interventions": peck_assist_interventions_today,
		"refunds": peck_assist_refunds_today,
		"pending_delivery_count": _pending_peck_assist_deliveries.size(),
		"reason": "%s claim #%04d reached the farmer; one attention charge was restored." % [
			String(normalized_quality).capitalize(),
			claim_id,
		],
	}
	receipt = _normalized_peck_assist_delivery_receipt(receipt)
	last_peck_assist_delivery = receipt.duplicate(true)
	announcement_posted.emit(String(receipt.get("reason", "PRIORITY PECK ATTENTION RESTORED.")))
	snapshot_changed.emit(snapshot())
	return receipt


func _rejected_peck_assist_delivery(
	claim_id: int,
	quality: StringName,
	reason: String
) -> Dictionary:
	return {
		"accepted": false,
		"refunded": false,
		"refund_amount": 0,
		"day": day,
		"claim_id": claim_id,
		"quality": String(quality),
		"charges_before": _peck_assist_charges_available(),
		"charges_after": _peck_assist_charges_available(),
		"remaining": _peck_assist_charges_available(),
		"gross_interventions": peck_assist_interventions_today,
		"refunds": peck_assist_refunds_today,
		"pending_delivery_count": _pending_peck_assist_deliveries.size(),
		"reason": reason,
	}


func _peck_assist_timing_score(progress: float) -> float:
	return clampf(1.0 - absf(progress - PECK_ASSIST_IDEAL_PROGRESS) / 34.0, 0.0, 1.0)


func _peck_assist_rating(timing_score: float) -> StringName:
	if timing_score >= 0.88:
		return &"perfect"
	if timing_score >= 0.68:
		return &"strong"
	if timing_score >= 0.42:
		return &"steady"
	return &"scramble"


func _peck_assist_timing_label(timing_score: float) -> String:
	match _peck_assist_rating(timing_score):
		&"perfect":
			return "GOLDEN RHYTHM"
		&"strong":
			return "CLEAN RHYTHM"
		&"steady":
			return "WORKABLE RHYTHM"
		_:
			return "RISKY RHYTHM"


func _preferred_personnel_action(worker: ChickenState) -> StringName:
	var definition := CAREER_PROFILE_DEFINITIONS.get(worker.career_profile, {}) as Dictionary
	return StringName(definition.get("preferred_action", &""))


func _personnel_action_outcome(worker: ChickenState, action_id: StringName) -> String:
	match action_id:
		&"share_credit":
			return "%s's name made it onto the basket. The farmer has requested a smaller font." % worker.display_name
		&"career_coaching":
			return "%s's development time was approved and immediately entered as lost capacity." % worker.display_name
		&"quota_pressure":
			return "The stretch clutch was accepted on %s's behalf. The grievance ledger noticed." % worker.display_name
	return "Personnel action filed."


func claim_queue_count(lane: StringName) -> int:
	if not CLAIM_LANE_DEFINITIONS.has(lane):
		return -1
	return (_claim_queues.get(lane, []) as Array).size()


func _lane_display_name(lane: StringName) -> String:
	if not CLAIM_LANE_DEFINITIONS.has(lane):
		return "AUTO DISPATCH" if lane == AUTO_ASSIGNMENT else "UNASSIGNED"
	return String((CLAIM_LANE_DEFINITIONS[lane] as Dictionary)["display_name"])


func directive_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for directive_id in DIRECTIVE_ORDER:
		var definition: Dictionary = DIRECTIVE_DEFINITIONS[directive_id]
		catalog.append({
			"id": directive_id,
			"name": String(definition["name"]),
			"short_name": String(definition["short_name"]),
			"tagline": String(definition["tagline"]),
			"preview": String(definition["preview"]),
			"tone": StringName(definition.get("tone", &"quality")),
		})
	return catalog


func active_directive_snapshot() -> Dictionary:
	if active_directive_id == &"" or not DIRECTIVE_DEFINITIONS.has(active_directive_id):
		return {}
	var definition: Dictionary = DIRECTIVE_DEFINITIONS[active_directive_id]
	return {
		"id": active_directive_id,
		"name": String(definition["name"]),
		"short_name": String(definition["short_name"]),
		"preview": String(definition["preview"]),
	}


func pending_decision_snapshot() -> Dictionary:
	return pending_decision.duplicate(true)


func announce_pending_decision() -> bool:
	if pending_decision.is_empty():
		return false
	decision_requested.emit(pending_decision_snapshot())
	return true


func begin_next_shift_briefing() -> bool:
	if shift_phase != ShiftPhase.REVIEW:
		return false
	if not pending_decision.is_empty():
		announcement_posted.emit("NEXT SHIFT HELD: file the closing credit memo first.")
		return false
	_prepare_morning_directive()
	shift_phase_changed.emit(shift_phase)
	decision_requested.emit(pending_decision_snapshot())
	snapshot_changed.emit(snapshot())
	return true


func select_directive(directive_id: StringName) -> bool:
	if pending_decision.is_empty() or StringName(pending_decision.get("kind", &"")) != &"directive":
		return false
	return resolve_decision(int(pending_decision.get("serial", -1)), directive_id)


func resolve_decision(serial: int, option_id: StringName) -> bool:
	if pending_decision.is_empty() or serial != int(pending_decision.get("serial", -1)):
		return false
	var valid_option := false
	for option_value in pending_decision.get("options", []):
		var option := option_value as Dictionary
		if StringName(option.get("id", &"")) == option_id:
			valid_option = true
			break
	if not valid_option:
		return false
	match StringName(pending_decision.get("kind", &"")):
		&"directive":
			return _resolve_directive(option_id)
		&"incident":
			return _resolve_incident(option_id)
		&"credit_allocation":
			return _resolve_credit_allocation(option_id)
		&"major_event":
			if StringName(pending_decision.get("id", &"")) == &"flock_restructuring":
				return _resolve_flock_restructuring(option_id)
			return _resolve_credit_allocation(option_id)
	return false


func _prepare_credit_allocation_decision(
	completed_day: int,
	ranking: Array[Dictionary],
	completed_golden: int,
) -> void:
	if completed_day >= PROBATION_CAMPAIGN_SHIFTS or ranking.is_empty():
		return
	var is_golden_dossier := (
		completed_day == GOLDEN_DOSSIER_FALLBACK_SHIFT
		and not golden_dossier_resolved
	)
	var is_flock_restructuring := (
		completed_day == FLOCK_RESTRUCTURING_SHIFT
		and not flock_restructuring_resolved
	)
	var projected_golden := is_golden_dossier and completed_golden <= 0
	var subject := ranking[ranking.size() - 1] if is_flock_restructuring else ranking[0]
	if is_golden_dossier and completed_golden > 0:
		for row in ranking:
			if int(row.get("golden", 0)) > 0:
				subject = row
				break
	var options := (
		_flock_restructuring_options(String(subject.get("worker_name", "LOWEST LAYER")))
		if is_flock_restructuring else
		_credit_allocation_options(
			is_golden_dossier,
			String(subject.get("worker_name", "TOP LAYER")),
		)
	)
	var ranking_lines: Array[String] = []
	for index in mini(3, ranking.size()):
		var row := ranking[index]
		ranking_lines.append("#%d  %s  /  %d eggs  /  $%.2f credit" % [
			int(row.get("rank", index + 1)),
			String(row.get("worker_name", "HEN")).to_upper(),
			int(row.get("eggs", 0)),
			float(int(row.get("credit_cents", 0))) / 100.0,
		])
	var body := "%s\n\n%s" % [
		"The ranking is final: credit value first, then golden eggs, fewer cracks, and employee number.",
		"\n".join(ranking_lines),
	]
	var decision_kind: StringName = &"credit_allocation"
	var decision_id: StringName = &"closing_credit_memo"
	var eyebrow := "PECKING ORDER  /  SHIFT %d CLOSED" % completed_day
	var title := "WHO GETS THE CREDIT?"
	if is_golden_dossier:
		decision_kind = &"major_event"
		decision_id = &"golden_egg_dossier"
		eyebrow = "CONFIDENTIAL DOSSIER  /  GOLDEN EGG"
		title = "WHO OWNS THE GOLDEN OUTCOME?"
		body = "%s\n\n%s" % [
			(
				"No natural golden egg arrived, so Brand has designated %s's highest-value file a PROJECTED GOLDEN OUTCOME. Ownership is still due before the deck."
				% String(subject.get("worker_name", "the leading hen")).to_upper()
				if projected_golden else
				"%s produced a golden egg. The farmer wants an owner, a patent, and a cleaner version of the story before morning."
				% String(subject.get("worker_name", "The leading hen")).to_upper()
			),
			"\n".join(ranking_lines),
		]
	elif is_flock_restructuring:
		decision_kind = &"major_event"
		decision_id = &"flock_restructuring"
		eyebrow = "CONFIDENTIAL DOSSIER  /  FLOCK RESTRUCTURING"
		title = "WHO CARRIES THE EFFICIENCY VARIANCE?"
		body = _flock_restructuring_body(subject, ranking_lines, completed_day)
	_decision_serial += 1
	pending_decision = {
		"serial": _decision_serial,
		"kind": decision_kind,
		"id": decision_id,
		"day": completed_day,
		"completed_day": completed_day,
		"eyebrow": eyebrow,
		"title": title,
		"body": body,
		"options": options,
		"ranking": ranking.duplicate(true),
		"subject_worker_id": int(subject.get("worker_id", -1)),
		"subject_worker_name": String(subject.get("worker_name", "")),
		"projected": projected_golden,
		"confirm_label": "FILE RESTRUCTURING ORDER" if is_flock_restructuring else "FILE CREDIT MEMO",
		"selection_prompt": (
			"Choose what happens to the named hen. The omitted context and exact Day-5 consequences are shown before filing."
			if is_flock_restructuring else
			"Choose an attribution. Its exact cost and next-shift consequences are shown before filing."
		),
		"allow_stay_paused": false,
		"resume_policy": &"review",
	}


func _flock_restructuring_body(
	subject_row: Dictionary,
	ranking_lines: Array[String],
	completed_day: int,
) -> String:
	var worker_id := int(subject_row.get("worker_id", -1))
	var worker: ChickenState = workers[worker_id] if worker_id >= 0 and worker_id < workers.size() else null
	var subject_name := String(subject_row.get("worker_name", "THE LOWEST LAYER")).to_upper()
	var context_lines: Array[String] = []
	if worker != null:
		var assignment_name := _lane_display_name(worker.assigned_lane)
		var specialty_name := _lane_display_name(worker.specialty)
		context_lines.append("Career: %s  /  %d XP  /  specialty %s" % [
			worker.career_title(), worker.career_xp, specialty_name,
		])
		context_lines.append("Human cost: trust %d  /  grievance %d  /  stress %d  /  fatigue %d" % [
			roundi(worker.manager_trust), roundi(worker.grievance), roundi(worker.stress), roundi(worker.fatigue),
		])
		if worker.assigned_lane != AUTO_ASSIGNMENT and worker.assigned_lane != worker.specialty:
			context_lines.append("Management routed %s into %s, outside her %s specialty." % [
				subject_name, assignment_name, specialty_name,
			])
		if worker.last_personnel_action_day == completed_day and worker.last_personnel_action == &"quota_pressure":
			context_lines.append("Management authorized a stretch clutch on her behalf this shift.")
		elif worker.last_personnel_action_day == completed_day and worker.last_personnel_action == &"career_coaching":
			context_lines.append("Her approved coaching time was counted against visible output.")
	if context_lines.size() <= 2:
		context_lines.append("The ranking excludes claim difficulty, breaks covered, and work reassigned by management.")
	return "%s\n\n%s\n\n%s\n%s" % [
		"The farmer wants one efficiency variance removed before the final presentation. The frozen ranking nominates %s because the ledger measures credited output, not how the work was produced." % subject_name,
		"\n".join(ranking_lines),
		"LOWEST RANKED  /  #%d  /  %d eggs  /  %d cracked  /  $%.2f credited" % [
			int(subject_row.get("rank", 0)), int(subject_row.get("eggs", 0)),
			int(subject_row.get("cracked", 0)), float(int(subject_row.get("credit_cents", 0))) / 100.0,
		],
		"OMITTED CONTEXT\n%s" % "\n".join(context_lines),
	]


func _flock_restructuring_options(subject_name: String) -> Array[Dictionary]:
	return [
		{
			"id": &"nominate_variance",
			"label": "NOMINATE THE LOWEST LAYER",
			"tagline": "%s leaves; the chart becomes easier to explain." % subject_name.to_upper(),
			"preview": "+$18 fund  /  +8 farmer favor  /  next quota +2  /  flock trust -10, grievance +12  /  candidate released",
			"outcome": "%s was removed as the efficiency variance. Her empty chair will appear in the farmer's deck as recovered capacity." % subject_name,
			"cost_cents": 0,
			"style_id": &"management_innovation",
			"tone": &"danger",
		},
		{
			"id": &"fund_redeployment",
			"label": "FUND A REDEPLOYMENT",
			"tagline": "Keep %s and correct the conditions behind the ranking." % subject_name.to_upper(),
			"preview": "Cost $12  /  candidate +8 morale, +14 trust, -12 grievance, +18 XP  /  favor -5  /  next quota -1",
			"outcome": "%s was redeployed into her specialty. Finance has categorized the avoided dismissal as an experimental expense." % subject_name,
			"cost_cents": 1200,
			"style_id": &"individual_merit",
			"tone": &"quality",
		},
		{
			"id": &"contest_ranking",
			"label": "CONTEST THE RANKING COLLECTIVELY",
			"tagline": "Keep the hen and put the measurement system on trial.",
			"preview": "No cost  /  flock +4 morale, +8 trust, -6 grievance, +15 unity  /  favor -10  /  obedience -5  /  next quota +2",
			"outcome": "The flock contested the ranking together. The farmer has retained every hen and added retaliation to tomorrow's target.",
			"cost_cents": 0,
			"style_id": &"shared_scoop",
			"tone": &"care",
		},
	]


func _credit_allocation_options(is_golden_dossier: bool, subject_name: String) -> Array[Dictionary]:
	if is_golden_dossier:
		return [
			{
				"id": &"name_the_layer",
				"label": "NAME THE LAYER",
				"tagline": "%s keeps authorship." % subject_name.to_upper(),
				"preview": "No cost  /  author +10 morale, +12 trust, -8 grievance, +12 XP  /  farmer favor -3",
				"outcome": "%s was named in the Golden Egg filing. The farmer has requested a shorter author list next time." % subject_name,
				"cost_cents": 0,
				"style_id": &"individual_merit",
				"tone": &"quality",
			},
			{
				"id": &"flock_owned_patent",
				"label": "DECLARE FLOCK-OWNED WORK",
				"tagline": "The patent belongs to every beak in the process.",
				"preview": "No cost  /  flock +5 morale, +4 trust, -4 grievance, +10 unity  /  favor -5  /  next quota +1",
				"outcome": "The Golden Egg was filed as collective work. Legal has described the flock as an unauthorized plural noun.",
				"cost_cents": 0,
				"style_id": &"shared_scoop",
				"tone": &"care",
			},
			{
				"id": &"patent_rooster_method",
				"label": "PATENT THE ROOSTER METHOD",
				"tagline": "The egg becomes evidence of management innovation.",
				"preview": "+$15 fund  /  +9 farmer favor  /  next quota +2  /  author trust -14, grievance +14",
				"outcome": "The Golden Egg is now a rooster-authored process improvement. The layer appears only in the risk appendix.",
				"cost_cents": 0,
				"style_id": &"management_innovation",
				"tone": &"danger",
			},
		]
	return [
		{
			"id": &"reward_top_layer",
			"label": "INDIVIDUAL MERIT",
			"tagline": "%s gets the byline." % subject_name.to_upper(),
			"preview": "No cost  /  winner +4 morale, +4 trust, +3 XP  /  every rival +1 grievance",
			"outcome": "%s received the merit stamp. The rest of the flock has received a motivational comparison." % subject_name,
			"cost_cents": 0,
			"style_id": &"individual_merit",
			"tone": &"quality",
		},
		{
			"id": &"share_feed_credit",
			"label": "SHARED SCOOP",
			"tagline": "Distribute feed and authorship across the closing roster.",
			"preview": "Cost $8  /  flock +4 morale, +3 trust, -2 grievance, +4 unity  /  farmer favor -2",
			"outcome": "Credit was shared with the flock. Accounting has recorded the feed as a collective attitude expense.",
			"cost_cents": 800,
			"style_id": &"shared_scoop",
			"tone": &"care",
		},
		{
			"id": &"claim_management_innovation",
			"label": "MANAGEMENT INNOVATION",
			"tagline": "The rooster's process produced every egg in the deck.",
			"preview": "+$8 fund  /  +5 farmer favor  /  next quota +1  /  flock trust -3, grievance +4",
			"outcome": "The ranking was patented as a management method. Tomorrow's quota already reflects its success.",
			"cost_cents": 0,
			"style_id": &"management_innovation",
			"tone": &"danger",
		},
	]


func _resolve_credit_allocation(option_id: StringName) -> bool:
	if shift_phase != ShiftPhase.REVIEW:
		return false
	var decision_kind := StringName(pending_decision.get("kind", &""))
	if decision_kind not in [&"credit_allocation", &"major_event"]:
		return false
	var chosen: Dictionary = {}
	for option_value in pending_decision.get("options", []):
		var option := option_value as Dictionary
		if StringName(option.get("id", &"")) == option_id:
			chosen = option
			break
	if chosen.is_empty():
		return false
	var cost_cents := int(chosen.get("cost_cents", 0))
	var spendable := spendable_fund_cents()
	if spendable < cost_cents:
		announcement_posted.emit(
			"CREDIT MEMO HELD: $%.2f more spendable Feed Fund required." % (
				float(cost_cents - spendable) / 100.0
			)
		)
		return false
	var subject_worker_id := int(pending_decision.get("subject_worker_id", -1))
	var ranked_worker_ids: Array[int] = []
	for row_value in pending_decision.get("ranking", []):
		var row := row_value as Dictionary
		var worker_id := int(row.get("worker_id", -1))
		if worker_id >= 0 and worker_id < workers.size() and worker_id not in ranked_worker_ids:
			ranked_worker_ids.append(worker_id)
	revenue_cents -= cost_cents
	_apply_credit_allocation_effects(option_id, subject_worker_id, ranked_worker_ids)
	var style_id := StringName(chosen.get("style_id", &"management_innovation"))
	credit_choice_counts[style_id] = int(credit_choice_counts.get(style_id, 0)) + 1
	var completed_day := int(pending_decision.get("completed_day", pending_decision.get("day", day - 1)))
	var is_special := decision_kind == &"major_event"
	if is_special:
		golden_dossier_resolved = true
		golden_dossier_day = completed_day
	var outcome := String(chosen.get("outcome", "Closing credit memo filed."))
	var serial := int(pending_decision.get("serial", -1))
	var decision_id := StringName(pending_decision.get("id", &"closing_credit_memo"))
	last_credit_allocation = {
		"day": completed_day,
		"decision_id": String(decision_id),
		"option_id": String(option_id),
		"style_id": String(style_id),
		"worker_id": subject_worker_id,
		"worker_name": String(pending_decision.get("subject_worker_name", "")),
		"cost_cents": cost_cents,
		"outcome": outcome,
		"special_event": is_special,
		"projected": bool(pending_decision.get("projected", false)),
	}
	pending_decision.clear()
	announcement_posted.emit(outcome)
	decision_resolved.emit({
		"serial": serial,
		"kind": decision_kind,
		"decision_id": decision_id,
		"option_id": option_id,
		"style_id": style_id,
		"outcome": outcome,
		"day": completed_day,
		"resume_policy": &"review",
	})
	snapshot_changed.emit(snapshot())
	return true


func _resolve_flock_restructuring(option_id: StringName) -> bool:
	if (
		shift_phase != ShiftPhase.REVIEW
		or flock_restructuring_resolved
		or StringName(pending_decision.get("id", &"")) != &"flock_restructuring"
	):
		return false
	var chosen: Dictionary = {}
	for option_value in pending_decision.get("options", []):
		var option := option_value as Dictionary
		if StringName(option.get("id", &"")) == option_id:
			chosen = option
			break
	if chosen.is_empty():
		return false
	var candidate_id := int(pending_decision.get("subject_worker_id", -1))
	if candidate_id < 0 or candidate_id >= workers.size() or not workers[candidate_id].employed:
		announcement_posted.emit("RESTRUCTURING HELD: the named hen is no longer on the active roster.")
		return false
	var cost_cents := int(chosen.get("cost_cents", 0))
	if spendable_fund_cents() < cost_cents:
		announcement_posted.emit(
			"RESTRUCTURING HELD: $%.2f more spendable Feed Fund required." % (
				float(cost_cents - spendable_fund_cents()) / 100.0
			)
		)
		return false

	var candidate := workers[candidate_id]
	var candidate_before := {
		"career_title": candidate.career_title(),
		"career_xp": candidate.career_xp,
		"specialty": String(candidate.specialty),
		"assignment": String(candidate.assigned_lane),
		"manager_trust": candidate.manager_trust,
		"grievance": candidate.grievance,
		"morale": candidate.morale,
		"stress": candidate.stress,
		"fatigue": candidate.fatigue,
	}
	var candidate_row := _ranked_worker_row(
		pending_decision.get("ranking", []) as Array,
		candidate_id,
	)
	revenue_cents -= cost_cents
	var replacement_worker_id := -1
	match option_id:
		&"nominate_variance":
			replacement_worker_id = _release_restructuring_candidate(candidate)
			revenue_cents += 1800
			executive_confidence = minf(100.0, executive_confidence + 8.0)
			quota_target = mini(10_000, quota_target + 2)
		&"fund_redeployment":
			candidate.assigned_lane = candidate.specialty
			candidate.morale = minf(100.0, candidate.morale + 8.0)
			candidate.manager_trust = minf(100.0, candidate.manager_trust + 14.0)
			candidate.grievance = maxf(0.0, candidate.grievance - 12.0)
			candidate.stress = maxf(0.0, candidate.stress - 10.0)
			candidate.fatigue = maxf(0.0, candidate.fatigue - 10.0)
			candidate.add_career_xp(18)
			executive_confidence = maxf(0.0, executive_confidence - 5.0)
			compliance = minf(100.0, compliance + 4.0)
			quota_target = maxi(1, quota_target - 1)
		&"contest_ranking":
			for worker in workers:
				if not worker.employed:
					continue
				worker.morale = minf(100.0, worker.morale + 4.0)
				worker.manager_trust = minf(100.0, worker.manager_trust + 8.0)
				worker.grievance = maxf(0.0, worker.grievance - 6.0)
			solidarity = minf(100.0, solidarity + 15.0)
			executive_confidence = maxf(0.0, executive_confidence - 10.0)
			compliance = maxf(0.0, compliance - 5.0)
			quota_target = mini(10_000, quota_target + 2)
		_:
			return false

	var style_id := StringName(chosen.get("style_id", &"management_innovation"))
	credit_choice_counts[style_id] = int(credit_choice_counts.get(style_id, 0)) + 1
	var completed_day := int(pending_decision.get("completed_day", FLOCK_RESTRUCTURING_SHIFT))
	var outcome := String(chosen.get("outcome", "Flock restructuring order filed."))
	var serial := int(pending_decision.get("serial", -1))
	var candidate_name := candidate.display_name
	last_credit_allocation = {
		"day": completed_day,
		"decision_id": "flock_restructuring",
		"option_id": String(option_id),
		"style_id": String(style_id),
		"worker_id": candidate_id,
		"worker_name": candidate_name,
		"cost_cents": cost_cents,
		"outcome": outcome,
		"special_event": true,
		"projected": false,
	}
	flock_restructuring_record = last_credit_allocation.duplicate(true)
	flock_restructuring_record.merge({
		"choice_label": String(chosen.get("label", "RESTRUCTURING FILED")),
		"candidate_rank": int(candidate_row.get("rank", 0)),
		"candidate_eggs": int(candidate_row.get("eggs", 0)),
		"candidate_cracked": int(candidate_row.get("cracked", 0)),
		"candidate_credit_cents": int(candidate_row.get("credit_cents", 0)),
		"candidate_before": candidate_before,
		"candidate_employed_after": candidate.employed,
		"replacement_worker_id": replacement_worker_id,
		"replacement_worker_name": (
			workers[replacement_worker_id].display_name
			if replacement_worker_id >= 0 else ""
		),
	}, true)
	flock_restructuring_resolved = true
	flock_restructuring_day = completed_day
	pending_decision.clear()
	announcement_posted.emit(outcome)
	decision_resolved.emit({
		"serial": serial,
		"kind": &"major_event",
		"decision_id": &"flock_restructuring",
		"option_id": option_id,
		"style_id": style_id,
		"worker_id": candidate_id,
		"worker_name": candidate_name,
		"outcome": outcome,
		"day": completed_day,
		"resume_policy": &"review",
	})
	snapshot_changed.emit(snapshot())
	return true


func _ranked_worker_row(ranking: Array, worker_id: int) -> Dictionary:
	for row_value in ranking:
		var row := row_value as Dictionary
		if int(row.get("worker_id", -1)) == worker_id:
			return row.duplicate(true)
	return {}


func _release_restructuring_candidate(candidate: ChickenState) -> int:
	var released_desk := candidate.desk_index
	candidate.employed = false
	candidate.desk_index = -1
	candidate.available_for_hire_day = mini(10_000, day + 2)
	candidate.employment_start_day = 0
	candidate.assigned_lane = AUTO_ASSIGNMENT
	candidate.current_claim = null
	candidate.work_state = ChickenState.WorkState.IDLE
	candidate.work_progress = 0.0
	candidate.state_ticks_remaining = 0
	_worker_at_workstation[candidate.id] = false
	for remaining_worker in workers:
		if not remaining_worker.employed:
			continue
		remaining_worker.morale = maxf(0.0, remaining_worker.morale - 7.0)
		remaining_worker.manager_trust = maxf(0.0, remaining_worker.manager_trust - 10.0)
		remaining_worker.grievance = minf(100.0, remaining_worker.grievance + 12.0)
	solidarity = minf(100.0, solidarity + 10.0)
	if active_worker_count() >= MINIMUM_STAFF_COUNT:
		return -1
	var replacement := _restructuring_replacement_candidate(candidate.id)
	if replacement == null:
		# This cannot occur with the six-hen roster, but fail closed into a retained
		# minimum rather than letting a malformed save strand the office at two.
		candidate.employed = true
		candidate.desk_index = released_desk
		candidate.available_for_hire_day = 0
		candidate.employment_start_day = day
		return -1
	replacement.employed = true
	replacement.desk_index = released_desk
	replacement.available_for_hire_day = 0
	replacement.hire_count += 1
	replacement.employment_start_day = day
	replacement.assigned_lane = AUTO_ASSIGNMENT
	replacement.current_claim = null
	replacement.work_state = ChickenState.WorkState.IDLE
	replacement.work_progress = 0.0
	replacement.state_ticks_remaining = 0
	replacement.morale = minf(100.0, replacement.morale + 3.0)
	_worker_at_workstation[replacement.id] = false
	return replacement.id


func _restructuring_replacement_candidate(excluded_worker_id: int) -> ChickenState:
	var fallback: ChickenState = null
	for worker in workers:
		if worker.employed or worker.id == excluded_worker_id:
			continue
		if fallback == null:
			fallback = worker
		if worker.available_for_hire_day <= day:
			return worker
	return fallback


func _apply_credit_allocation_effects(
	option_id: StringName,
	subject_worker_id: int,
	ranked_worker_ids: Array[int],
) -> void:
	var subject: ChickenState = (
		workers[subject_worker_id]
		if subject_worker_id >= 0 and subject_worker_id < workers.size() else null
	)
	match option_id:
		&"reward_top_layer":
			if subject != null:
				subject.morale = minf(100.0, subject.morale + 4.0)
				subject.manager_trust = minf(100.0, subject.manager_trust + 4.0)
				subject.add_career_xp(3)
			for worker_id in ranked_worker_ids:
				if worker_id != subject_worker_id:
					workers[worker_id].grievance = minf(100.0, workers[worker_id].grievance + 1.0)
		&"share_feed_credit":
			for worker_id in ranked_worker_ids:
				var worker := workers[worker_id]
				worker.morale = minf(100.0, worker.morale + 4.0)
				worker.manager_trust = minf(100.0, worker.manager_trust + 3.0)
				worker.grievance = maxf(0.0, worker.grievance - 2.0)
			solidarity = minf(100.0, solidarity + 4.0)
			executive_confidence = maxf(0.0, executive_confidence - 2.0)
		&"claim_management_innovation":
			revenue_cents += 800
			executive_confidence = minf(100.0, executive_confidence + 5.0)
			quota_target = mini(10_000, quota_target + 1)
			for worker_id in ranked_worker_ids:
				var worker := workers[worker_id]
				worker.manager_trust = maxf(0.0, worker.manager_trust - 3.0)
				worker.grievance = minf(100.0, worker.grievance + 4.0)
			solidarity = maxf(0.0, solidarity - 3.0)
		&"name_the_layer":
			if subject != null:
				subject.morale = minf(100.0, subject.morale + 10.0)
				subject.manager_trust = minf(100.0, subject.manager_trust + 12.0)
				subject.grievance = maxf(0.0, subject.grievance - 8.0)
				subject.add_career_xp(12)
			executive_confidence = maxf(0.0, executive_confidence - 3.0)
		&"flock_owned_patent":
			for worker_id in ranked_worker_ids:
				var worker := workers[worker_id]
				worker.morale = minf(100.0, worker.morale + 5.0)
				worker.manager_trust = minf(100.0, worker.manager_trust + 4.0)
				worker.grievance = maxf(0.0, worker.grievance - 4.0)
			solidarity = minf(100.0, solidarity + 10.0)
			executive_confidence = maxf(0.0, executive_confidence - 5.0)
			quota_target = mini(10_000, quota_target + 1)
		&"patent_rooster_method":
			revenue_cents += 1500
			executive_confidence = minf(100.0, executive_confidence + 9.0)
			quota_target = mini(10_000, quota_target + 2)
			for worker_id in ranked_worker_ids:
				var worker := workers[worker_id]
				if worker_id == subject_worker_id:
					worker.manager_trust = maxf(0.0, worker.manager_trust - 14.0)
					worker.grievance = minf(100.0, worker.grievance + 14.0)
				else:
					worker.manager_trust = maxf(0.0, worker.manager_trust - 4.0)
					worker.grievance = minf(100.0, worker.grievance + 4.0)


func current_daily_feed_cost_cents() -> int:
	var legacy_adjustment := feed_cents_per_day - LEGACY_FULL_ROSTER_FEED_CENTS
	return maxi(
		BASE_FEED_COST_CENTS,
		BASE_FEED_COST_CENTS
		+ FEED_COST_PER_ACTIVE_HEN_CENTS * active_worker_count()
		+ legacy_adjustment
		+ _daily_feed_adjustment_cents
		+ _incident_feed_adjustment_cents
	)


func phase_label() -> String:
	match shift_phase:
		ShiftPhase.AWAITING_DIRECTIVE:
			return "AWAITING DIRECTIVE"
		ShiftPhase.RUNNING:
			return "RUNNING"
		ShiftPhase.AWAITING_INCIDENT:
			return "AWAITING INCIDENT"
		ShiftPhase.REVIEW:
			return "REVIEW"
	return "UNKNOWN"


func _prepare_morning_directive() -> void:
	_decision_serial += 1
	shift_phase = ShiftPhase.AWAITING_DIRECTIVE
	var options: Array[Dictionary] = []
	for directive in directive_catalog():
		options.append({
			"id": directive["id"],
			"label": directive["name"],
			"tagline": directive["tagline"],
			"preview": directive["preview"],
			"cost_cents": 0,
			"tone": directive["tone"],
		})
	pending_decision = {
		"serial": _decision_serial,
		"kind": &"directive",
		"id": &"morning_directive",
		"day": day,
		"eyebrow": "MORNING DIRECTIVE  ·  DAY %d" % day,
		"title": "CHOOSE TODAY'S MANAGEMENT POLICY",
		"body": "One policy governs the entire shift. Its benefits and liabilities are both real, even if only one appears in the farmer's presentation.",
		"options": options,
	}


func _resolve_directive(directive_id: StringName) -> bool:
	if shift_phase != ShiftPhase.AWAITING_DIRECTIVE or not DIRECTIVE_DEFINITIONS.has(directive_id):
		return false
	var definition: Dictionary = DIRECTIVE_DEFINITIONS[directive_id]
	active_directive_id = directive_id
	_directive_work_multiplier = float(definition.get("work_multiplier", 1.0))
	_directive_fatigue_multiplier = float(definition.get("fatigue_multiplier", 1.0))
	_directive_stress_multiplier = float(definition.get("stress_multiplier", 1.0))
	_directive_morale_drain_multiplier = float(definition.get("morale_drain_multiplier", 1.0))
	_directive_crack_modifier = float(definition.get("crack_modifier", 0.0))
	_daily_feed_adjustment_cents = int(definition.get("feed_delta_cents", 0))
	compliance = clampf(compliance + float(definition.get("compliance_delta", 0.0)), 0.0, 100.0)
	var worker_stress_delta := float(definition.get("worker_stress_delta", 0.0))
	if not is_zero_approx(worker_stress_delta):
		_adjust_workers(0.0, worker_stress_delta, 0.0)
	match directive_id:
		&"record_harvest":
			_adjust_worker_relationships(-2.0, 3.0)
		&"shell_assurance":
			_adjust_worker_relationships(1.0, -1.0)
		&"sustainable_flock":
			_adjust_worker_relationships(3.0, -3.0)
	var decision_id := StringName(pending_decision.get("id", &"morning_directive"))
	pending_decision.clear()
	shift_phase = ShiftPhase.RUNNING
	shift_phase_changed.emit(shift_phase)
	var outcome := String(definition.get("outcome", "Directive authorized."))
	announcement_posted.emit(outcome)
	decision_resolved.emit({
		"serial": _decision_serial,
		"kind": &"directive",
		"decision_id": decision_id,
		"option_id": directive_id,
		"outcome": outcome,
		"day": day,
	})
	snapshot_changed.emit(snapshot())
	return true


func _maybe_open_incident() -> bool:
	if _incident_slot >= INCIDENT_MINUTES.size():
		return false
	if minute_of_day < INCIDENT_MINUTES[_incident_slot]:
		return false
	_decision_serial += 1
	var petition_decision: Dictionary = {}
	if day in FLOCK_PETITION_DAYS and _incident_slot == FLOCK_PETITION_INCIDENT_SLOT:
		petition_decision = _build_flock_petition_decision()
	if not petition_decision.is_empty():
		petition_decision["serial"] = _decision_serial
		pending_decision = petition_decision
	else:
		# Preserve the original structural incident as a deterministic fallback.
		var rotation_index := ((day - 1) * INCIDENT_MINUTES.size() + _incident_slot) % INCIDENT_ORDER.size()
		var incident_id := INCIDENT_ORDER[rotation_index]
		var definition: Dictionary = INCIDENT_DEFINITIONS[incident_id]
		var options: Array[Dictionary] = []
		for choice_value in definition.get("choices", []):
			options.append((choice_value as Dictionary).duplicate(true))
		pending_decision = {
			"serial": _decision_serial,
			"kind": &"incident",
			"id": incident_id,
			"day": day,
			"eyebrow": "INCIDENT  ·  AUTO-PAUSED  ·  %s" % _format_time(minute_of_day),
			"title": String(definition.get("title", "OFFICE INCIDENT")),
			"body": String(definition.get("body", "A measurable variance requires management attention.")),
			"options": options,
		}
	_incident_slot += 1
	shift_phase = ShiftPhase.AWAITING_INCIDENT
	shift_phase_changed.emit(shift_phase)
	decision_requested.emit(pending_decision_snapshot())
	return true


func _resolve_incident(option_id: StringName) -> bool:
	if shift_phase != ShiftPhase.AWAITING_INCIDENT:
		return false
	var incident_id := StringName(pending_decision.get("id", &""))
	var is_flock_petition := incident_id == FLOCK_PETITION_INCIDENT_ID
	if not INCIDENT_DEFINITIONS.has(incident_id) and not is_flock_petition:
		return false
	var chosen: Dictionary = {}
	for option_value in pending_decision.get("options", []):
		var option := option_value as Dictionary
		if StringName(option.get("id", &"")) == option_id:
			chosen = option
			break
	if chosen.is_empty():
		return false
	if is_flock_petition and not _can_apply_flock_petition_response(option_id, chosen):
		return false
	var cost_cents := int(chosen.get("cost_cents", 0))
	var spendable := spendable_fund_cents()
	if spendable < cost_cents:
		announcement_posted.emit(
			"RESPONSE DENIED: $%.2f more spendable Feed Fund required." % (
				float(cost_cents - spendable) / 100.0
			)
		)
		return false
	revenue_cents -= cost_cents
	var petition_record: Dictionary = {}
	if is_flock_petition:
		petition_record = _apply_flock_petition_response(option_id, chosen)
	else:
		_apply_incident_effects(incident_id, option_id)
	incidents_resolved_today += 1
	var outcome := String(chosen.get("outcome", "Incident response recorded."))
	var serial := int(pending_decision.get("serial", -1))
	pending_decision.clear()
	shift_phase = ShiftPhase.RUNNING
	shift_phase_changed.emit(shift_phase)
	announcement_posted.emit(outcome)
	var result := {
		"serial": serial,
		"kind": &"incident",
		"decision_id": incident_id,
		"option_id": option_id,
		"outcome": outcome,
		"day": day,
	}
	if is_flock_petition:
		result["category"] = FLOCK_PETITION_CATEGORY
		result["flock_petition"] = petition_record.duplicate(true)
		result["flock_compact"] = active_flock_compact.duplicate(true)
		result["work_to_rule"] = work_to_rule_snapshot()
	decision_resolved.emit(result)
	snapshot_changed.emit(snapshot())
	return true


func _build_flock_petition_decision() -> Dictionary:
	if not active_flock_compact.is_empty():
		return {}
	var candidates: Array[Dictionary] = []
	for worker in workers:
		if not worker.employed:
			continue
		if worker.assigned_lane != AUTO_ASSIGNMENT and worker.assigned_lane != worker.specialty:
			candidates.append({
				"petition_type": &"specialty_respect",
				"worker_id": worker.id,
				"score": 600 + roundi(worker.grievance * 4.0 + worker.stress + worker.fatigue),
				"evidence": [
					"Assigned file: %s" % _lane_display_name(worker.assigned_lane),
					"Trained file: %s" % _lane_display_name(worker.specialty),
					"Grievance ledger: %d" % roundi(worker.grievance),
				],
			})
		var pace_pressure := (
			worker.stress >= 45.0
			or worker.fatigue >= 55.0
			or overtime_enabled
			or (
				worker.last_personnel_action_day == day
				and worker.last_personnel_action == &"quota_pressure"
			)
		)
		if pace_pressure:
			var pace_score := 400 + roundi(worker.stress * 3.0 + worker.fatigue * 2.0)
			if overtime_enabled:
				pace_score += 100
			if worker.last_personnel_action_day == day and worker.last_personnel_action == &"quota_pressure":
				pace_score += 120
			candidates.append({
				"petition_type": &"safe_pace",
				"worker_id": worker.id,
				"score": pace_score,
				"evidence": [
					"Stress reading: %d" % roundi(worker.stress),
					"Fatigue reading: %d" % roundi(worker.fatigue),
					"Overtime order: %s" % ("ACTIVE" if overtime_enabled else "INACTIVE"),
				],
			})
		if (
			worker.career_profile == &"credit_conscious"
			and not last_credit_allocation.is_empty()
			and int(last_credit_allocation.get("day", 0)) >= 1
			and int(last_credit_allocation.get("day", 0)) < day
		):
			var allocation_style := StringName(last_credit_allocation.get("style_id", &""))
			var credit_score := 200 + roundi(worker.grievance * 2.0)
			if allocation_style == &"management_innovation":
				credit_score += 140
			if int(last_credit_allocation.get("worker_id", -1)) == worker.id:
				credit_score += 60
			candidates.append({
				"petition_type": &"credit_in_writing",
				"worker_id": worker.id,
				"score": credit_score,
				"evidence": [
					"Last credit memo: %s" % String(allocation_style).replace("_", " ").to_upper(),
					"Career profile: CREDIT CONSCIOUS",
					"Grievance ledger: %d" % roundi(worker.grievance),
				],
			})
	if candidates.is_empty():
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := int(a.get("score", 0))
		var score_b := int(b.get("score", 0))
		if score_a != score_b:
			return score_a > score_b
		var type_a := StringName(a.get("petition_type", &""))
		var type_b := StringName(b.get("petition_type", &""))
		var priority_a := int((FLOCK_PETITION_DEFINITIONS.get(type_a, {}) as Dictionary).get("priority", 0))
		var priority_b := int((FLOCK_PETITION_DEFINITIONS.get(type_b, {}) as Dictionary).get("priority", 0))
		if priority_a != priority_b:
			return priority_a > priority_b
		return int(a.get("worker_id", 9999)) < int(b.get("worker_id", 9999))
	)
	var candidate := candidates[0]
	var petition_type := StringName(candidate.get("petition_type", &""))
	var definition := FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	var sponsor := workers[int(candidate.get("worker_id", -1))]
	var effective_day := mini(9999, day + 1)
	var evidence := (candidate.get("evidence", []) as Array).duplicate(true)
	var petition := {
		"version": 1,
		"petition_type": petition_type,
		"petition_title": String(definition.get("title", "FLOCK PETITION")),
		"compact_name": String(definition.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"sponsor_profile": String(sponsor.career_profile),
		"evidence": evidence,
		"evidence_summary": String(evidence[0]) if not evidence.is_empty() else "Filed from the active flock ledger.",
		"promise": String(definition.get("promise", "")),
		"condition": String(definition.get("condition", "")),
		"effective_day": effective_day,
		"solidarity": snappedf(solidarity, 0.0001),
		"work_to_rule_threshold": WORK_TO_RULE_SOLIDARITY_THRESHOLD,
	}
	return {
		"serial": -1,
		"kind": &"incident",
		"category": FLOCK_PETITION_CATEGORY,
		"id": FLOCK_PETITION_INCIDENT_ID,
		"day": day,
		"eyebrow": "FLOCK PETITION  ·  AUTO-PAUSED  ·  %s" % _format_time(minute_of_day),
		"title": String(definition.get("title", "FLOCK PETITION")),
		"body": "%s has put her name on a collective request. Its evidence comes from the same ledger used for performance reviews." % sponsor.display_name,
		"petition_type": petition_type,
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"evidence": evidence,
		"petition": petition,
		"options": [
			{
				"id": &"sign_compact",
				"response_tier": &"binding",
				"label": "SIGN THE COMPACT",
				"tagline": "Put tomorrow's promise in writing.",
				"preview": "$%.2f  /  binding next shift  /  breach has consequences" % (float(definition.get("sign_cost_cents", 0)) / 100.0),
				"cost_cents": int(definition.get("sign_cost_cents", 0)),
				"tone": &"care",
				"outcome": "%s's compact was signed. Tomorrow's rooster is accountable to the wording." % sponsor.display_name,
			},
			{
				"id": &"offer_concession",
				"response_tier": &"concession",
				"label": "OFFER A SCOOP OF FEED",
				"tagline": "Address today's strain without signing tomorrow away.",
				"preview": "$4.00  /  immediate relief  /  no binding compact",
				"cost_cents": 400,
				"tone": &"quality",
				"outcome": "%s accepted a small concession. The petition remains in the filing cabinet, not the contract drawer." % sponsor.display_name,
			},
			{
				"id": &"deny_and_monitor",
				"response_tier": &"denial",
				"label": "DENY AND MONITOR",
				"tagline": "Call the pattern anecdotal and measure the reaction.",
				"preview": "FREE  /  trust falls  /  solidarity may trigger work-to-rule",
				"cost_cents": 0,
				"tone": &"danger",
				"outcome": "Management denied %s's petition and opened a dashboard to monitor the resulting solidarity." % sponsor.display_name,
			},
		],
	}


func _can_apply_flock_petition_response(option_id: StringName, chosen: Dictionary) -> bool:
	if option_id not in FLOCK_PETITION_RESPONSE_IDS or int(pending_decision.get("day", 0)) != day:
		return false
	var petition_type := StringName(pending_decision.get("petition_type", &""))
	if petition_type not in FLOCK_PETITION_TYPES:
		return false
	var sponsor_id := int(pending_decision.get("sponsor_worker_id", -1))
	if sponsor_id < 0 or sponsor_id >= workers.size() or not workers[sponsor_id].employed:
		return false
	if String(pending_decision.get("sponsor_worker_name", "")) != workers[sponsor_id].display_name:
		return false
	var expected_cost := 0
	match option_id:
		&"sign_compact":
			if not active_flock_compact.is_empty():
				return false
			expected_cost = int((FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary).get("sign_cost_cents", -1))
		&"offer_concession":
			expected_cost = 400
		&"deny_and_monitor":
			expected_cost = 0
	return int(chosen.get("cost_cents", -1)) == expected_cost


func _apply_flock_petition_response(option_id: StringName, chosen: Dictionary) -> Dictionary:
	var petition_type := StringName(pending_decision.get("petition_type", &""))
	var sponsor_id := int(pending_decision.get("sponsor_worker_id", -1))
	var sponsor := workers[sponsor_id]
	var solidarity_before := solidarity
	var compact_scheduled := false
	var work_to_rule_scheduled := false
	match option_id:
		&"sign_compact":
			sponsor.manager_trust = minf(100.0, sponsor.manager_trust + 6.0)
			sponsor.grievance = maxf(0.0, sponsor.grievance - 8.0)
			sponsor.morale = minf(100.0, sponsor.morale + 3.0)
			solidarity = minf(100.0, solidarity + 5.0)
			executive_confidence = maxf(0.0, executive_confidence - 2.0)
			active_flock_compact = _new_flock_compact(petition_type, sponsor)
			compact_scheduled = true
		&"offer_concession":
			_adjust_worker_relationships(1.0, -1.0)
			sponsor.manager_trust = minf(100.0, sponsor.manager_trust + 2.0)
			sponsor.grievance = maxf(0.0, sponsor.grievance - 3.0)
			sponsor.morale = minf(100.0, sponsor.morale + 2.0)
			sponsor.stress = maxf(0.0, sponsor.stress - 4.0)
			sponsor.fatigue = maxf(0.0, sponsor.fatigue - 2.0)
			solidarity = minf(100.0, solidarity + 2.0)
			executive_confidence = maxf(0.0, executive_confidence - 1.0)
		&"deny_and_monitor":
			_adjust_worker_relationships(-4.0, 8.0)
			sponsor.manager_trust = maxf(0.0, sponsor.manager_trust - 8.0)
			sponsor.grievance = minf(100.0, sponsor.grievance + 8.0)
			sponsor.morale = maxf(0.0, sponsor.morale - 5.0)
			sponsor.stress = minf(100.0, sponsor.stress + 5.0)
			solidarity = minf(100.0, solidarity + 14.0)
			executive_confidence = minf(100.0, executive_confidence + 4.0)
			if solidarity >= WORK_TO_RULE_SOLIDARITY_THRESHOLD:
				work_to_rule_scheduled = _schedule_work_to_rule(
					&"petition_denied", sponsor.id, sponsor.display_name, day, mini(9999, day + 1)
				)
	var record := {
		"version": 1,
		"day": day,
		"petition_type": String(petition_type),
		"petition_title": String(pending_decision.get("title", "FLOCK PETITION")),
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"evidence": (pending_decision.get("evidence", []) as Array).duplicate(true),
		"response_id": String(option_id),
		"response_tier": String(chosen.get("response_tier", "")),
		"cost_cents": int(chosen.get("cost_cents", 0)),
		"outcome": String(chosen.get("outcome", "Petition response recorded.")),
		"effective_day": mini(9999, day + 1),
		"compact_scheduled": compact_scheduled,
		"work_to_rule_scheduled": work_to_rule_scheduled,
		"solidarity_before": snappedf(solidarity_before, 0.0001),
		"solidarity_after": snappedf(solidarity, 0.0001),
	}
	last_flock_petition = record.duplicate(true)
	flock_petition_history.append(record.duplicate(true))
	while flock_petition_history.size() > FLOCK_PETITION_HISTORY_LIMIT:
		flock_petition_history.pop_front()
	return record


func _new_flock_compact(petition_type: StringName, sponsor: ChickenState) -> Dictionary:
	var definition := FLOCK_PETITION_DEFINITIONS[petition_type] as Dictionary
	return {
		"version": 1,
		"compact_id": "D%d-%s-%d" % [day, String(petition_type), sponsor.id],
		"petition_day": day,
		"effective_day": mini(9999, day + 1),
		"status": "scheduled",
		"petition_type": String(petition_type),
		"compact_name": String(definition.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor.id,
		"sponsor_worker_name": sponsor.display_name,
		"promise": String(definition.get("promise", "")),
		"condition": String(definition.get("condition", "")),
	}


func _schedule_work_to_rule(
	trigger: StringName,
	sponsor_id: int,
	sponsor_name: String,
	petition_day: int,
	effective_day: int,
) -> bool:
	if effective_day < day or effective_day > 9999:
		return false
	var record := {
		"version": 1,
		"trigger": String(trigger),
		"petition_day": petition_day,
		"effective_day": effective_day,
		"status": "active" if effective_day == day else "scheduled",
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": sponsor_name,
		"work_multiplier": WORK_TO_RULE_WORK_MULTIPLIER,
		"crack_modifier": WORK_TO_RULE_CRACK_MODIFIER,
		"outcome": "The flock is following every written procedure, including the slow ones.",
	}
	if work_to_rule_day == 0:
		work_to_rule_day = effective_day
		last_work_to_rule_record = record
		return true
	if work_to_rule_day == effective_day:
		return true
	if work_to_rule_day == day and effective_day > day and queued_work_to_rule_day == 0:
		queued_work_to_rule_day = effective_day
		queued_work_to_rule_record = record
		return true
	if queued_work_to_rule_day == effective_day:
		return true
	return false


func _is_work_to_rule_active() -> bool:
	return work_to_rule_day == day


func _work_to_rule_work_multiplier() -> float:
	return WORK_TO_RULE_WORK_MULTIPLIER if _is_work_to_rule_active() else 1.0


func _work_to_rule_crack_modifier() -> float:
	return WORK_TO_RULE_CRACK_MODIFIER if _is_work_to_rule_active() else 0.0


func work_to_rule_snapshot() -> Dictionary:
	return {
		"active": _is_work_to_rule_active(),
		"scheduled": work_to_rule_day > day,
		"day": work_to_rule_day,
		"queued_day": queued_work_to_rule_day,
		"threshold": WORK_TO_RULE_SOLIDARITY_THRESHOLD,
		"work_multiplier": _work_to_rule_work_multiplier(),
		"crack_modifier": _work_to_rule_crack_modifier(),
		"record": last_work_to_rule_record.duplicate(true),
		"queued_record": queued_work_to_rule_record.duplicate(true),
	}


func _activate_next_shift_flock_state() -> void:
	if (
		not active_flock_compact.is_empty()
		and StringName(active_flock_compact.get("status", &"")) == &"scheduled"
		and int(active_flock_compact.get("effective_day", 0)) == day
	):
		active_flock_compact["status"] = "active"
		if StringName(active_flock_compact.get("petition_type", &"")) == &"specialty_respect":
			var sponsor_id := int(active_flock_compact.get("sponsor_worker_id", -1))
			if sponsor_id >= 0 and sponsor_id < workers.size() and workers[sponsor_id].employed:
				workers[sponsor_id].assigned_lane = workers[sponsor_id].specialty
	if work_to_rule_day == day and not last_work_to_rule_record.is_empty():
		last_work_to_rule_record["status"] = "active"
	if work_to_rule_day == 0 and queued_work_to_rule_day == day:
		work_to_rule_day = queued_work_to_rule_day
		last_work_to_rule_record = queued_work_to_rule_record.duplicate(true)
		last_work_to_rule_record["status"] = "active"
		queued_work_to_rule_day = 0
		queued_work_to_rule_record.clear()


func _finish_work_to_rule_day(completed_day: int) -> Dictionary:
	if work_to_rule_day != completed_day:
		return {}
	var completed := work_to_rule_snapshot()
	completed["completed"] = true
	if not last_work_to_rule_record.is_empty():
		last_work_to_rule_record["status"] = "completed"
		last_work_to_rule_record["completed_day"] = completed_day
	work_to_rule_day = 0
	return completed


func _breach_compact_for_sponsor_release(worker_id: int) -> bool:
	if active_flock_compact.is_empty():
		return false
	if int(active_flock_compact.get("sponsor_worker_id", -1)) != worker_id:
		return false
	return _breach_flock_compact(&"sponsor_released")


func _breach_specialty_compact_for_assignment(worker: ChickenState) -> bool:
	if active_flock_compact.is_empty():
		return false
	if StringName(active_flock_compact.get("status", &"")) != &"active":
		return false
	if StringName(active_flock_compact.get("petition_type", &"")) != &"specialty_respect":
		return false
	if int(active_flock_compact.get("sponsor_worker_id", -1)) != worker.id:
		return false
	if worker.assigned_lane == worker.specialty:
		return false
	return _breach_flock_compact(&"specialty_assignment_changed")


func _breach_safe_pace_compact(reason: StringName) -> bool:
	if active_flock_compact.is_empty():
		return false
	if StringName(active_flock_compact.get("status", &"")) != &"active":
		return false
	if StringName(active_flock_compact.get("petition_type", &"")) != &"safe_pace":
		return false
	return _breach_flock_compact(reason)


func _breach_flock_compact(reason: StringName) -> bool:
	if active_flock_compact.is_empty():
		return false
	if StringName(active_flock_compact.get("status", &"")) not in [&"scheduled", &"active"]:
		return false
	var compact := active_flock_compact.duplicate(true)
	var sponsor_id := int(compact.get("sponsor_worker_id", -1))
	_adjust_worker_relationships(-3.0, 6.0)
	if sponsor_id >= 0 and sponsor_id < workers.size():
		var sponsor := workers[sponsor_id]
		sponsor.manager_trust = maxf(0.0, sponsor.manager_trust - 9.0)
		sponsor.grievance = minf(100.0, sponsor.grievance + 12.0)
		sponsor.morale = maxf(0.0, sponsor.morale - 6.0)
	solidarity = minf(100.0, solidarity + 16.0)
	compliance = maxf(0.0, compliance - 4.0)
	executive_confidence = maxf(0.0, executive_confidence - 3.0)
	var schedule_day := day if shift_phase in [ShiftPhase.REVIEW, ShiftPhase.AWAITING_DIRECTIVE] else mini(9999, day + 1)
	var work_scheduled := false
	if solidarity >= WORK_TO_RULE_SOLIDARITY_THRESHOLD:
		work_scheduled = _schedule_work_to_rule(
			&"compact_breached",
			sponsor_id,
			String(compact.get("sponsor_worker_name", "")),
			int(compact.get("petition_day", day)),
			schedule_day,
		)
	last_flock_compact_receipt = {
		"version": 1,
		"compact_id": String(compact.get("compact_id", "")),
		"petition_day": int(compact.get("petition_day", 0)),
		"effective_day": int(compact.get("effective_day", 0)),
		"resolved_day": day,
		"status": "breached",
		"petition_type": String(compact.get("petition_type", "")),
		"compact_name": String(compact.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": String(compact.get("sponsor_worker_name", "")),
		"promise": String(compact.get("promise", "")),
		"condition": String(compact.get("condition", "")),
		"reason": String(reason),
		"work_to_rule_scheduled": work_scheduled,
		"outcome": "%s was breached. The flock has entered the consequence in its own ledger." % String(compact.get("compact_name", "Flock compact")),
	}
	active_flock_compact.clear()
	announcement_posted.emit(String(last_flock_compact_receipt.get("outcome", "Compact breached.")))
	return true


func _resolve_due_flock_compact(completed_day: int) -> Dictionary:
	if active_flock_compact.is_empty():
		return {}
	if (
		StringName(active_flock_compact.get("status", &"")) != &"active"
		or int(active_flock_compact.get("effective_day", 0)) != completed_day
	):
		return {}
	var petition_type := StringName(active_flock_compact.get("petition_type", &""))
	var sponsor_id := int(active_flock_compact.get("sponsor_worker_id", -1))
	var fulfilled := sponsor_id >= 0 and sponsor_id < workers.size() and workers[sponsor_id].employed
	var breach_reason: StringName = &"sponsor_unavailable"
	if fulfilled:
		var sponsor := workers[sponsor_id]
		match petition_type:
			&"specialty_respect":
				fulfilled = sponsor.assigned_lane == sponsor.specialty
				breach_reason = &"specialty_assignment_changed"
			&"safe_pace":
				fulfilled = not overtime_enabled
				breach_reason = &"overtime_enabled"
			&"credit_in_writing":
				fulfilled = (
					sponsor.last_personnel_action_day == completed_day
					and sponsor.last_personnel_action == &"share_credit"
				)
				breach_reason = &"credit_not_filed"
	if not fulfilled:
		_breach_flock_compact(breach_reason)
		return last_flock_compact_receipt.duplicate(true)
	var compact := active_flock_compact.duplicate(true)
	var sponsor := workers[sponsor_id]
	_adjust_worker_relationships(1.0, -2.0)
	sponsor.manager_trust = minf(100.0, sponsor.manager_trust + 7.0)
	sponsor.grievance = maxf(0.0, sponsor.grievance - 8.0)
	sponsor.morale = minf(100.0, sponsor.morale + 5.0)
	solidarity = minf(100.0, solidarity + 3.0)
	executive_confidence = maxf(0.0, executive_confidence - 2.0)
	last_flock_compact_receipt = {
		"version": 1,
		"compact_id": String(compact.get("compact_id", "")),
		"petition_day": int(compact.get("petition_day", 0)),
		"effective_day": int(compact.get("effective_day", 0)),
		"resolved_day": completed_day,
		"status": "fulfilled",
		"petition_type": String(petition_type),
		"compact_name": String(compact.get("compact_name", "FLOCK COMPACT")),
		"sponsor_worker_id": sponsor_id,
		"sponsor_worker_name": sponsor.display_name,
		"promise": String(compact.get("promise", "")),
		"condition": String(compact.get("condition", "")),
		"reason": "promise_kept",
		"work_to_rule_scheduled": false,
		"outcome": "%s was fulfilled once, on the shift it named." % String(compact.get("compact_name", "Flock compact")),
	}
	active_flock_compact.clear()
	announcement_posted.emit(String(last_flock_compact_receipt.get("outcome", "Compact fulfilled.")))
	return last_flock_compact_receipt.duplicate(true)


func _apply_incident_effects(incident_id: StringName, option_id: StringName) -> void:
	match incident_id:
		&"ledger_molt":
			if option_id == &"patch":
				compliance = minf(100.0, compliance + 4.0)
				_incident_crack_modifier -= 0.04
				_adjust_worker_relationships(1.0, -1.0)
			else:
				_incident_work_multiplier *= 1.05
				_incident_crack_modifier += 0.06
				compliance = maxf(0.0, compliance - 6.0)
				_adjust_worker_relationships(-2.0, 3.0)
		&"wellness_request":
			if option_id == &"grant_breaks":
				_adjust_workers(4.0, -6.0, -5.0)
				_adjust_worker_relationships(3.0, -4.0)
				executive_confidence = maxf(0.0, executive_confidence - 2.0)
				solidarity = minf(100.0, solidarity + 4.0)
			else:
				_adjust_workers(-6.0, 6.0, 0.0)
				_adjust_worker_relationships(-5.0, 6.0)
				executive_confidence = minf(100.0, executive_confidence + 3.0)
				solidarity = minf(100.0, solidarity + 5.0)
				_incident_crack_modifier += 0.025
		&"farmer_story":
			if option_id == &"polish_story":
				_adjust_worker_relationships(-4.0, 5.0)
				revenue_cents += 1600
				credited_today_cents += 1600
				executive_confidence = minf(100.0, executive_confidence + 8.0)
				solidarity = maxf(0.0, solidarity - 5.0)
				_pending_quota_adjustment += 1
			else:
				_adjust_worker_relationships(4.0, -3.0)
				executive_confidence = maxf(0.0, executive_confidence - 6.0)
				compliance = minf(100.0, compliance + 5.0)
				solidarity = minf(100.0, solidarity + 6.0)
				_pending_quota_adjustment -= 1
				_incident_golden_modifier += 0.012
		&"feed_shortfall":
			if option_id == &"buy_grain":
				_adjust_workers(6.0, -4.0, 0.0)
				_adjust_worker_relationships(2.0, -2.0)
				solidarity = minf(100.0, solidarity + 3.0)
				_incident_strain_multiplier *= 0.85
			else:
				_incident_feed_adjustment_cents -= 800
				_adjust_workers(-7.0, 5.0, 0.0)
				_adjust_worker_relationships(-3.0, 4.0)
				_incident_work_multiplier *= 0.96
				_incident_crack_modifier += 0.03


func _adjust_workers(morale_delta: float, stress_delta: float, fatigue_delta: float) -> void:
	for worker in workers:
		if not worker.employed:
			continue
		worker.morale = clampf(worker.morale + morale_delta, 0.0, 100.0)
		worker.stress = clampf(worker.stress + stress_delta, 0.0, 100.0)
		worker.fatigue = clampf(worker.fatigue + fatigue_delta, 0.0, 100.0)


func _adjust_worker_relationships(trust_delta: float, grievance_delta: float) -> void:
	for worker in workers:
		if not worker.employed:
			continue
		worker.manager_trust = clampf(worker.manager_trust + trust_delta, 0.0, 100.0)
		worker.grievance = clampf(worker.grievance + grievance_delta, 0.0, 100.0)


func _reset_daily_decision_state() -> void:
	active_directive_id = &""
	pending_decision.clear()
	incidents_resolved_today = 0
	peck_assists_used_today = 0
	peck_assist_interventions_today = 0
	peck_assist_refunds_today = 0
	peck_assist_streak = 0
	last_peck_assist.clear()
	last_peck_assist_delivery.clear()
	priority_credit_today_cents = 0
	_assisted_claim_ids.clear()
	_missed_assist_claim_ids.clear()
	_assist_quality_modifiers.clear()
	_assist_chain_by_claim_id.clear()
	_pending_peck_assist_deliveries.clear()
	_settled_peck_assist_delivery_ids.clear()
	_incident_slot = 0
	_directive_work_multiplier = 1.0
	_directive_fatigue_multiplier = 1.0
	_directive_stress_multiplier = 1.0
	_directive_morale_drain_multiplier = 1.0
	_directive_crack_modifier = 0.0
	_daily_feed_adjustment_cents = 0
	_incident_work_multiplier = 1.0
	_incident_strain_multiplier = 1.0
	_incident_crack_modifier = 0.0
	_incident_golden_modifier = 0.0
	_incident_feed_adjustment_cents = 0
	_pending_quota_adjustment = 0


func _initialize_claim_queues() -> void:
	_claim_queues.clear()
	for lane in CLAIM_LANES:
		var queue: Array[ClaimState] = []
		_claim_queues[lane] = queue


func _current_operational_minute() -> int:
	var shift_length := SHIFT_END_MINUTE - SHIFT_START_MINUTE
	var elapsed_today := clampi(minute_of_day - SHIFT_START_MINUTE, 0, shift_length)
	return (day - 1) * shift_length + elapsed_today


func _operational_minute_for_shift_start(target_day: int) -> int:
	return (maxi(1, target_day) - 1) * (SHIFT_END_MINUTE - SHIFT_START_MINUTE)


func _queued_claim_count() -> int:
	var total := 0
	for lane in CLAIM_LANES:
		total += (_claim_queues.get(lane, []) as Array).size()
	return total


func _active_claim_count() -> int:
	var total := 0
	for worker in workers:
		if not worker.employed:
			continue
		if worker.current_claim != null:
			total += 1
	return total


func _outstanding_claim_count() -> int:
	return _queued_claim_count() + _active_claim_count() + _pending_rework.size()


func _sync_claims_waiting() -> void:
	claims_waiting = _queued_claim_count()


func _enqueue_new_claim(lane: StringName) -> bool:
	if not CLAIM_LANE_DEFINITIONS.has(lane) or _outstanding_claim_count() >= MAX_CLAIM_QUEUE:
		return false
	var definition: Dictionary = CLAIM_LANE_DEFINITIONS[lane]
	var arrival_minute := _current_operational_minute()
	var service_window := int(definition["deadline_minutes"])
	var claim := ClaimState.new(
		_next_claim_id,
		lane,
		String(definition["display_name"]),
		float(definition["base_difficulty"]),
		int(definition["base_value_cents"]),
		float(definition["crack_modifier"]),
		arrival_minute,
		arrival_minute + service_window,
		service_window,
		false,
		-1,
		day,
		0
	)
	_next_claim_id += 1
	_append_claim_to_queue(claim)
	return true


func _append_claim_to_queue(claim: ClaimState) -> void:
	if claim == null or not CLAIM_LANE_DEFINITIONS.has(claim.lane):
		return
	var queue: Array = _claim_queues[claim.lane]
	queue.append(claim)
	_sync_claims_waiting()


func _choose_arrival_lane() -> StringName:
	var roll := _claim_rng.randf()
	var cumulative := 0.0
	for lane in CLAIM_LANES:
		var definition: Dictionary = CLAIM_LANE_DEFINITIONS[lane]
		cumulative += float(definition["arrival_weight"])
		if roll <= cumulative:
			return lane
	return CLAIM_LANES[CLAIM_LANES.size() - 1]


func _earliest_claim_index(lane: StringName) -> int:
	if not CLAIM_LANE_DEFINITIONS.has(lane):
		return -1
	var queue: Array = _claim_queues[lane]
	var earliest_index := -1
	var earliest_deadline := 0
	var earliest_id := 0
	for index in queue.size():
		var claim := queue[index] as ClaimState
		if claim == null:
			continue
		if (
			earliest_index < 0
			or claim.deadline_operational_minute < earliest_deadline
			or (
				claim.deadline_operational_minute == earliest_deadline
				and claim.id < earliest_id
			)
		):
			earliest_index = index
			earliest_deadline = claim.deadline_operational_minute
			earliest_id = claim.id
	return earliest_index


func _claim_at(lane: StringName, index: int) -> ClaimState:
	if not CLAIM_LANE_DEFINITIONS.has(lane):
		return null
	var queue: Array = _claim_queues[lane]
	if index < 0 or index >= queue.size():
		return null
	return queue[index] as ClaimState


func _remove_claim_at(lane: StringName, index: int) -> ClaimState:
	var claim := _claim_at(lane, index)
	if claim == null:
		return null
	var queue: Array = _claim_queues[lane]
	queue.remove_at(index)
	_sync_claims_waiting()
	return claim


func _take_claim_for_worker(worker: ChickenState) -> ClaimState:
	if worker.assigned_lane != AUTO_ASSIGNMENT:
		return _remove_claim_at(worker.assigned_lane, _earliest_claim_index(worker.assigned_lane))

	var urgent_lane: StringName = &""
	var urgent_index := -1
	var urgent_claim: ClaimState
	for lane in CLAIM_LANES:
		var candidate_index := _earliest_claim_index(lane)
		var candidate := _claim_at(lane, candidate_index)
		if candidate == null:
			continue
		if (
			urgent_claim == null
			or candidate.deadline_operational_minute < urgent_claim.deadline_operational_minute
			or (
				candidate.deadline_operational_minute == urgent_claim.deadline_operational_minute
				and candidate.id < urgent_claim.id
			)
		):
			urgent_lane = lane
			urgent_index = candidate_index
			urgent_claim = candidate

	if urgent_claim == null:
		return null
	var specialty_index := _earliest_claim_index(worker.specialty)
	var specialty_claim := _claim_at(worker.specialty, specialty_index)
	if (
		specialty_claim != null
		and specialty_claim.deadline_operational_minute
			<= urgent_claim.deadline_operational_minute + AUTO_SPECIALTY_GRACE_MINUTES
	):
		return _remove_claim_at(worker.specialty, specialty_index)
	return _remove_claim_at(urgent_lane, urgent_index)


func _claim_speed_factor(worker: ChickenState) -> float:
	if worker.current_claim == null:
		return 1.0
	var affinity := (
		SPECIALTY_SPEED_MULTIPLIER
		if worker.has_specialty(worker.current_claim.lane) else
		MISMATCH_SPEED_MULTIPLIER
	)
	return affinity / maxf(0.1, worker.current_claim.difficulty)


func _claim_affinity_crack_modifier(worker: ChickenState) -> float:
	if worker.current_claim == null:
		return 0.0
	return (
		SPECIALTY_CRACK_MODIFIER
		if worker.has_specialty(worker.current_claim.lane) else
		MISMATCH_CRACK_MODIFIER
	)


func _schedule_rework(source_claim: ClaimState) -> void:
	if source_claim == null:
		return
	var definition: Dictionary = CLAIM_LANE_DEFINITIONS[source_claim.lane]
	var available_on_day := day + 1
	var arrival_minute := _operational_minute_for_shift_start(available_on_day)
	var service_window := int(definition["deadline_minutes"])
	var rework := ClaimState.new(
		_next_claim_id,
		source_claim.lane,
		"%s REWORK" % String(definition["display_name"]),
		source_claim.difficulty * 1.08,
		maxi(90, roundi(source_claim.value_cents * 0.50)),
		source_claim.base_crack_risk + 0.015,
		arrival_minute,
		arrival_minute + service_window,
		service_window,
		true,
		source_claim.id,
		available_on_day,
		source_claim.rework_depth + 1
	)
	_next_claim_id += 1
	_pending_rework.append(rework)
	_rework_total_created += 1


func _release_due_rework() -> void:
	for index in range(_pending_rework.size() - 1, -1, -1):
		var claim := _pending_rework[index]
		if claim.available_day <= day:
			_pending_rework.remove_at(index)
			_append_claim_to_queue(claim)
	_sync_claims_waiting()


func _queue_snapshot() -> Dictionary:
	var now := _current_operational_minute()
	var counts: Dictionary = {}
	var items: Dictionary = {}
	var overdue_counts: Dictionary = {}
	for lane in CLAIM_LANES:
		var queue: Array = _claim_queues[lane]
		var lane_items: Array[Dictionary] = []
		var lane_overdue := 0
		for claim_value in queue:
			var claim := claim_value as ClaimState
			if claim == null:
				continue
			var claim_snapshot := claim.snapshot(now)
			lane_items.append(claim_snapshot)
			if bool(claim_snapshot["overdue"]):
				lane_overdue += 1
		counts[lane] = lane_items.size()
		items[lane] = lane_items
		overdue_counts[lane] = lane_overdue
	return {
		"counts": counts,
		"items": items,
		"overdue_counts": overdue_counts,
	}


func _overdue_claim_count(include_active: bool = true) -> int:
	var now := _current_operational_minute()
	var total := 0
	for lane in CLAIM_LANES:
		for claim_value in (_claim_queues[lane] as Array):
			var claim := claim_value as ClaimState
			if claim != null and claim.is_overdue(now):
				total += 1
	if include_active:
		for worker in workers:
			if not worker.employed:
				continue
			if worker.current_claim != null and worker.current_claim.is_overdue(now):
				total += 1
	return total


func _queued_rework_count() -> int:
	var total := 0
	for lane in CLAIM_LANES:
		for claim_value in (_claim_queues[lane] as Array):
			var claim := claim_value as ClaimState
			if claim != null and claim.is_rework:
				total += 1
	return total


func _active_rework_count() -> int:
	var total := 0
	for worker in workers:
		if not worker.employed:
			continue
		if worker.current_claim != null and worker.current_claim.is_rework:
			total += 1
	return total


func advance_tick() -> void:
	if shift_phase != ShiftPhase.RUNNING:
		return
	_tick_count += 1
	minute_of_day += MINUTES_PER_TICK

	_release_due_rework()
	if _tick_count % 3 == 0 and _outstanding_claim_count() < MAX_CLAIM_QUEUE:
		_enqueue_new_claim(_choose_arrival_lane())

	for worker in workers:
		if not worker.employed:
			continue
		_update_worker(worker)

	if _maybe_open_incident():
		snapshot_changed.emit(snapshot())
		return

	if minute_of_day >= SHIFT_END_MINUTE:
		_complete_workday()

	snapshot_changed.emit(snapshot())


func fund_feed_party() -> bool:
	const COST_CENTS := 2000
	if shift_phase != ShiftPhase.RUNNING:
		announcement_posted.emit("FEED PARTY DENIED: settle the current management decision first.")
		return false
	if feed_party_used_today:
		announcement_posted.emit("FEED PARTY DENIED: one measurable celebration per shift.")
		return false
	var spendable := spendable_fund_cents()
	if spendable < COST_CENTS:
		announcement_posted.emit("BUDGET DENIED: morale must improve more economically.")
		return false

	revenue_cents -= COST_CENTS
	feed_party_used_today = true
	for worker in workers:
		if not worker.employed:
			continue
		worker.morale = minf(100.0, worker.morale + 10.0)
		worker.stress = maxf(0.0, worker.stress - 8.0)
	_adjust_worker_relationships(2.0, -2.0)
	executive_confidence = minf(100.0, executive_confidence + 2.0)
	solidarity = minf(100.0, solidarity + 1.5)
	feed_party_funded.emit()
	announcement_posted.emit("MANDATORY FEED PARTY funded. Trough attendance will be measured.")
	snapshot_changed.emit(snapshot())
	return true


func upgrade_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for upgrade_id in UPGRADE_ORDER:
		var definition: Dictionary = UPGRADE_DEFINITIONS[upgrade_id]
		var level := upgrade_level(upgrade_id)
		catalog.append({
			"id": upgrade_id,
			"name": String(definition["name"]),
			"short_name": String(definition["short_name"]),
			"description": String(definition["description"]),
			"level": level,
			"max_level": MAX_UPGRADE_LEVEL,
			"cost_cents": upgrade_cost_cents(upgrade_id),
			"maxed": level >= MAX_UPGRADE_LEVEL,
		})
	return catalog


func upgrade_level(upgrade_id: StringName) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func upgrade_cost_cents(upgrade_id: StringName) -> int:
	if not UPGRADE_DEFINITIONS.has(upgrade_id):
		return -1
	var definition: Dictionary = UPGRADE_DEFINITIONS[upgrade_id]
	var level := upgrade_level(upgrade_id)
	if level >= MAX_UPGRADE_LEVEL:
		return 0
	return roundi(float(definition["base_cost_cents"]) * pow(float(definition["growth"]), level))


func purchase_upgrade(upgrade_id: StringName) -> bool:
	if not UPGRADE_DEFINITIONS.has(upgrade_id):
		announcement_posted.emit("REQUISITION DENIED: initiative code not found.")
		return false
	var level := upgrade_level(upgrade_id)
	if level >= MAX_UPGRADE_LEVEL:
		announcement_posted.emit("REQUISITION DENIED: this initiative is already fully optimized.")
		return false
	var cost := upgrade_cost_cents(upgrade_id)
	var spendable := spendable_fund_cents()
	if spendable < cost:
		announcement_posted.emit(
			"REQUISITION DENIED: $%.2f more spendable feed funding required." % (
				float(cost - spendable) / 100.0
			)
		)
		return false
	revenue_cents -= cost
	level += 1
	upgrade_levels[upgrade_id] = level
	var definition: Dictionary = UPGRADE_DEFINITIONS[upgrade_id]
	upgrade_purchased.emit(upgrade_id, level, cost)
	announcement_posted.emit("APPROVED: %s is now level %d." % [String(definition["name"]), level])
	snapshot_changed.emit(snapshot())
	return true


func estimated_crack_risk(worker_id: int) -> float:
	if worker_id < 0 or worker_id >= workers.size():
		return 1.0
	if not workers[worker_id].employed:
		return 0.0
	return _error_risk_for(workers[worker_id])


func toggle_overtime() -> bool:
	if shift_phase != ShiftPhase.RUNNING:
		announcement_posted.emit("AFTER-HOURS PECKING DENIED: management has an unresolved decision.")
		return overtime_enabled
	overtime_enabled = not overtime_enabled
	if overtime_enabled:
		_breach_safe_pace_compact(&"overtime_enabled")
		announcement_posted.emit("DISCRETIONARY PECK COMMITMENT is now mandatory.")
	else:
		announcement_posted.emit("Normal pecking hours restored pending farmer inspection.")
	snapshot_changed.emit(snapshot())
	return overtime_enabled


func snapshot() -> Dictionary:
	_sync_claims_waiting()
	var now := _current_operational_minute()
	var worker_snapshots: Array[Dictionary] = []
	var live_pecking_order := current_pecking_order()
	var staffing_action_available := staffing_planning_open() and not _staffing_action_used_today()
	var active_staff := active_worker_count()
	var vacant_desk := _lowest_vacant_desk()
	var spendable := spendable_fund_cents()
	var assist_delivery_status := peck_assist_delivery_status()
	for worker in workers:
		var worker_snapshot := worker.snapshot(now)
		var shift_stats := _worker_shift_stat(worker.id)
		worker_snapshot["shift_eggs"] = int(shift_stats.get("eggs", 0))
		worker_snapshot["shift_sound"] = int(shift_stats.get("sound", 0))
		worker_snapshot["shift_cracked"] = int(shift_stats.get("cracked", 0))
		worker_snapshot["shift_golden"] = int(shift_stats.get("golden", 0))
		worker_snapshot["shift_credit_cents"] = int(shift_stats.get("credit_cents", 0))
		worker_snapshot["at_workstation"] = is_worker_at_workstation(worker.id)
		worker_snapshot["specialty_name"] = _lane_display_name(worker.specialty)
		worker_snapshot["secondary_specialty_name"] = (
			_lane_display_name(worker.secondary_specialty)
			if worker.has_secondary_specialty() else
			""
		)
		worker_snapshot["cross_training_target_name"] = (
			_lane_display_name(worker.cross_training_target)
			if worker.cross_training_pending() else
			""
		)
		worker_snapshot["cross_training_active"] = (
			worker.employed
			and worker.cross_training_pending()
			and shift_phase == ShiftPhase.RUNNING
		)
		var profile_definition := CAREER_PROFILE_DEFINITIONS.get(worker.career_profile, {}) as Dictionary
		worker_snapshot["career_profile_name"] = String(profile_definition.get("name", "UNFILED PROFILE"))
		worker_snapshot["career_profile_description"] = String(profile_definition.get("description", ""))
		worker_snapshot["preferred_personnel_action"] = (
			_preferred_personnel_action(worker) if worker.employed else &""
		)
		worker_snapshot["career_work_multiplier"] = (
			_career_relationship_work_multiplier(worker) if worker.employed else 1.0
		)
		worker_snapshot["career_crack_modifier"] = (
			_career_relationship_crack_modifier(worker) if worker.employed else 0.0
		)
		worker_snapshot["peck_assist"] = peck_assist_status(worker.id)
		var pending_sponsor_id := int(pending_decision.get("sponsor_worker_id", -1))
		var compact_sponsor_id := int(active_flock_compact.get("sponsor_worker_id", -1))
		worker_snapshot["is_petition_sponsor"] = worker.id == pending_sponsor_id
		worker_snapshot["is_compact_sponsor"] = worker.id == compact_sponsor_id
		worker_snapshot["compact_status"] = (
			StringName(active_flock_compact.get("status", &""))
			if worker.id == compact_sponsor_id else &""
		)
		worker_snapshot["compact_condition"] = (
			String(active_flock_compact.get("condition", ""))
			if worker.id == compact_sponsor_id else ""
		)
		worker_snapshot["assignment_name"] = (
			"APPLICANT POOL"
			if not worker.employed else
			("AUTO DISPATCH" if worker.assigned_lane == AUTO_ASSIGNMENT else
			_lane_display_name(worker.assigned_lane)
			)
		)
		worker_snapshot["can_hire"] = (
			staffing_action_available
			and not worker.employed
			and worker.available_for_hire_day <= day
			and active_staff < office_capacity
			and vacant_desk >= 0
			and spendable >= worker.hire_cost_cents()
		)
		worker_snapshot["can_release"] = (
			staffing_action_available
			and worker.employed
			and active_staff > MINIMUM_STAFF_COUNT
			and worker.work_state == ChickenState.WorkState.IDLE
			and worker.current_claim == null
			and spendable >= worker.release_cost_cents()
		)
		var current_claim_snapshot := worker_snapshot.get("current_claim", {}) as Dictionary
		if not current_claim_snapshot.is_empty():
			current_claim_snapshot["specialty_match"] = worker.has_specialty(worker.current_claim.lane)
			current_claim_snapshot["affinity_speed_multiplier"] = _claim_speed_factor(worker)
			current_claim_snapshot["affinity_crack_modifier"] = _claim_affinity_crack_modifier(worker)
		worker_snapshots.append(worker_snapshot)
	var queue_snapshot := _queue_snapshot()
	var pending_rework_items: Array[Dictionary] = []
	for claim in _pending_rework:
		pending_rework_items.append(claim.snapshot(now))

	var personnel_status := personnel_action_status()
	return {
		"day": day,
		"minute_of_day": minute_of_day,
		"time_label": _format_time(minute_of_day),
		"claims_waiting": claims_waiting,
		"claims_outstanding": _outstanding_claim_count(),
		"claims_processed": claims_processed,
		"eggs_today": eggs_today,
		"eggs_total": eggs_total,
		"cracked_eggs": cracked_eggs,
		"cracked_today": cracked_today,
		"golden_eggs": golden_eggs,
		"golden_today": golden_today,
		"revenue_cents": revenue_cents,
		"credited_today_cents": credited_today_cents,
		"daily_feed_cost_cents": current_daily_feed_cost_cents(),
		"active_staff_count": active_staff,
		"office_capacity": office_capacity,
		"maximum_staff_capacity": MAXIMUM_STAFF_CAPACITY,
		"daily_payroll_cents": current_daily_payroll_cents(),
		"daily_facility_cost_cents": current_daily_facility_cost_cents(),
		"daily_operating_cost_cents": current_daily_operating_cost_cents(),
		"wage_arrears_cents": wage_arrears_cents,
		"spendable_fund_cents": spendable,
		"career_sponsorship_cost_cents": CAREER_SPONSORSHIP_COST_CENTS,
		"career_sponsorship_planning_open": shift_phase == ShiftPhase.REVIEW,
		"staffing_planning_open": staffing_planning_open(),
		"capacity_upgrade": capacity_upgrade_status(),
		"staffing_catalog": staffing_catalog(),
		"last_staffing_action": last_staffing_action.duplicate(true),
		"pecking_order": live_pecking_order,
		"last_pecking_order": last_pecking_order.duplicate(true),
		"last_pecking_order_day": last_pecking_order_day,
		"last_credit_allocation": last_credit_allocation.duplicate(true),
		"credit_choice_counts": credit_choice_counts.duplicate(),
		"leadership_record": leadership_record_snapshot(),
		"credit_memo_pending": (
			StringName(pending_decision.get("kind", &""))
			in [&"credit_allocation", &"major_event"]
		),
		"golden_dossier_resolved": golden_dossier_resolved,
		"golden_dossier_day": golden_dossier_day,
		"flock_restructuring_resolved": flock_restructuring_resolved,
		"flock_restructuring_day": flock_restructuring_day,
		"flock_restructuring_record": flock_restructuring_record.duplicate(true),
		"flock_petition": last_flock_petition.duplicate(true),
		"flock_petition_history": flock_petition_history.duplicate(true),
		"flock_compact": active_flock_compact.duplicate(true),
		"flock_compact_receipt": last_flock_compact_receipt.duplicate(true),
		"work_to_rule": work_to_rule_snapshot(),
		"solidarity_action_threshold": WORK_TO_RULE_SOLIDARITY_THRESHOLD,
		"credit_memo_id": StringName(pending_decision.get("id", &"")),
		"peck_assists_used_today": peck_assists_used_today,
		"peck_assists_remaining": _peck_assist_charges_available(),
		"peck_assist_charges": _peck_assist_charges_available(),
		"peck_assist_limit": PECK_ASSIST_LIMIT,
		"peck_assist_interventions_today": peck_assist_interventions_today,
		"peck_assist_gross_interventions": peck_assist_interventions_today,
		"peck_assist_refunds_today": peck_assist_refunds_today,
		"peck_assist_pending_delivery": (
			assist_delivery_status.get("pending_delivery", {}) as Dictionary
		).duplicate(true),
		"peck_assist_pending_delivery_count": int(assist_delivery_status.get("pending_delivery_count", 0)),
		"peck_assist_pending_deliveries": (
			assist_delivery_status.get("pending_deliveries", []) as Array
		).duplicate(true),
		"peck_assist_delivery_reason": String(assist_delivery_status.get("reason", "")),
		"peck_assist_streak": peck_assist_streak,
		"best_peck_assist_streak": best_peck_assist_streak,
		"last_peck_assist": last_peck_assist.duplicate(true),
		"last_peck_assist_delivery": last_peck_assist_delivery.duplicate(true),
		"priority_credit_today_cents": priority_credit_today_cents,
		"priority_credit_total_cents": priority_credit_total_cents,
		"quota_target": quota_target,
		"executive_confidence": executive_confidence,
		"compliance": compliance,
		"solidarity": solidarity,
		"overtime_enabled": overtime_enabled,
		"feed_party_used_today": feed_party_used_today,
		"quality_streak": quality_streak,
		"best_quality_streak": best_quality_streak,
		"last_streak_bonus_cents": last_streak_bonus_cents,
		"shift_phase": shift_phase,
		"shift_phase_label": phase_label(),
		"active_directive": active_directive_snapshot(),
		"pending_decision": pending_decision_snapshot(),
		"incidents_resolved_today": incidents_resolved_today,
		"decision_modifiers": {
			"work_multiplier": _directive_work_multiplier * _incident_work_multiplier * _work_to_rule_work_multiplier(),
			"fatigue_multiplier": _directive_fatigue_multiplier * _incident_strain_multiplier,
			"stress_multiplier": _directive_stress_multiplier * _incident_strain_multiplier,
			"morale_drain_multiplier": _directive_morale_drain_multiplier,
			"crack_modifier": _directive_crack_modifier + _incident_crack_modifier + _work_to_rule_crack_modifier(),
			"work_to_rule_work_multiplier": _work_to_rule_work_multiplier(),
			"work_to_rule_crack_modifier": _work_to_rule_crack_modifier(),
			"golden_modifier": _incident_golden_modifier,
			"quota_adjustment": _pending_quota_adjustment,
		},
		"upgrade_levels": upgrade_levels.duplicate(),
		"upgrade_catalog": upgrade_catalog(),
		"auto_assignment_id": AUTO_ASSIGNMENT,
		"routing_catalog": routing_catalog(),
		"claim_queue_counts": (queue_snapshot["counts"] as Dictionary).duplicate(),
		"claim_queue_items": (queue_snapshot["items"] as Dictionary).duplicate(true),
		"claim_queue_overdue_counts": (queue_snapshot["overdue_counts"] as Dictionary).duplicate(),
		"queued_overdue_claims": _overdue_claim_count(false),
		"overdue_claims": _overdue_claim_count(true),
		"rework_waiting": _queued_rework_count(),
		"rework_in_progress": _active_rework_count(),
		"rework_due_next_shift": _pending_rework.size(),
		"rework_pending_items": pending_rework_items,
		"rework_total_created": _rework_total_created,
		"lane_processed_today": lane_processed_today.duplicate(),
		"lane_processed_totals": lane_processed_totals.duplicate(),
		"campaign_unlocks": campaign_unlocks.duplicate(),
		"campaign_unlock_effects": campaign_unlock_effects(),
		"personnel_action_available": bool(personnel_status["available"]),
		"personnel_action_used": bool(personnel_status["used_today"]),
		"personnel_action_status": personnel_status,
		"personnel_catalog": personnel_action_catalog(),
		"workers": worker_snapshots,
	}


func _personnel_action_for_day(target_day: int) -> Dictionary:
	for worker in workers:
		if not worker.employed:
			continue
		if worker.last_personnel_action_day != target_day or worker.last_personnel_action == &"":
			continue
		var definition := PERSONNEL_ACTION_DEFINITIONS.get(worker.last_personnel_action, {}) as Dictionary
		if definition.is_empty():
			return {}
		return {
			"day": target_day,
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"action_id": worker.last_personnel_action,
			"action_name": String(definition.get("name", "PERSONNEL ACTION")),
			"cost_cents": int(definition.get("cost_cents", 0)),
			"preferred": _preferred_personnel_action(worker) == worker.last_personnel_action,
			"outcome": _personnel_action_outcome(worker, worker.last_personnel_action),
		}
	return {}


func _personnel_shift_work_multiplier(worker: ChickenState) -> float:
	if worker.last_personnel_action_day != day:
		return 1.0
	match worker.last_personnel_action:
		&"career_coaching":
			return 0.94
		&"quota_pressure":
			return 1.18 if _preferred_personnel_action(worker) == &"quota_pressure" else 1.14
	return 1.0


func _personnel_shift_crack_modifier(worker: ChickenState) -> float:
	if worker.last_personnel_action_day != day:
		return 0.0
	match worker.last_personnel_action:
		&"career_coaching":
			return -0.03
		&"quota_pressure":
			return 0.025
	return 0.0


func _career_relationship_work_multiplier(worker: ChickenState) -> float:
	var trust_factor := 1.0 + (worker.manager_trust - 50.0) * 0.0012
	var grievance_factor := 1.0 - worker.grievance * 0.0012
	var career_factor := 1.0 + 0.02 * worker.career_level()
	var relationship_multiplier := clampf(
		trust_factor * grievance_factor * career_factor * _personnel_shift_work_multiplier(worker),
		0.75,
		1.30
	)
	return relationship_multiplier * worker.cross_training_work_multiplier()


func _career_relationship_crack_modifier(worker: ChickenState) -> float:
	return clampf(
		(50.0 - worker.manager_trust) * 0.0004
		+ worker.grievance * 0.00035
		- worker.career_level() * 0.004,
		-0.04,
		0.08
	)


func _career_strain_multiplier(worker: ChickenState) -> float:
	var multiplier := 1.0 + worker.career_level() * 0.05
	if worker.grievance >= 40.0:
		multiplier += 0.10
	if worker.grievance >= 70.0:
		multiplier += 0.10
	return multiplier


func _update_worker(worker: ChickenState) -> void:
	if not worker.employed:
		return
	match worker.work_state:
		ChickenState.WorkState.IDLE:
			worker.fatigue = maxf(0.0, worker.fatigue - 0.35)
			if is_worker_at_workstation(worker.id) and claims_waiting > 0:
				var next_claim := _take_claim_for_worker(worker)
				if next_claim != null:
					worker.current_claim = next_claim
					worker.work_state = ChickenState.WorkState.WORKING
		ChickenState.WorkState.WORKING:
			if not is_worker_at_workstation(worker.id):
				return
			var morale_factor := remap(clampf(worker.morale, 20.0, 100.0), 20.0, 100.0, 0.62, 1.1)
			var overtime_factor := 1.22 if overtime_enabled else 1.0
			var tool_factor := 1.0 + 0.08 * upgrade_level(&"peckwork_tools")
			var comfort_factor := maxf(0.50, 1.0 - 0.10 * upgrade_level(&"nest_cushion"))
			var decision_work_factor := (
				_directive_work_multiplier
				* _incident_work_multiplier
				* _work_to_rule_work_multiplier()
			)
			var total_work_factor := clampf(overtime_factor * tool_factor * decision_work_factor, 0.55, 1.70)
			var decision_strain_factor := _incident_strain_multiplier
			var campaign_fatigue_factor := 0.90 if has_campaign_unlock(&"welfare_breaks") else 1.0
			var campaign_stress_factor := 0.88 if has_campaign_unlock(&"welfare_breaks") else 1.0
			var career_work_factor := _career_relationship_work_multiplier(worker)
			var career_strain_factor := _career_strain_multiplier(worker)
			var progress_before_tick := worker.work_progress
			worker.work_progress += BASE_WORK_PROGRESS * worker.skill * morale_factor * total_work_factor * _claim_speed_factor(worker) * career_work_factor
			if worker.cross_training_pending() and worker.work_progress > progress_before_tick:
				worker.cross_training_worked_this_shift = true
			if (
				worker.current_claim != null
				and progress_before_tick <= PECK_ASSIST_WINDOW_END
				and worker.work_progress > PECK_ASSIST_WINDOW_END
				and not _assisted_claim_ids.has(worker.current_claim.id)
				and not _missed_assist_claim_ids.has(worker.current_claim.id)
			):
				var missed_claim_id := worker.current_claim.id
				_missed_assist_claim_ids[missed_claim_id] = true
				peck_assist_streak = 0
				peck_assist_missed.emit(worker.id, missed_claim_id)
			worker.fatigue = minf(100.0, worker.fatigue + (0.65 if overtime_enabled else 0.36) * comfort_factor * _directive_fatigue_multiplier * decision_strain_factor * campaign_fatigue_factor)
			worker.stress = minf(100.0, worker.stress + (0.40 if overtime_enabled else 0.2) * comfort_factor * _directive_stress_multiplier * decision_strain_factor * campaign_stress_factor * career_strain_factor)
			worker.morale = maxf(0.0, worker.morale - (0.18 if overtime_enabled else 0.07) * _directive_morale_drain_multiplier)
			if overtime_enabled:
				worker.manager_trust = maxf(0.0, worker.manager_trust - 0.025)
				worker.grievance = minf(100.0, worker.grievance + 0.04)
			if worker.work_progress >= 100.0:
				worker.work_progress = 100.0
				worker.work_state = ChickenState.WorkState.LAYING
				worker.state_ticks_remaining = 3
		ChickenState.WorkState.LAYING:
			if not is_worker_at_workstation(worker.id):
				return
			worker.state_ticks_remaining -= 1
			if worker.state_ticks_remaining <= 0:
				_complete_egg(worker)
		ChickenState.WorkState.BREAK:
			worker.state_ticks_remaining -= 1
			worker.fatigue = maxf(0.0, worker.fatigue - 2.0)
			worker.stress = maxf(0.0, worker.stress - 1.4)
			if worker.state_ticks_remaining <= 0:
				worker.work_state = ChickenState.WorkState.IDLE

	if worker.fatigue >= 78.0 and worker.work_state == ChickenState.WorkState.IDLE:
		worker.work_state = ChickenState.WorkState.BREAK
		worker.state_ticks_remaining = 10


func _error_risk_for(worker: ChickenState) -> float:
	var error_risk := 1.0 - worker.accuracy
	error_risk += worker.stress / 500.0
	error_risk += worker.fatigue / 600.0
	if overtime_enabled:
		error_risk += 0.08
	if compliance < 60.0:
		error_risk += (60.0 - compliance) / 400.0
	error_risk -= 0.025 * upgrade_level(&"shell_lamp")
	if has_campaign_unlock(&"shell_quality_checks"):
		error_risk -= 0.025
	error_risk += _directive_crack_modifier + _incident_crack_modifier + _work_to_rule_crack_modifier()
	error_risk += _career_relationship_crack_modifier(worker)
	error_risk += _personnel_shift_crack_modifier(worker)
	if worker.current_claim != null:
		error_risk += worker.current_claim.base_crack_risk
		error_risk += _claim_affinity_crack_modifier(worker)
		error_risk += float(_assist_quality_modifiers.get(worker.current_claim.id, 0.0))
	return clampf(error_risk, 0.02, 0.92)


func _complete_egg(worker: ChickenState) -> void:
	var completed_claim := worker.current_claim
	var error_risk := _error_risk_for(worker)
	var assisted_claim_id := completed_claim.id if completed_claim != null else -1
	var was_assisted := assisted_claim_id > 0 and _assisted_claim_ids.has(assisted_claim_id)
	var assist_chain := int(_assist_chain_by_claim_id.get(assisted_claim_id, 0))

	var roll := _rng.randf()
	var quality: StringName = &"sound"
	var base_value_cents := completed_claim.value_cents if completed_claim != null else 420
	var value_cents := base_value_cents
	if roll < error_risk:
		quality = &"cracked"
		value_cents = maxi(90, roundi(base_value_cents * 0.22))
		cracked_eggs += 1
		cracked_today += 1
		compliance = maxf(0.0, compliance - 0.8)
		if completed_claim != null:
			_schedule_rework(completed_claim)
	else:
		var golden_chance := clampf(0.025 + maxf(0.0, worker.morale - 70.0) * 0.0005 + _incident_golden_modifier, 0.025, 0.08)
		if _rng.randf() < golden_chance:
			quality = &"golden"
			value_cents = base_value_cents * 4
			golden_eggs += 1
			golden_today += 1
			executive_confidence = minf(100.0, executive_confidence + 1.5)
	if has_campaign_unlock(&"farmer_credit_bonus"):
		value_cents += 25
	var priority_credit_cents := 0
	if quality != &"cracked" and assist_chain > 0:
		priority_credit_cents = 20 * mini(assist_chain, 5)
		value_cents += priority_credit_cents
		priority_credit_today_cents += priority_credit_cents
		priority_credit_total_cents += priority_credit_cents
		announcement_posted.emit(
			"PRIORITY CREDIT: management added $%.2f to %s's finished claim." % [
				float(priority_credit_cents) / 100.0, worker.display_name,
			]
		)
	if was_assisted:
		if quality == &"cracked":
			# A cracked shell consumes the intervention permanently. It never mints
			# a delivery token, and it breaks the live chain even when other claims
			# are still moving through the office.
			peck_assist_streak = 0
			announcement_posted.emit(
				"PRIORITY PECK CHAIN BROKEN: claim #%04d cracked and cannot restore attention." % assisted_claim_id
			)
		elif quality in [&"sound", &"golden"]:
			# Claim ids are monotonic, so this token is both the presentation handoff
			# and the durable exact-once idempotency key.
			_pending_peck_assist_deliveries[assisted_claim_id] = {
				"day": day,
				"claim_id": assisted_claim_id,
				"worker_id": worker.id,
				"quality": String(quality),
			}

	last_streak_bonus_cents = 0
	if quality == &"cracked":
		quality_streak = 0
	else:
		quality_streak += 1
		best_quality_streak = maxi(best_quality_streak, quality_streak)
		last_streak_bonus_cents = mini(quality_streak, 8) * 35
		value_cents += last_streak_bonus_cents
	quality_streak_changed.emit(quality_streak, best_quality_streak)
	var xp_award := 1 if quality == &"cracked" else (5 if quality == &"golden" else 3)
	if worker.add_career_xp(xp_award):
		announcement_posted.emit("PROMOTION FILED: %s is now %s." % [worker.display_name.to_upper(), worker.career_title()])
	_record_worker_shift_result(worker.id, quality, value_cents)

	worker.eggs_laid += 1
	if completed_claim != null:
		lane_processed_today[completed_claim.lane] = int(lane_processed_today.get(completed_claim.lane, 0)) + 1
		lane_processed_totals[completed_claim.lane] = int(lane_processed_totals.get(completed_claim.lane, 0)) + 1
		_assisted_claim_ids.erase(completed_claim.id)
		_missed_assist_claim_ids.erase(completed_claim.id)
		_assist_quality_modifiers.erase(completed_claim.id)
		_assist_chain_by_claim_id.erase(completed_claim.id)
	worker.current_claim = null
	worker.work_progress = 0.0
	worker.work_state = ChickenState.WorkState.IDLE
	claims_processed += 1
	eggs_today += 1
	eggs_total += 1
	revenue_cents += value_cents
	credited_today_cents += value_cents
	egg_laid_detailed.emit(
		worker.id,
		quality,
		value_cents,
		assisted_claim_id,
		priority_credit_cents,
	)
	egg_laid.emit(worker.id, quality, value_cents)


func _flock_welfare_score() -> int:
	var active_count := active_worker_count()
	if active_count == 0:
		return 0
	var total := 0
	for worker in workers:
		if not worker.employed:
			continue
		var morale := roundi(worker.morale)
		var stress := roundi(worker.stress)
		var fatigue := roundi(worker.fatigue)
		total += clampi(morale + 20 - roundi(float(stress) / 3.0) - roundi(float(fatigue) / 5.0), 0, 100)
	return roundi(float(total) / float(active_count))


func _average_manager_trust() -> int:
	var active_count := active_worker_count()
	if active_count == 0:
		return 0
	var total := 0.0
	for worker in workers:
		if not worker.employed:
			continue
		total += worker.manager_trust
	return roundi(total / float(active_count))


func _average_grievance() -> int:
	var active_count := active_worker_count()
	if active_count == 0:
		return 0
	var total := 0.0
	for worker in workers:
		if not worker.employed:
			continue
		total += worker.grievance
	return roundi(total / float(active_count))


func _complete_career_sponsorships(completed_day: int) -> Array[Dictionary]:
	## Accreditation is deliberately filed after this shift's payroll has been
	## captured. The training shift therefore uses the old wage, while every
	## later operating reserve includes the permanent $1 credential premium.
	var completions: Array[Dictionary] = []
	for worker in workers:
		if (
			not worker.employed
			or not worker.cross_training_pending()
			or not worker.cross_training_worked_this_shift
		):
			continue
		var target_lane := worker.cross_training_target
		var wage_before := worker.daily_wage_cents()
		var accredited_lane := worker.complete_cross_training()
		if accredited_lane == &"":
			continue
		var outcome := "%s is now cross-accredited in %s; her permanent daily wage rises by $1.00." % [
			worker.display_name,
			_lane_display_name(accredited_lane),
		]
		var receipt := {
			"status": &"accredited",
			"day": completed_day,
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"primary_specialty": worker.specialty,
			"secondary_specialty": accredited_lane,
			"training_target": target_lane,
			"daily_wage_before_cents": wage_before,
			"daily_wage_cents": worker.daily_wage_cents(),
			"daily_wage_delta_cents": worker.daily_wage_cents() - wage_before,
			"outcome": outcome,
		}
		completions.append(receipt)
		announcement_posted.emit(outcome)
	return completions


func _complete_workday() -> void:
	var completed_day := day
	var completed_eggs := eggs_today
	var completed_quota := quota_target
	var completed_cracked := cracked_today
	var completed_golden := golden_today
	var completed_priority_credit_cents := priority_credit_today_cents
	var completed_directive := active_directive_snapshot()
	var completed_incidents := incidents_resolved_today
	var completed_feed_cost := current_daily_feed_cost_cents()
	var completed_facility_cost := current_daily_facility_cost_cents()
	var completed_payroll := current_daily_payroll_cents()
	var completed_career_sponsorships := _complete_career_sponsorships(completed_day)
	var opening_wage_arrears := wage_arrears_cents
	var completed_operating_cost := (
		completed_feed_cost + completed_facility_cost + completed_payroll
	)
	var completed_active_staff := active_worker_count()
	var completed_office_capacity := office_capacity
	var completed_quota_adjustment := _pending_quota_adjustment
	var completed_lane_processed: Dictionary = lane_processed_today.duplicate()
	var completed_personnel_action := _personnel_action_for_day(completed_day)
	var completed_staffing_actions := _staffing_actions_for_day(completed_day)
	var completed_flock_petition: Dictionary = {}
	if int(last_flock_petition.get("day", 0)) == completed_day:
		completed_flock_petition = last_flock_petition.duplicate(true)
	var completed_pecking_order := current_pecking_order()
	last_pecking_order = completed_pecking_order.duplicate(true)
	last_pecking_order_day = completed_day
	var completed_overdue_claims := _overdue_claim_count(true)
	var met_quota := eggs_today >= quota_target
	var quota_bonus_cents := 0
	var quality_bonus_cents := 0
	if met_quota:
		executive_confidence = minf(100.0, executive_confidence + 4.0)
		var surplus_cap := ceili(float(quota_target) * 0.25)
		var rewarded_surplus := mini(maxi(0, eggs_today - quota_target), surplus_cap)
		quota_bonus_cents = 1000 + 200 * day + 100 * rewarded_surplus
		revenue_cents += quota_bonus_cents
		credited_today_cents += quota_bonus_cents
		announcement_posted.emit("DAY %d: The farmer gathered %d eggs from the flock." % [day, eggs_today])
	else:
		executive_confidence = maxf(0.0, executive_confidence - 6.0)
		announcement_posted.emit("DAY %d: The flock missed the farmer's entirely reasonable clutch target." % day)
	var crack_share := float(cracked_today) / maxf(1.0, float(eggs_today))
	if eggs_today > 0 and crack_share <= 0.15:
		quality_bonus_cents = 500
		revenue_cents += quality_bonus_cents
		credited_today_cents += quality_bonus_cents

	var completed_credited_cents := credited_today_cents
	# Feed and physical office costs are paid first. Current wages plus any carried
	# arrears are then paid from the remaining fund without allowing underflow.
	revenue_cents = maxi(
		0,
		revenue_cents - completed_feed_cost - completed_facility_cost
	)
	var payroll_due_cents := opening_wage_arrears + completed_payroll
	var payroll_paid_cents := mini(revenue_cents, payroll_due_cents)
	revenue_cents -= payroll_paid_cents
	wage_arrears_cents = payroll_due_cents - payroll_paid_cents
	if wage_arrears_cents > 0:
		_apply_wage_arrears_consequences()
		announcement_posted.emit(
			"PAYROLL EXCEPTION: $%.2f in hen wages has been moved to a future promise." % (
				float(wage_arrears_cents) / 100.0
			)
		)
	var completed_flock_compact_receipt := _resolve_due_flock_compact(completed_day)
	var completed_work_to_rule := _finish_work_to_rule_day(completed_day)
	var completed_welfare := _flock_welfare_score()
	var completed_compliance := roundi(compliance)
	var completed_farmer_favor := roundi(executive_confidence)
	var completed_average_trust := _average_manager_trust()
	var completed_average_grievance := _average_grievance()
	# Capture one human-scale consequence while this shift's worker ledger and
	# closing relationship values still exist. The report survives the daily
	# stat reset below and is persisted by the office session checkpoint.
	var completed_hen_highlight := _build_shift_hen_highlight(
		completed_day,
		completed_pecking_order,
		completed_eggs,
	)
	var next_quota := quota_target
	if met_quota:
		next_quota += 3 if eggs_today >= ceili(float(quota_target) * 1.25) else 1
	else:
		next_quota = maxi(12, next_quota - 2)
	next_quota = clampi(next_quota + completed_quota_adjustment, maxi(12, quota_target - 2), quota_target + 3)
	var returned_claims := 0
	for worker in workers:
		if not worker.employed:
			continue
		if (
			worker.work_state in [ChickenState.WorkState.WORKING, ChickenState.WorkState.LAYING]
			and worker.current_claim != null
		):
			_append_claim_to_queue(worker.current_claim)
			worker.current_claim = null
			returned_claims += 1
	day += 1
	minute_of_day = SHIFT_START_MINUTE
	quota_target = next_quota
	eggs_today = 0
	cracked_today = 0
	golden_today = 0
	credited_today_cents = 0
	for lane in CLAIM_LANES:
		lane_processed_today[lane] = 0
	_reset_worker_shift_stats()
	quality_streak = 0
	last_streak_bonus_cents = 0
	feed_party_used_today = false
	overtime_enabled = false
	_reset_daily_decision_state()
	_activate_next_shift_flock_state()
	_release_due_rework()
	var new_intake_claims := 0
	for _claim_index in 5:
		if not _enqueue_new_claim(_choose_arrival_lane()):
			break
		new_intake_claims += 1
	shift_phase = ShiftPhase.REVIEW
	_prepare_credit_allocation_decision(
		completed_day,
		completed_pecking_order,
		completed_golden,
	)
	shift_phase_changed.emit(shift_phase)
	for worker in workers:
		if not worker.employed:
			continue
		worker.fatigue = maxf(0.0, worker.fatigue - 24.0)
		worker.stress = maxf(0.0, worker.stress - 10.0)
		worker.current_claim = null
		worker.work_progress = 0.0
		worker.work_state = ChickenState.WorkState.IDLE
	_sync_claims_waiting()

	workday_completed.emit({
		"day": completed_day,
		"eggs": completed_eggs,
		"quota": completed_quota,
		"met_quota": met_quota,
		"cracked": completed_cracked,
		"golden": completed_golden,
		"priority_credit_cents": completed_priority_credit_cents,
		"quota_bonus_cents": quota_bonus_cents,
		"quality_bonus_cents": quality_bonus_cents,
		"credited_cents": completed_credited_cents,
		"feed_cost_cents": completed_feed_cost,
		"facility_cost_cents": completed_facility_cost,
		"payroll_cents": completed_payroll,
		"opening_wage_arrears_cents": opening_wage_arrears,
		"payroll_due_cents": payroll_due_cents,
		"payroll_paid_cents": payroll_paid_cents,
		"wage_arrears_cents": wage_arrears_cents,
		"operating_cost_cents": completed_operating_cost,
		"active_staff_count": completed_active_staff,
		"office_capacity": completed_office_capacity,
		"welfare": completed_welfare,
		"compliance": completed_compliance,
		"farmer_favor": completed_farmer_favor,
		"directive": completed_directive,
		"incidents_resolved": completed_incidents,
		"quota_adjustment": completed_quota_adjustment,
		"returned_claims": returned_claims,
		"new_intake_claims": new_intake_claims,
		"lane_processed": completed_lane_processed,
		"personnel_action": completed_personnel_action,
		"staffing_actions": completed_staffing_actions,
		"career_sponsorships_completed": completed_career_sponsorships,
		"flock_petition": completed_flock_petition,
		"flock_compact_receipt": completed_flock_compact_receipt,
		"work_to_rule": completed_work_to_rule,
		"next_flock_compact": active_flock_compact.duplicate(true),
		"next_work_to_rule": work_to_rule_snapshot(),
		"pecking_order": completed_pecking_order,
		"hen_highlight": completed_hen_highlight,
		"credit_memo_required": not pending_decision.is_empty(),
		"credit_memo_kind": StringName(pending_decision.get("kind", &"")),
		"credit_memo_id": StringName(pending_decision.get("id", &"")),
		"average_manager_trust": completed_average_trust,
		"average_grievance": completed_average_grievance,
		"overdue_claims": completed_overdue_claims,
		"rework_waiting": _queued_rework_count(),
		"rework_due_next_shift": _pending_rework.size(),
		"rework_total_created": _rework_total_created,
		"closing_fund_cents": revenue_cents,
		"next_quota": quota_target,
	})


func _build_shift_hen_highlight(
	completed_day: int,
	ranking: Array[Dictionary],
	completed_eggs: int,
) -> Dictionary:
	## Selects one deterministic, real shift story for the closing report. The
	## priority favors consequences and exceptional moments over the ordinary
	## ledger leader, which remains a guaranteed fallback.
	if ranking.is_empty():
		return {}
	var pressure_rows: Array[Dictionary] = []
	var golden_rows: Array[Dictionary] = []
	var strain_rows: Array[Dictionary] = []
	var invisible_rows: Array[Dictionary] = []
	var average_output := float(maxi(0, completed_eggs)) / float(ranking.size())
	var bottom_half_starts_after := ceili(float(ranking.size()) / 2.0)
	for row in ranking:
		var worker_id := int(row.get("worker_id", -1))
		if worker_id < 0 or worker_id >= workers.size():
			continue
		var worker := workers[worker_id]
		if not worker.employed:
			continue
		if (
			worker.last_personnel_action_day == completed_day
			and worker.last_personnel_action == &"quota_pressure"
			and int(row.get("cracked", 0)) > 0
		):
			pressure_rows.append(row)
		if int(row.get("golden", 0)) > 0:
			golden_rows.append(row)
		if (
			worker.grievance >= 45.0
			or worker.manager_trust <= 40.0
			or worker.stress >= 70.0
			or worker.fatigue >= 78.0
		):
			strain_rows.append(row)
		if (
			int(row.get("eggs", 0)) >= 2
			and float(int(row.get("eggs", 0))) >= average_output
			and int(row.get("rank", 0)) > bottom_half_starts_after
		):
			invisible_rows.append(row)

	pressure_rows.sort_custom(_pressure_highlight_precedes)
	golden_rows.sort_custom(_golden_highlight_precedes)
	strain_rows.sort_custom(_strain_highlight_precedes)
	invisible_rows.sort_custom(_invisible_highlight_precedes)
	var highlight_type := &"ledger_leader"
	var selected_row := ranking[0]
	if not pressure_rows.is_empty():
		highlight_type = &"pressure_exception"
		selected_row = pressure_rows[0]
	elif not golden_rows.is_empty():
		highlight_type = &"golden_deliverable"
		selected_row = golden_rows[0]
	elif not strain_rows.is_empty():
		highlight_type = &"strain_notice"
		selected_row = strain_rows[0]
	elif not invisible_rows.is_empty():
		highlight_type = &"invisible_labor"
		selected_row = invisible_rows[0]
	return _format_shift_hen_highlight(highlight_type, completed_day, selected_row)


func _pressure_highlight_precedes(a: Dictionary, b: Dictionary) -> bool:
	var cracked_a := int(a.get("cracked", 0))
	var cracked_b := int(b.get("cracked", 0))
	if cracked_a != cracked_b:
		return cracked_a > cracked_b
	var worker_a := workers[int(a.get("worker_id", 0))]
	var worker_b := workers[int(b.get("worker_id", 0))]
	if not is_equal_approx(worker_a.stress, worker_b.stress):
		return worker_a.stress > worker_b.stress
	return worker_a.id < worker_b.id


func _golden_highlight_precedes(a: Dictionary, b: Dictionary) -> bool:
	var golden_a := int(a.get("golden", 0))
	var golden_b := int(b.get("golden", 0))
	if golden_a != golden_b:
		return golden_a > golden_b
	var credit_a := int(a.get("credit_cents", 0))
	var credit_b := int(b.get("credit_cents", 0))
	if credit_a != credit_b:
		return credit_a > credit_b
	var cracked_a := int(a.get("cracked", 0))
	var cracked_b := int(b.get("cracked", 0))
	if cracked_a != cracked_b:
		return cracked_a < cracked_b
	return int(a.get("worker_id", 0)) < int(b.get("worker_id", 0))


func _strain_highlight_precedes(a: Dictionary, b: Dictionary) -> bool:
	var worker_a := workers[int(a.get("worker_id", 0))]
	var worker_b := workers[int(b.get("worker_id", 0))]
	var danger_a := worker_a.stress + worker_a.fatigue + worker_a.grievance + (100.0 - worker_a.manager_trust)
	var danger_b := worker_b.stress + worker_b.fatigue + worker_b.grievance + (100.0 - worker_b.manager_trust)
	if not is_equal_approx(danger_a, danger_b):
		return danger_a > danger_b
	var cracked_a := int(a.get("cracked", 0))
	var cracked_b := int(b.get("cracked", 0))
	if cracked_a != cracked_b:
		return cracked_a > cracked_b
	return worker_a.id < worker_b.id


func _invisible_highlight_precedes(a: Dictionary, b: Dictionary) -> bool:
	var eggs_a := int(a.get("eggs", 0))
	var eggs_b := int(b.get("eggs", 0))
	if eggs_a != eggs_b:
		return eggs_a > eggs_b
	var rank_a := int(a.get("rank", 0))
	var rank_b := int(b.get("rank", 0))
	if rank_a != rank_b:
		return rank_a > rank_b
	var credit_a := int(a.get("credit_cents", 0))
	var credit_b := int(b.get("credit_cents", 0))
	if credit_a != credit_b:
		return credit_a < credit_b
	return int(a.get("worker_id", 0)) < int(b.get("worker_id", 0))


func _format_shift_hen_highlight(
	highlight_type: StringName,
	completed_day: int,
	row: Dictionary,
) -> Dictionary:
	var worker_id := int(row.get("worker_id", -1))
	if worker_id < 0 or worker_id >= workers.size():
		return {}
	var worker := workers[worker_id]
	var eggs := maxi(0, int(row.get("eggs", 0)))
	var sound := maxi(0, int(row.get("sound", 0)))
	var cracked := maxi(0, int(row.get("cracked", 0)))
	var golden := maxi(0, int(row.get("golden", 0)))
	var rank := maxi(1, int(row.get("rank", 1)))
	var credit_cents := maxi(0, int(row.get("credit_cents", 0)))
	var headline := "TODAY'S MODEL EMPLOYEE"
	var body := (
		"With every tray empty, employee number made %s #1. The ranking remained decisive."
		% worker.display_name
		if eggs == 0 else
		"%s finished #1 with $%.2f in credited output. The farmer praised the system that happened to contain her."
		% [worker.display_name, float(credit_cents) / 100.0]
	)
	var tone := &"quality"
	match highlight_type:
		&"pressure_exception":
			headline = "STRETCH CLUTCH EXCEPTION"
			body = "Management filed a stretch clutch for %s; she closed with %d cracked %s. The policy remains motivational." % [
				worker.display_name,
				cracked,
				"egg" if cracked == 1 else "eggs",
			]
			tone = &"danger"
		&"golden_deliverable":
			headline = "GOLDEN DELIVERABLE"
			body = "%s laid %d golden %s. The farmer congratulated management before collecting %s." % [
				worker.display_name,
				golden,
				"egg" if golden == 1 else "eggs",
				"it" if golden == 1 else "them",
			]
			tone = &"gold"
		&"strain_notice":
			headline = "RESILIENCE OPPORTUNITY"
			body = "%s closed at trust %d, grievance %d, and stress %d. HR converted the warning into an opportunity." % [
				worker.display_name,
				roundi(worker.manager_trust),
				roundi(worker.grievance),
				roundi(worker.stress),
			]
			tone = &"care"
		&"invisible_labor":
			headline = "INVISIBLE CLUTCH"
			body = "%s matched the flock's output pace and still finished #%d. The ledger calls that calibration." % [
				worker.display_name,
				rank,
			]
			tone = &"neutral"
	var metric := "%d EGGS  //  %d SOUND  //  %d CRACKED" % [eggs, sound, cracked]
	if golden > 0:
		metric += "  //  %d GOLDEN" % golden
	metric += "  //  $%.2f CREDIT" % (float(credit_cents) / 100.0)
	return {
		"version": 1,
		"type": String(highlight_type),
		"day": completed_day,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"career_title": worker.career_title(),
		"relationship_label": worker.relationship_label(),
		"rank": rank,
		"eggs": eggs,
		"sound": sound,
		"cracked": cracked,
		"golden": golden,
		"credit_cents": credit_cents,
		"morale": roundi(worker.morale),
		"stress": roundi(worker.stress),
		"fatigue": roundi(worker.fatigue),
		"manager_trust": roundi(worker.manager_trust),
		"grievance": roundi(worker.grievance),
		"personnel_action_id": (
			String(worker.last_personnel_action)
			if worker.last_personnel_action_day == completed_day else
			""
		),
		"headline": headline,
		"body": body,
		"metric": metric,
		"tone": String(tone),
	}


func _apply_wage_arrears_consequences() -> void:
	for worker in workers:
		if not worker.employed:
			continue
		worker.morale = maxf(0.0, worker.morale - 8.0)
		worker.manager_trust = maxf(0.0, worker.manager_trust - 10.0)
		worker.grievance = minf(100.0, worker.grievance + 14.0)
	solidarity = minf(100.0, solidarity + 8.0)


func _format_time(total_minutes: int) -> String:
	var hours := total_minutes / 60
	var minutes := total_minutes % 60
	var suffix := "AM" if hours < 12 else "PM"
	var display_hour := hours % 12
	if display_hour == 0:
		display_hour = 12
	return "%d:%02d %s" % [display_hour, minutes, suffix]
