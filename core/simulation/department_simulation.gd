class_name DepartmentSimulation
extends RefCounted

var cost_probe := preload("res://core/simulation/runtime_cost_probe.gd").new()

const FeedProcurementStateScript := preload("res://core/simulation/feed_procurement_state.gd")
const HarvestCreditStateScript := preload("res://core/simulation/harvest_credit_state.gd")
const FarmgateDispatchStateScript := preload("res://core/simulation/farmgate_dispatch_state.gd")
const CampusPortfolioStateScript := preload("res://core/simulation/campus_portfolio_state.gd")
const FarmTreasuryStateScript := preload("res://core/simulation/farm_treasury_state.gd")
const InternshipProgramStateScript := preload("res://core/simulation/internship_program_state.gd")
const ComplicityLedgerScript := preload("res://core/experience/complicity_ledger.gd")

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
signal pair_reward_earned(receipt: Dictionary)
signal feed_party_funded()
signal upgrade_purchased(upgrade_id: StringName, level: int, cost_cents: int)
signal quality_streak_changed(streak: int, best_streak: int)
signal workday_completed(report: Dictionary)
signal decision_requested(decision: Dictionary)
signal decision_resolved(result: Dictionary)
signal personnel_action_resolved(result: Dictionary)
signal manager_action_resolved(result: Dictionary)
signal internship_action_resolved(result: Dictionary)
signal peck_assist_resolved(result: Dictionary)
signal peck_assist_missed(worker_id: int, claim_id: int)
signal routing_momentum_broken(receipt: Dictionary)
signal routing_momentum_recovered(receipt: Dictionary)
signal staffing_action_resolved(result: Dictionary)
signal career_sponsorship_resolved(result: Dictionary)
signal office_capacity_changed(capacity: int, cost_cents: int)
signal facility_purchased(facility_id: StringName, level: int, cost_cents: int)
signal first_clutch_reinvestment_resolved(result: Dictionary)
signal market_contract_signed(result: Dictionary)
signal market_contract_declined(result: Dictionary)
signal market_contract_settled(result: Dictionary)
signal farmer_relations_campaign_resolved(result: Dictionary)
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
const BASE_CLAIM_CAPACITY := 18
const CLAIM_CAPACITY_PER_RECORDS_LEVEL := 6
const BASE_WORK_PROGRESS := 3.2
const MAX_UPGRADE_LEVEL := 5
const SAVE_STATE_VERSION := 30
const ECONOMIC_WATCH_ORDER: Array[StringName] = [
	&"auto",
	&"margin",
	&"feed",
	&"capacity",
	&"welfare",
	&"market",
]
const MANAGER_ROSTER_VERSION := 1
const FIRST_CLUTCH_REINVESTMENT_VERSION := 1
const FIRST_CLUTCH_WORKER_ID := 0
const FIRST_CLUTCH_REINVESTMENT_OFFER_LIMIT := 2
const ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS := 1800
const FIRST_CLUTCH_BANK_CHOICE_ID: StringName = &"bank_fund"
const MINIMUM_STAFF_COUNT := 3
const MAXIMUM_STAFF_CAPACITY := 6
const PROBATION_CAMPAIGN_SHIFTS := 5
const GOLDEN_DOSSIER_FALLBACK_SHIFT := 3
const FLOCK_RESTRUCTURING_SHIFT := 4
const PECK_ASSIST_LIMIT := 3
const PECK_ASSIST_WINDOW_START := 28.0
const PECK_ASSIST_WINDOW_END := 88.0
const PECK_ASSIST_IDEAL_PROGRESS := 62.0
const PECK_ASSIST_GOLD_START := 58.0
const PECK_ASSIST_GOLD_END := 66.0
const ROUTING_MOMENTUM_PACE_MILESTONE := 2
const ROUTING_MOMENTUM_PECK_MILESTONE := 3
const ROUTING_MOMENTUM_GOLDEN_MILESTONE := 5
const ROUTING_MOMENTUM_CELEBRATION_MILESTONE := 10
const ROUTING_MOMENTUM_MASTERY_INTERVAL := 5
const ROUTING_MOMENTUM_PACE_MULTIPLIER := 1.15
## Clock-driven snapshots publish several large planning projections that do not
## need to be rebuilt at the authoritative tick rate. Keep their visible age
## below two seconds while direct actions and explicit snapshot() reads remain
## exact. This removes repeated facility/campus quote construction from the
## accelerated simulation hot path without changing saved or economic state.
const RUNTIME_PROJECTION_REFRESH_MSEC := 2_000
const PECK_ASSIST_TIMING_PROFILES := {
	&"standard": {"window_start": 28.0, "window_end": 88.0},
	&"lenient": {"window_start": 22.0, "window_end": 92.0},
	&"extended": {"window_start": 15.0, "window_end": 96.0},
}
const BASE_FEED_COST_CENTS := 600
const FEED_COST_PER_ACTIVE_HEN_CENTS := 200
const FACILITY_COST_PER_EXPANDED_SEAT_CENTS := 200
const CAREER_SPONSORSHIP_COST_CENTS := 1200
const LEGACY_FULL_ROSTER_FEED_CENTS := 1800
const CAPACITY_UPGRADE_COSTS := {
	4: 2500,
	5: 5500,
}
const PACKING_ANNEX_ID: StringName = &"farmer_brand_packing_annex"
const RECORDS_ANNEX_ID: StringName = &"records_annex"
const FARM_MUTUAL_SERVICE_COOP_ID: StringName = &"farm_mutual_service_coop"
const FARM_MUTUAL_NEGOTIATION_ROOM_ID: StringName = &"farm_mutual_negotiation_room"
const WELLNESS_NEST_ID: StringName = &"wellness_nest_room"
const TRAINING_ROOST_ID: StringName = &"training_roost"
const ROOSTER_OPERATIONS_OFFICE_ID: StringName = &"rooster_operations_office"
const IT_COOP_ID: StringName = &"it_coop"
const FLOCK_RELATIONS_OFFICE_ID: StringName = &"flock_relations_office"
const FEED_PROCUREMENT_COOP_ID: StringName = &"feed_procurement_coop"
const FARMER_RELATIONS_GALLERY_ID: StringName = &"farmer_relations_gallery"
const FARMGATE_DISPATCH_DEPOT_ID: StringName = &"farmgate_dispatch_depot"
const FARMGATE_DISPATCH_LEVEL_COSTS_CENTS: Array[int] = [12_000, 20_000, 32_000]
const FARMGATE_DISPATCH_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 700, 1_300, 2_200]
const FARMGATE_DISPATCH_UNLOCK_DAYS: Array[int] = [6, 10, 14]
const FARMGATE_DISPATCH_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const FARMGATE_DISPATCH_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const FARMGATE_DISPATCH_PACKING_LEVEL_REQUIREMENTS: Array[int] = [1, 2, 3]
const FARMGATE_DISPATCH_GALLERY_LEVEL_REQUIREMENTS: Array[int] = [1, 2, 3]
const FARMGATE_DISPATCH_STANDING_REQUIREMENTS: Array[int] = [5, 12, 25]
const FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS: Array[int] = [0, 12, 24, 42]
const FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS: Array[int] = [0, 8, 16, 24]
const FARMGATE_DISPATCH_SHELF_LIFE_SHIFTS: Array[int] = [0, 2, 3, 4]
const FARMGATE_COMMISSIONING_HISTORY_LIMIT := 32
const CAMPUS_EXPANSION_SAVE_VERSION := 1
const CAMPUS_EXPANSION_UNLOCK_DAY := 1
const CAMPUS_EXPANSION_STANDING_REQUIREMENT := 2
const CAMPUS_EXPANSION_HISTORY_LIMIT := 64
const CAMPUS_PARCEL_ID: StringName = &"north_meadow"
const CAMPUS_MODULE_ID: StringName = &"egg_routing_pod"
const CAMPUS_CLAIM_CAPACITY_BONUS := 6
const CAMPUS_FARMGATE_STORAGE_BONUS_EGGS := 6
const CAMPUS_FARMGATE_MAX_STORAGE_EGGS := 48
const CAMPUS_PARCEL_DEFINITIONS := {
	CAMPUS_PARCEL_ID: {
		"name": "NORTH MEADOW PARCEL",
		"capital_cost_cents": 8_500,
		"daily_cost_cents": 300,
	},
}
const CAMPUS_SERVICE_ORDER: Array[StringName] = [&"circulation", &"power", &"cold_chain"]
const CAMPUS_SERVICE_DEFINITIONS := {
	&"circulation": {
		"name": "MEADOW CIRCULATION LINK",
		"capital_cost_cents": 2_800,
		"daily_cost_cents": 150,
		"required_for_pod": true,
	},
	&"power": {
		"name": "MEADOW POWER DROP",
		"capital_cost_cents": 3_500,
		"daily_cost_cents": 225,
		"required_for_pod": true,
	},
	&"cold_chain": {
		"name": "MEADOW COLD-CHAIN LOOP",
		"capital_cost_cents": 6_000,
		"daily_cost_cents": 400,
		"required_for_pod": false,
	},
}
const CAMPUS_SOCKET_ORDER: Array[StringName] = [&"meadow_west", &"meadow_east", &"service_spine"]
const CAMPUS_SOCKET_DEFINITIONS := {
	&"meadow_west": {
		"name": "MEADOW WEST SOCKET",
		"route_blocked": false,
		"blocked_reason": "",
	},
	&"meadow_east": {
		"name": "MEADOW EAST SOCKET",
		"route_blocked": false,
		"blocked_reason": "",
	},
	&"service_spine": {
		"name": "SERVICE SPINE SOCKET",
		"route_blocked": true,
		"blocked_reason": "The Service Spine is reserved for the flock circulation route.",
	},
}
const CAMPUS_MODULE_DEFINITIONS := {
	CAMPUS_MODULE_ID: {
		"name": "EGG ROUTING POD",
		"capital_cost_cents": 7_500,
		"relocation_cost_cents": 1_800,
		"daily_cost_cents": 500,
	},
}
const CAMPUS_EXPANSION_SAVE_KEYS: Array[String] = [
	"version", "parcel_owned", "services", "pod_owned", "pod_socket_id",
	"capital_spend_total_cents", "next_receipt_id", "last_receipt", "history",
]
const CAMPUS_EXPANSION_RECEIPT_KEYS: Array[String] = [
	"accepted", "receipt_id", "day", "action_id", "item_id", "socket_id",
	"from_socket_id", "cost_cents", "added_daily_cost_cents", "fund_before_cents",
	"fund_after_cents", "daily_cost_before_cents", "daily_cost_after_cents",
	"claim_capacity_bonus_before", "claim_capacity_bonus_after",
	"farmgate_capacity_bonus_before", "farmgate_capacity_bonus_after",
	"access_gate_id", "access_standing_points", "access_farmgate_level", "reason", "outcome",
]
const FACILITY_PURCHASE_RECEIPT_KEYS: Array[String] = [
	"accepted", "action_id", "facility_id", "facility_name", "level_name", "day",
	"purchased_level", "max_level", "cost_cents", "fund_before_cents", "fund_after_cents",
	"spendable_before_cents", "spendable_after_cents", "protected_reserve_before_cents",
	"protected_reserve_after_cents", "upkeep_before_cents", "upkeep_after_cents",
	"upkeep_delta_cents", "effect",
]
const FACILITY_PURCHASE_EFFECT_KEYS: Array[String] = [
	"benefits", "tradeoffs", "storage_capacity_eggs", "dispatch_capacity_eggs",
	"shelf_life_shifts",
]
const WELLNESS_NEST_LEVEL_COSTS_CENTS: Array[int] = [7000, 11500, 17500]
const WELLNESS_NEST_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 500, 900, 1400]
const WELLNESS_NEST_UNLOCK_DAYS: Array[int] = [3, 6, 9]
const WELLNESS_NEST_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const WELLNESS_NEST_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const WELLNESS_STRAIN_GAIN_BASIS_POINTS: Array[int] = [10000, 9200, 8400, 7600]
const WELLNESS_BREAK_RECOVERY_BASIS_POINTS: Array[int] = [10000, 11500, 13000, 15000]
const WELLNESS_BREAK_MORALE_MILLIPOINTS: Array[int] = [0, 100, 160, 250]
const WELLNESS_OVERNIGHT_FATIGUE_RECOVERY_MILLIPOINTS: Array[int] = [24000, 27000, 30000, 34000]
const WELLNESS_OVERNIGHT_STRESS_RECOVERY_MILLIPOINTS: Array[int] = [10000, 12000, 14000, 17000]
const TRAINING_ROOST_LEVEL_COSTS_CENTS: Array[int] = [8500, 13500, 21000]
const TRAINING_ROOST_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 600, 1000, 1600]
const TRAINING_ROOST_UNLOCK_DAYS: Array[int] = [4, 7, 10]
const TRAINING_ROOST_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const TRAINING_ROOST_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const TRAINING_ROOST_CAREER_LEVEL_REQUIREMENTS: Array[int] = [1, 2, 3]
const TRAINING_SPONSORSHIP_COSTS_CENTS: Array[int] = [1200, 1000, 800, 600]
const TRAINING_WORK_BASIS_POINTS: Array[int] = [8500, 9000, 9500, 10000]
const TRAINING_COACHING_XP_BONUS: Array[int] = [0, 2, 4, 6]
const ROOSTER_OPERATIONS_LEVEL_COSTS_CENTS: Array[int] = [10000, 16000, 24000]
const ROOSTER_OPERATIONS_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 400, 700, 1100]
const ROOSTER_OPERATIONS_UNLOCK_DAYS: Array[int] = [5, 8, 11]
const ROOSTER_OPERATIONS_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const ROOSTER_OPERATIONS_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const ROOSTER_PERSONNEL_ACTION_LIMITS: Array[int] = [1, 2, 3, 4]
const ROOSTER_SUPERVISOR_PAYROLL_CENTS: Array[int] = [0, 500, 800, 1200]
const ROOSTER_SURVEILLANCE_GRIEVANCE_MILLIPOINTS: Array[int] = [0, 750, 1250, 2000]
const ROOSTER_SURVEILLANCE_STRESS_MILLIPOINTS: Array[int] = [0, 500, 1000, 1500]
const ROOSTER_SURVEILLANCE_SOLIDARITY_MILLIPOINTS: Array[int] = [0, 500, 1000, 1500]
const MANAGER_SLOT_SALARIES_CENTS: Array[int] = [0, 500, 300, 400]
const MANAGER_DEFAULT_HIRE_ORDER: Array[StringName] = [
	&"cornelius_credit", &"bramwell_quota", &"prudence_compliance", &"clover_culture",
]
const MANAGER_ASSIGNMENT_ORDER: Array[StringName] = [
	&"whole_flock", &"front_row", &"back_row", &"auto_desk", &"at_risk",
]
const MANAGER_ASSIGNMENT_DEFINITIONS := {
	&"whole_flock": {"label": "WHOLE FLOCK", "summary": "Every employed hen receives the directive."},
	&"front_row": {"label": "FRONT ROOST", "summary": "Desks 1-3 receive the directive."},
	&"back_row": {"label": "BACK ROOST", "summary": "Desks 4-6 receive the directive."},
	&"auto_desk": {"label": "AUTO DESK", "summary": "Only hens enrolled in AUTO receive the directive."},
	&"at_risk": {"label": "AT-RISK FILE", "summary": "The most stressed employed hen receives the directive."},
}
const MANAGER_POSTURE_ORDER: Array[StringName] = [
	&"coach", &"protect_quality", &"chase_quota", &"audit", &"visibility", &"meetings",
]
const MANAGER_POSTURE_DEFINITIONS := {
	&"coach": {"label": "COACH THE FLOCK", "work_bp": 200, "crack_bp": -150, "stress": -1.0, "trust": 1.5, "grievance": -0.5, "meeting_minutes": 10},
	&"protect_quality": {"label": "PROTECT SHELLS", "work_bp": -250, "crack_bp": -350, "stress": -0.5, "trust": 0.5, "grievance": 0.0, "meeting_minutes": 5},
	&"chase_quota": {"label": "CHASE QUOTA", "work_bp": 700, "crack_bp": 250, "stress": 2.0, "trust": -1.0, "grievance": 1.5, "meeting_minutes": 5},
	&"audit": {"label": "PREPARE AUDIT", "work_bp": -150, "crack_bp": -100, "stress": 1.0, "trust": -0.5, "grievance": 0.5, "meeting_minutes": 15},
	&"visibility": {"label": "PROMOTE VISIBILITY", "work_bp": -100, "crack_bp": 0, "stress": 0.5, "trust": -0.5, "grievance": 0.5, "meeting_minutes": 15},
	&"meetings": {"label": "ALIGNMENT MEETINGS", "work_bp": -500, "crack_bp": -50, "stress": 1.5, "trust": -0.5, "grievance": 1.0, "meeting_minutes": 30},
}
const MANAGER_CANDIDATE_DEFINITIONS := {
	&"cornelius_credit": {"name": "Cornelius Claimwell", "archetype": "CREDIT", "doctrine": "The flock produces; management presents.", "default_posture": &"visibility", "color": "343941", "accessory": &"BowTie", "signing_cost_cents": 0},
	&"bramwell_quota": {"name": "Bramwell Beakley", "archetype": "QUOTA", "doctrine": "Every clutch can become a stretch clutch.", "default_posture": &"chase_quota", "color": "5b3432", "accessory": &"AccessoryNeck_LongTie", "signing_cost_cents": 4000},
	&"prudence_compliance": {"name": "Prudence Peckworth", "archetype": "COMPLIANCE", "doctrine": "If it is not filed, it did not happen.", "default_posture": &"audit", "color": "344c49", "accessory": &"AccessoryHead_SquareGlasses", "signing_cost_cents": 5200},
	&"clover_culture": {"name": "Clover Crowsby", "archetype": "CULTURE", "doctrine": "Mandatory warmth is still warmth.", "default_posture": &"meetings", "color": "62513b", "accessory": &"AccessoryBody_SweaterVest", "signing_cost_cents": 6000},
	&"pivot_reorg": {"name": "Pivot Strutters", "archetype": "REORG", "doctrine": "A new chart is evidence of motion.", "default_posture": &"coach", "color": "493c5d", "accessory": &"AccessoryNeck_Lanyard", "signing_cost_cents": 4800},
	&"byte_automation": {"name": "Byte Bantam", "archetype": "AUTOMATION", "doctrine": "The spreadsheet is the coop.", "default_posture": &"audit", "color": "30465d", "accessory": &"AccessoryHead_Headset", "signing_cost_cents": 7000},
}
const MANAGER_RANK_TITLES: Array[String] = [
	"ACTING LEAD", "ASSISTANT ROOST SUPERVISOR", "SENIOR CLUTCH MANAGER",
	"EXECUTIVE VICE ROOSTER", "CHIEF EGG OFFICER",
]
const MANAGER_RANK_INFLUENCE: Array[int] = [0, 25, 60, 120, 220]
const IT_COOP_LEVEL_COSTS_CENTS: Array[int] = [13000, 20000, 30000]
const IT_COOP_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 1000, 1700, 2600]
const IT_COOP_UNLOCK_DAYS: Array[int] = [6, 9, 12]
const IT_COOP_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const IT_COOP_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const IT_AUTO_WORK_BASIS_POINTS: Array[int] = [10000, 10300, 10600, 11000]
const IT_AUTO_SPECIALTY_GRACE_MINUTES: Array[int] = [180, 150, 120, 60]
const IT_COMPLIANCE_EXPOSURE_MILLIPOINTS: Array[int] = [0, 1000, 1800, 2800]
const IT_LEDGER_PATCH_COSTS_CENTS: Array[int] = [1800, 2200, 2600, 3000]
const IT_SPREADSHEET_COMPLIANCE_LOSS_MILLIPOINTS: Array[int] = [6000, 8000, 10000, 12000]
const IT_SPREADSHEET_CRACK_BASIS_POINTS: Array[int] = [600, 750, 900, 1050]
const FLOCK_RELATIONS_LEVEL_COSTS_CENTS: Array[int] = [11_000, 17_500, 26_000]
const FLOCK_RELATIONS_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 500, 900, 1500]
const FLOCK_RELATIONS_UNLOCK_DAYS: Array[int] = [7, 10, 13]
const FLOCK_RELATIONS_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const FLOCK_RELATIONS_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const FLOCK_RELATIONS_CASE_CAPACITY: Array[int] = [0, 1, 2, 3]
const FLOCK_RELATIONS_RESOLUTION_LIMITS: Array[int] = [0, 1, 2, 3]
const FLOCK_RELATIONS_CASE_RISK_THRESHOLD := 160
const FLOCK_RELATIONS_HISTORY_LIMIT := 32
const FEED_PROCUREMENT_LEVEL_COSTS_CENTS: Array[int] = [8_000, 14_000, 22_000]
const FEED_PROCUREMENT_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 400, 800, 1_300]
const FEED_PROCUREMENT_UNLOCK_DAYS: Array[int] = [4, 8, 12]
const FEED_PROCUREMENT_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const FEED_PROCUREMENT_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const FEED_PROCUREMENT_CAPACITY_SCOOPS: Array[int] = [0, 18, 36, 54]
const FEED_BASE_SPOT_UNIT_PRICE_CENTS := 200
const FEED_CHARTER_LENGTH_SHIFTS := 3
const FEED_PROCUREMENT_ORDER_LIMIT := 1
const FARMER_RELATIONS_GALLERY_LEVEL_COSTS_CENTS: Array[int] = [9_000, 15_000, 24_000]
const FARMER_RELATIONS_GALLERY_MAINTENANCE_BY_LEVEL_CENTS: Array[int] = [0, 500, 900, 1_500]
const FARMER_RELATIONS_GALLERY_UNLOCK_DAYS: Array[int] = [5, 9, 13]
const FARMER_RELATIONS_GALLERY_OFFICE_CAPACITY_REQUIREMENTS: Array[int] = [4, 5, 6]
const FARMER_RELATIONS_GALLERY_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const FEED_PROCUREMENT_OFFER_ORDER: Array[StringName] = [
	&"local_whole_grain",
	&"inspirational_bulk_mash",
	&"fixed_future_reserve",
]
const FEED_PROCUREMENT_OFFER_DEFINITIONS := {
	&"local_whole_grain": {
		"label": "LOCAL WHOLE GRAIN",
		"description": "Buy one shift of traceable local grain. It costs more, keeps briefly, and leaves the flock visibly better fed.",
		"required_level": 1,
		"quantity_multiplier": 1,
		"unit_price_basis_points": 12_500,
		"shelf_shifts": 2,
		"strain_basis_points": 9_200,
		"morale_delta": 2,
		"grievance_delta": 0,
	},
	&"inspirational_bulk_mash": {
		"label": "INSPIRATIONAL BULK MASH",
		"description": "Buy three shifts at a discount. The mash lasts longer, though the motivational branding does more for management than digestion.",
		"required_level": 2,
		"quantity_multiplier": 3,
		"unit_price_basis_points": 8_500,
		"shelf_shifts": 3,
		"strain_basis_points": 10_500,
		"morale_delta": 0,
		"grievance_delta": 1,
	},
	&"fixed_future_reserve": {
		"label": "FIXED FUTURE RESERVE",
		"description": "Prepay four shifts at today's seasonal quote. The reserve is neutral feed, but it turns tomorrow's price into today's planning decision.",
		"required_level": 3,
		"quantity_multiplier": 4,
		"unit_price_basis_points": 10_000,
		"shelf_shifts": 4,
		"strain_basis_points": 10_000,
		"morale_delta": 0,
		"grievance_delta": 0,
	},
}
const FLOCK_RELATIONS_ACTION_ORDER: Array[StringName] = [
	&"fund_remedy",
	&"mediate",
	&"file_pip",
	&"binding_arbitration",
]
const FLOCK_RELATIONS_CASE_TYPES: Array[StringName] = [
	&"pay_dispute",
	&"automation_appeal",
	&"surveillance_grievance",
	&"burnout_case",
	&"credit_claim",
	&"workplace_grievance",
]
const FLOCK_RELATIONS_ACTION_DEFINITIONS := {
	&"fund_remedy": {
		"label": "FUND REMEDY",
		"required_level": 1,
		"effect_preview": "Trust +12, grievance -16, stress -8, compliance +4, farmer favor -2.",
	},
	&"mediate": {
		"label": "MEDIATE",
		"required_level": 2,
		"effect_preview": "Trust +7, grievance -9, stress -4, compliance +2, farmer favor -1.",
	},
	&"file_pip": {
		"label": "FILE PIP",
		"required_level": 1,
		"effect_preview": "Trust -10, grievance +14, stress +8, compliance -3, solidarity +4, farmer favor +3.",
	},
	&"binding_arbitration": {
		"label": "BINDING ARBITRATION",
		"required_level": 3,
		"effect_preview": "Trust -3, grievance -5, stress -3, compliance +6, solidarity +2, farmer favor +1.",
	},
}
const PACKING_CARTON_SIZE := 6
const PACKING_VALUE_BONUS_PER_LEVEL := 0.04
const PACKING_CARTON_BONUS_PER_LEVEL_CENTS := 300
const CONTRACT_BOARD_UNLOCK_DAY := 3
const MARKET_CONTRACT_MAX_CLAIMS := 7
const MARKET_STANDING_SUCCESS_POINTS := 2
const MARKET_STANDING_BREACH_POINTS := 1
const SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL := 5000
const SERVICE_COOP_LEVEL_STANDING_REQUIREMENTS: Array[int] = [2, 6, 12]
const SERVICE_COOP_LEVEL_CLAIM_CAPACITY_REQUIREMENTS: Array[int] = [24, 30, 36]
const SERVICE_COOP_LEVEL_ACTIVE_STAFF_REQUIREMENTS: Array[int] = [4, 5, 6]
const NEGOTIATION_ROOM_UNLOCK_DAY := 6
const NEGOTIATION_ROOM_REQUIRED_STANDING := 12
const NEGOTIATION_ROOM_REQUIRED_SERVICE_COOP_LEVEL := 3
const MARKET_SEASON_FIRST_DAY := 6
const MARKET_SEASON_LENGTH_DAYS := 3
const MARKET_SEASONS_PER_YEAR := 4
const RESTED_FLOCK_WELFARE_MINIMUM := 72
const MARKET_PRICING_EXECUTIVE_REACH_REQUIREMENT := 3
const MARKET_PRICING_EXECUTIVE_SATISFACTION_MINIMUM := 50
const MARKET_PRICING_ESTIMATED_HANDLING_COST_CENTS := 125
const MARKET_PRICING_PROFILE_ORDER: Array[StringName] = [
	&"mutual_rate",
	&"community_access_rate",
	&"executive_select_rate",
]
const MARKET_PRICING_OUTCOME_KEYS: Array[String] = [
	"mutual_rate_success",
	"mutual_rate_breach",
	"community_access_rate_success",
	"community_access_rate_breach",
	"executive_select_rate_success",
	"executive_select_rate_breach",
]
const MARKET_PRICING_PROFILE_DEFINITIONS := {
	&"mutual_rate": {
		"label": "MUTUAL RATE",
		"summary": "Keep the quoted premium and standard folder volume.",
		"premium_basis_points": 0,
		"volume_delta": 0,
		"required_delta": 0,
		"satisfaction_success_delta": 1,
		"satisfaction_breach_delta": -3,
		"reach_success_delta": 1,
		"reach_breach_delta": -1,
		"required_reach": 0,
		"required_satisfaction": 0,
	},
	&"community_access_rate": {
		"label": "COMMUNITY ACCESS RATE",
		"summary": "Quote 20% less, accept one referred folder, and earn stronger claimant goodwill when fulfilled.",
		"premium_basis_points": -2000,
		"volume_delta": 1,
		"required_delta": 1,
		"satisfaction_success_delta": 4,
		"satisfaction_breach_delta": -5,
		"reach_success_delta": 3,
		"reach_breach_delta": -2,
		"required_reach": 0,
		"required_satisfaction": 0,
	},
	&"executive_select_rate": {
		"label": "EXECUTIVE SELECT RATE",
		"summary": "Quote 30% more and serve one fewer folder, but spend claimant goodwill that must be rebuilt.",
		"premium_basis_points": 3000,
		"volume_delta": -1,
		"required_delta": -1,
		"satisfaction_success_delta": -2,
		"satisfaction_breach_delta": -6,
		"reach_success_delta": 0,
		"reach_breach_delta": -3,
		"required_reach": MARKET_PRICING_EXECUTIVE_REACH_REQUIREMENT,
		"required_satisfaction": MARKET_PRICING_EXECUTIVE_SATISFACTION_MINIMUM,
	},
}
const MARKET_CONTRACT_CLAUSE_ORDER: Array[StringName] = [
	&"standard_terms",
	&"expedited_hatch_rider",
	&"specialist_roost_endorsement",
	&"rested_flock_warranty",
]
const MARKET_CONTRACT_CLAUSE_DEFINITIONS := {
	&"standard_terms": {
		"label": "STANDARD TERMS",
		"summary": "Keep Farm Mutual's seasonal binder exactly as quoted.",
		"category": &"standard",
		"requires_negotiation_room": false,
		"premium_basis_points": 0,
		"breach_basis_points": 0,
	},
	&"expedited_hatch_rider": {
		"label": "EXPEDITED HATCH RIDER",
		"summary": "Tighten every service window by one hour and mark one additional late-arriving standard folder as rush work.",
		"category": &"schedule",
		"requires_negotiation_room": true,
		"premium_basis_points": 2500,
		"breach_basis_points": 5000,
	},
	&"specialist_roost_endorsement": {
		"label": "SPECIALIST ROOST ENDORSEMENT",
		"summary": "Convert every folder to this binder's authored dominant file tray.",
		"category": &"routing",
		"requires_negotiation_room": true,
		"premium_basis_points": 3500,
		"breach_basis_points": 2500,
	},
	&"rested_flock_warranty": {
		"label": "RESTED FLOCK WARRANTY",
		"summary": "Earn a richer binder only if the flock also closes with welfare at 72 or above.",
		"category": &"welfare",
		"requires_negotiation_room": true,
		"premium_basis_points": 4000,
		"breach_basis_points": 4000,
	},
}
const MARKET_SEASON_DEFINITIONS := [
	{
		"id": &"spring_hatch_surge",
		"label": "SPRING HATCH SURGE",
		"short_label": "SPRING SURGE",
		"summary": "Nest-damage demand rises as fresh hatches strain the Mutual's routine-loss book.",
		"lane_demand_basis_points": {
			"nest_damage": 2000,
			"predator_loss": 0,
			"appeals": -1000,
		},
	},
	{
		"id": &"summer_predator_migration",
		"label": "SUMMER PREDATOR MIGRATION",
		"short_label": "PREDATOR SEASON",
		"summary": "Fox and hawk migration pushes predator-loss folders to the front of the underwriting queue.",
		"lane_demand_basis_points": {
			"nest_damage": -500,
			"predator_loss": 2500,
			"appeals": 500,
		},
	},
	{
		"id": &"autumn_retention_audit",
		"label": "AUTUMN RETENTION AUDIT",
		"short_label": "RETENTION AUDIT",
		"summary": "Appeal-heavy renewals command the richest seasonal demand before the winter book closes.",
		"lane_demand_basis_points": {
			"nest_damage": -1000,
			"predator_loss": 500,
			"appeals": 3000,
		},
	},
	{
		"id": &"winter_feed_fund_squeeze",
		"label": "WINTER FEED-FUND SQUEEZE",
		"short_label": "FEED-FUND SQUEEZE",
		"summary": "Every lane becomes dearer while winter feed pressure tightens Farm Mutual reserves.",
		"lane_demand_basis_points": {
			"nest_damage": 1000,
			"predator_loss": 1000,
			"appeals": 1000,
		},
	},
]
const MARKET_CONTRACT_OFFER_ORDER: Array[StringName] = [
	&"homestead_stability_binder",
	&"predator_watch_pool",
	&"exceptions_retention_covenant",
]
const MARKET_CONTRACT_DEFINITIONS := {
	&"homestead_stability_binder": {
		"name": "HOMESTEAD STABILITY BINDER",
		"short_name": "HOMESTEAD BINDER",
		"client": "LOW FENCE FARM MUTUAL",
		"tagline": "Routine nesting losses, bundled until they stop feeling routine.",
		"required_claim_capacity": 18,
		"required_active_staff": 4,
		"required_deliveries": 4,
		"service_window_minutes": 120,
		"premium_cents": 1000,
		"breach_cents": 500,
		"arrival_batches": [
			{
				"minute_of_day": 9 * 60,
				"lanes": [&"nest_damage", &"nest_damage", &"nest_damage", &"predator_loss"],
				"rush": false,
			},
			{
				"minute_of_day": 11 * 60,
				"lanes": [&"nest_damage"],
				"rush": true,
			},
		],
		"tone": &"quality",
	},
	&"predator_watch_pool": {
		"name": "PREDATOR WATCH POOL",
		"short_name": "PREDATOR POOL",
		"client": "RED COMB AGRICULTURAL",
		"tagline": "High-strain fox and hawk files with a punctuality clause.",
		"required_claim_capacity": 24,
		"required_active_staff": 5,
		"required_deliveries": 5,
		"service_window_minutes": 180,
		"premium_cents": 1600,
		"breach_cents": 800,
		"arrival_batches": [
			{
				"minute_of_day": 9 * 60,
				"lanes": [&"predator_loss", &"predator_loss", &"nest_damage", &"predator_loss"],
				"rush": false,
			},
			{
				"minute_of_day": 12 * 60,
				"lanes": [&"predator_loss", &"predator_loss"],
				"rush": true,
			},
		],
		"tone": &"pressure",
	},
	&"exceptions_retention_covenant": {
		"name": "EXCEPTIONS RETENTION COVENANT",
		"short_name": "EXCEPTIONS COVENANT",
		"client": "GILT NEST UNDERWRITERS",
		"tagline": "Appeals-heavy premium work whose fine print also has fine print.",
		"required_claim_capacity": 30,
		"required_active_staff": 6,
		"required_deliveries": 5,
		"service_window_minutes": 240,
		"premium_cents": 2400,
		"breach_cents": 1200,
		"arrival_batches": [
			{
				"minute_of_day": 9 * 60,
				"lanes": [&"appeals", &"appeals", &"predator_loss", &"nest_damage"],
				"rush": false,
			},
			{
				"minute_of_day": 13 * 60,
				"lanes": [&"appeals", &"appeals"],
				"rush": true,
			},
		],
		"tone": &"danger",
	},
}
const V14_FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
]
const V15_FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
]
const V16_FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
]
const V17_FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
	FLOCK_RELATIONS_OFFICE_ID,
]
const V18_FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
	FLOCK_RELATIONS_OFFICE_ID,
	FEED_PROCUREMENT_COOP_ID,
]
const V19_FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
	FLOCK_RELATIONS_OFFICE_ID,
	FEED_PROCUREMENT_COOP_ID,
	FARMER_RELATIONS_GALLERY_ID,
]
const V20_FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
	FLOCK_RELATIONS_OFFICE_ID,
	FEED_PROCUREMENT_COOP_ID,
	FARMER_RELATIONS_GALLERY_ID,
	FARMGATE_DISPATCH_DEPOT_ID,
]
const FACILITY_ORDER: Array[StringName] = [
	&"candling_rework_bay",
	PACKING_ANNEX_ID,
	RECORDS_ANNEX_ID,
	FARM_MUTUAL_SERVICE_COOP_ID,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID,
	WELLNESS_NEST_ID,
	TRAINING_ROOST_ID,
	ROOSTER_OPERATIONS_OFFICE_ID,
	IT_COOP_ID,
	FLOCK_RELATIONS_OFFICE_ID,
	FEED_PROCUREMENT_COOP_ID,
	FARMER_RELATIONS_GALLERY_ID,
	FARMGATE_DISPATCH_DEPOT_ID,
]
const FACILITY_DEFINITIONS := {
	&"candling_rework_bay": {
		"name": "CANDLING & REWORK BAY",
		"short_name": "CANDLING BAY",
		"description": "A lit shell-inspection bench and dedicated return lane for cracked files.",
		"cost_cents": 4000,
		"daily_maintenance_cents": 300,
		"max_level": 1,
		"unlock_id": &"shell_quality_checks",
		"unlock_requirement": "Complete the Shell Quality Checks milestone before commissioning this facility.",
		"crack_modifier": -0.015,
		"rework_speed_multiplier": 1.20,
		"benefits": [
			"-1.5% crack risk across the office",
			"+20% processing speed for rework files",
		],
		"tradeoffs": [
			"Adds $3.00 in maintenance to every shift",
		],
		"level_names": ["CANDLING BAY"],
	},
	PACKING_ANNEX_ID: {
		"name": "FARMER BRAND PACKING ANNEX",
		"short_name": "PACKING ANNEX",
		"description": "An external packing wing where the flock fills cartons carrying somebody else's name.",
		"level_costs_cents": [6000, 9500, 14000],
		"maintenance_by_level_cents": [0, 300, 500, 800],
		"max_level": 3,
		"unlock_day": 3,
		"unlock_requirement": "Complete two shifts to release the annex lease option.",
		"value_bonus_per_level": PACKING_VALUE_BONUS_PER_LEVEL,
		"carton_size": PACKING_CARTON_SIZE,
		"carton_bonus_per_level_cents": PACKING_CARTON_BONUS_PER_LEVEL_CENTS,
		"benefits": [
			"+4% sound and golden egg value per level",
			"Every six good eggs earns a $3.00 contract bonus per level",
		],
		"tradeoffs": [
			"Daily annex maintenance rises to $3 / $5 / $8",
			"Cracked eggs do not advance the branded carton",
		],
		"level_names": [
			"MANUAL PACKING LINE",
			"AUTOMATED SEALING",
			"PREMIUM DISPATCH",
		],
	},
	RECORDS_ANNEX_ID: {
		"name": "LAYING RECORDS ANNEX",
		"short_name": "RECORDS ANNEX",
		"description": "A rolling file roost that lets the bureau retain more incoming peckwork than the flock may be able to finish.",
		"level_costs_cents": [7000, 10500, 15500],
		"maintenance_by_level_cents": [0, 400, 700, 1100],
		"max_level": 3,
		"unlock_day": 3,
		"unlock_requirement": "Complete two shifts to release the east-parcel records lease.",
		"claim_capacity_per_level": CLAIM_CAPACITY_PER_RECORDS_LEVEL,
		"benefits": [
			"+6 live file capacity per level",
			"Retains file demand that would otherwise leave the farm",
		],
		"tradeoffs": [
			"Daily archive maintenance rises to $4 / $7 / $11",
			"More retained files can become overdue when the flock is understaffed",
		],
		"level_names": [
			"ROLLING RECORDS FLOOR",
			"PNEUMATIC TRIAGE",
			"PERMANENT RETENTION VAULT",
		],
	},
	FARM_MUTUAL_SERVICE_COOP_ID: {
		"name": "FARM MUTUAL SERVICE COOP",
		"short_name": "SERVICE COOP",
		"description": "A cumulative client-service counter where Farm Mutual converts successful binders into better-paid public confidence.",
		"level_costs_cents": [7500, 12000, 18000],
		"maintenance_by_level_cents": [0, 300, 600, 900],
		"max_level": 3,
		"unlock_day": CONTRACT_BOARD_UNLOCK_DAY,
		"unlock_requirement": "Earn Bronze Farm Mutual standing and commission the required records and staffing infrastructure.",
		"premium_basis_points_per_level": SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL,
		"standing_requirements": SERVICE_COOP_LEVEL_STANDING_REQUIREMENTS,
		"claim_capacity_requirements": SERVICE_COOP_LEVEL_CLAIM_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": SERVICE_COOP_LEVEL_ACTIVE_STAFF_REQUIREMENTS,
		"benefits": [
			"Successful Farm Mutual premiums rise by 50% of their base value per level",
			"Each cumulative tier makes the bureau's client standing physically visible",
		],
		"tradeoffs": [
			"Daily client-service upkeep rises to $3 / $6 / $9",
			"The bonus pays only when the flock fulfills the signed binder",
		],
		"level_names": [
			"BRONZE CLIENT SEAL DESK",
			"SILVER TIMED DISPATCH HUTCH",
			"GOLD ACCOUNT GALLERY",
		],
	},
	FARM_MUTUAL_NEGOTIATION_ROOM_ID: {
		"name": "FARM MUTUAL NEGOTIATION ROOM",
		"short_name": "NEGOTIATION ROOM",
		"description": "A sealed underwriting room where Gold-standing bureaus may sign one operational rider per Farm Mutual binder.",
		"cost_cents": 24000,
		"daily_maintenance_cents": 1200,
		"max_level": 1,
		"unlock_day": NEGOTIATION_ROOM_UNLOCK_DAY,
		"unlock_requirement": "Reach Day 6, retain Gold Farm Mutual standing, and commission Service Coop level 3.",
		"required_market_standing": NEGOTIATION_ROOM_REQUIRED_STANDING,
		"required_service_coop_level": NEGOTIATION_ROOM_REQUIRED_SERVICE_COOP_LEVEL,
		"benefits": [
			"Unlocks one negotiated clause per Farm Mutual binder",
			"Makes schedule, specialty, or welfare risk an explicit signed choice",
		],
		"tradeoffs": [
			"Costs $240.00 in capital and adds $12.00 daily upkeep",
			"Every negotiated advantage carries an authored premium and breach adjustment",
		],
		"level_names": ["GOLD UNDERWRITING TABLE"],
	},
	WELLNESS_NEST_ID: {
		"name": "WELLNESS NEST",
		"short_name": "WELLNESS NEST",
		"description": "A cumulative recovery suite where rested hens are measured closely enough to justify a larger clutch target.",
		"level_costs_cents": WELLNESS_NEST_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": WELLNESS_NEST_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": WELLNESS_NEST_UNLOCK_DAYS[0],
		"unlock_days": WELLNESS_NEST_UNLOCK_DAYS,
		"office_capacity_requirements": WELLNESS_NEST_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": WELLNESS_NEST_ACTIVE_STAFF_REQUIREMENTS,
		"unlock_requirement": "Reach the tier's filing day and maintain the required authorized desks and active flock.",
		"benefits": [
			"Reduces real fatigue and stress gained while pecking",
			"Improves break and overnight recovery without adding a welfare score bonus",
		],
		"tradeoffs": [
			"Daily care upkeep rises to $5 / $9 / $14",
			"Each commissioned tier adds one file to the next-shift clutch target",
		],
		"level_names": [
			"QUIET NEST CUBBIES",
			"ROTATING RECOVERY ROOM",
			"RESTED FLOCK SUITE",
		],
	},
	TRAINING_ROOST_ID: {
		"name": "TRAINING ROOST",
		"short_name": "TRAINING ROOST",
		"description": "A cumulative credentialing wing that makes development cheaper and faster while promotions raise the permanent wage bill.",
		"level_costs_cents": TRAINING_ROOST_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": TRAINING_ROOST_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": TRAINING_ROOST_UNLOCK_DAYS[0],
		"unlock_days": TRAINING_ROOST_UNLOCK_DAYS,
		"office_capacity_requirements": TRAINING_ROOST_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": TRAINING_ROOST_ACTIVE_STAFF_REQUIREMENTS,
		"career_level_requirements": TRAINING_ROOST_CAREER_LEVEL_REQUIREMENTS,
		"unlock_requirement": "Match this tier's Wellness Nest, authorized desks, active flock, and career accreditation.",
		"benefits": [
			"Reduces Career Sponsorship Feed Fund cost per tier",
			"Removes more of the pending-training work penalty and adds coaching XP",
		],
		"tradeoffs": [
			"Daily credential upkeep rises to $6 / $10 / $16",
			"Faster promotions and completed secondary credentials raise payroll",
		],
		"level_names": [
			"PRACTICE TERMINAL",
			"CROSS-LANE CLASSROOM",
			"CREDENTIAL GALLERY",
		],
	},
	ROOSTER_OPERATIONS_OFFICE_ID: {
		"name": "ROOSTER OPERATIONS OFFICE",
		"short_name": "ROOSTER OFFICE",
		"description": "A cumulative management pod that expands flock check-ins while converting every occupied desk into a visible supervision record.",
		"level_costs_cents": ROOSTER_OPERATIONS_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": ROOSTER_OPERATIONS_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": ROOSTER_OPERATIONS_UNLOCK_DAYS[0],
		"unlock_days": ROOSTER_OPERATIONS_UNLOCK_DAYS,
		"office_capacity_requirements": ROOSTER_OPERATIONS_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": ROOSTER_OPERATIONS_ACTIVE_STAFF_REQUIREMENTS,
		"unlock_requirement": "Reach the tier's filing day and maintain the required authorized desks and active flock.",
		"benefits": [
			"Adds one consequential flock check-in per tier",
			"Makes management span and daily pressure visible instead of implicit",
		],
		"tradeoffs": [
			"Supervisor payroll rises to $5 / $8 / $12 in addition to office upkeep",
			"Daily surveillance raises hen stress, grievance, and flock solidarity",
		],
		"level_names": [
			"SHIFT BOARD PERCH",
			"GLASS SUPERVISION POD",
			"COMMAND ROOST GALLERY",
		],
	},
	IT_COOP_ID: {
		"name": "IT COOP",
		"short_name": "IT COOP",
		"description": "A cumulative repair and dispatch wing that assists AUTO peckwork while enlarging the ledger's maintenance and compliance surface.",
		"level_costs_cents": IT_COOP_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": IT_COOP_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": IT_COOP_UNLOCK_DAYS[0],
		"unlock_days": IT_COOP_UNLOCK_DAYS,
		"office_capacity_requirements": IT_COOP_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": IT_COOP_ACTIVE_STAFF_REQUIREMENTS,
		"unlock_requirement": "Match this tier's Records Annex and Rooster Office while maintaining the required desks and active flock.",
		"benefits": [
			"Accelerates AUTO-enrolled peckwork and improves deadline triage per tier",
			"AUTO recognizes accredited secondary specialties from level one",
		],
		"tradeoffs": [
			"Daily systems upkeep rises to $10 / $17 / $26",
			"Automation creates recurring compliance exposure and costlier Ledger Molt repairs",
		],
		"level_names": [
			"CABLE & REPAIR BENCH",
			"PREDICTIVE DISPATCH RACK",
			"AUTOMATED FILE SORTER",
		],
	},
	FLOCK_RELATIONS_OFFICE_ID: {
		"name": "FLOCK RELATIONS OFFICE",
		"short_name": "FLOCK RELATIONS",
		"description": "A cumulative casework suite where workplace harm becomes an orderly management file with a daily disposition limit.",
		"level_costs_cents": FLOCK_RELATIONS_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": FLOCK_RELATIONS_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": FLOCK_RELATIONS_UNLOCK_DAYS[0],
		"unlock_days": FLOCK_RELATIONS_UNLOCK_DAYS,
		"office_capacity_requirements": FLOCK_RELATIONS_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": FLOCK_RELATIONS_ACTIVE_STAFF_REQUIREMENTS,
		"unlock_requirement": "Match this tier's Rooster Office and Wellness Nest while maintaining the required desks and active flock.",
		"benefits": [
			"Adds one open workplace-case slot and one review disposition per tier",
			"Makes pay disputes, burnout, surveillance, automation, and stolen-credit consequences actionable",
		],
		"tradeoffs": [
			"Daily casework upkeep rises to $5 / $9 / $15",
			"Unresolved files lower compliance, strengthen solidarity, and deepen the subject's grievance",
		],
		"level_names": [
			"OPEN-NEST CASE INTAKE",
			"MEDIATION & PIP ROOM",
			"MANDATORY ARBITRATION ROOST",
		],
	},
	FEED_PROCUREMENT_COOP_ID: {
		"name": "FLOCK PROVISIONS CO-OP",
		"short_name": "PROVISIONS CO-OP",
		"description": "A cumulative grain-buying office that converts the flock's automatic daily feed bill into visible seasonal inventory, shortage, and spoilage decisions.",
		"level_costs_cents": FEED_PROCUREMENT_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": FEED_PROCUREMENT_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": FEED_PROCUREMENT_UNLOCK_DAYS[0],
		"unlock_days": FEED_PROCUREMENT_UNLOCK_DAYS,
		"office_capacity_requirements": FEED_PROCUREMENT_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": FEED_PROCUREMENT_ACTIVE_STAFF_REQUIREMENTS,
		"unlock_requirement": "Reach the tier's filing day and maintain the required authorized desks and active flock.",
		"benefits": [
			"Stores 18 / 36 / 54 scoops of feed in deterministic FIFO lots",
			"Unlocks local grain, bulk mash, and fixed-price reserve orders",
		],
		"tradeoffs": [
			"Daily co-op upkeep rises to $4 / $8 / $13",
			"Prepaid grain can spoil, while every uncovered scoop is bought automatically at the seasonal spot quote",
		],
		"level_names": [
			"RECEIVING HOPPER",
			"DRY GRAIN RESERVE",
			"FEED FUTURES DESK",
		],
	},
	FARMER_RELATIONS_GALLERY_ID: {
		"name": "HARVEST CREDIT GALLERY",
		"short_name": "CREDIT GALLERY",
		"description": "A cumulative press gallery that turns verified flock output into public standing, paid publicity contracts, and increasingly selective authorship.",
		"level_costs_cents": FARMER_RELATIONS_GALLERY_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": FARMER_RELATIONS_GALLERY_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": FARMER_RELATIONS_GALLERY_UNLOCK_DAYS[0],
		"unlock_days": FARMER_RELATIONS_GALLERY_UNLOCK_DAYS,
		"office_capacity_requirements": FARMER_RELATIONS_GALLERY_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": FARMER_RELATIONS_GALLERY_ACTIVE_STAFF_REQUIREMENTS,
		"packing_annex_level_requirements": [1, 2, 3],
		"unlock_requirement": "Reach the tier's filing day, match its Packing Annex, and maintain the required authorized desks and active flock.",
		"benefits": [
			"Files one evidence-bound publicity contract after every completed shift",
			"Higher tiers improve per-egg and golden-result placement rates",
		],
		"tradeoffs": [
			"Daily gallery upkeep rises to $5 / $9 / $15",
			"Public authorship changes flock trust, grievance, compliance, quota pressure, and who receives the credit",
		],
		"level_names": [
			"BASKET PRESS DESK",
			"CLUTCH RESULTS WALL",
			"EXECUTIVE HARVEST STAGE",
		],
	},
	FARMGATE_DISPATCH_DEPOT_ID: {
		"name": "FARMGATE DISPATCH DEPOT",
		"short_name": "FARMGATE DEPOT",
		"description": "A cumulative cold-chain and route office where finished flock output waits under the farmer's shipping authority.",
		"level_costs_cents": FARMGATE_DISPATCH_LEVEL_COSTS_CENTS,
		"maintenance_by_level_cents": FARMGATE_DISPATCH_MAINTENANCE_BY_LEVEL_CENTS,
		"max_level": 3,
		"unlock_day": FARMGATE_DISPATCH_UNLOCK_DAYS[0],
		"unlock_days": FARMGATE_DISPATCH_UNLOCK_DAYS,
		"office_capacity_requirements": FARMGATE_DISPATCH_OFFICE_CAPACITY_REQUIREMENTS,
		"active_staff_requirements": FARMGATE_DISPATCH_ACTIVE_STAFF_REQUIREMENTS,
		"packing_annex_level_requirements": FARMGATE_DISPATCH_PACKING_LEVEL_REQUIREMENTS,
		"gallery_level_requirements": FARMGATE_DISPATCH_GALLERY_LEVEL_REQUIREMENTS,
		"harvest_credit_standing_requirements": FARMGATE_DISPATCH_STANDING_REQUIREMENTS,
		"unlock_requirement": "Reach the tier's filing day, match its Packing Annex and Harvest Credit Gallery, and earn the required public standing.",
		"benefits": [
			"Stores 12 / 24 / 42 finished eggs in immutable FIFO lots",
			"Dispatches 8 / 16 / 24 eggs by county route, with a level-three regional showcase option",
		],
		"tradeoffs": [
			"Daily cold-chain upkeep rises to $7 / $13 / $22",
			"Unsold eggs incur carrying cost, expire, and can be sold at a discount when storage overflows",
		],
		"level_names": [
			"ROADSIDE LOADING SHED",
			"CHILLED COUNTY DOCK",
			"REGIONAL ROUTE FLEET",
		],
	},
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
		"work_stress_basis_points": 10_000,
		"sound_morale_millipoints": 600,
		"sound_compliance_millipoints": 0,
		"cracked_compliance_millipoints": 0,
		"operational_tradeoff": "CLAIMANT-PATH REPAIR RELIEF: a sound or golden filed path restores +0.6 handler morale.",
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
		"work_stress_basis_points": 12_500,
		"sound_morale_millipoints": 0,
		"sound_compliance_millipoints": 0,
		"cracked_compliance_millipoints": 0,
		"operational_tradeoff": "CLAIMANT-PATH TRAUMA LOAD: handler stress accumulates 25% faster after a path is filed.",
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
		"work_stress_basis_points": 10_000,
		"sound_morale_millipoints": 0,
		"sound_compliance_millipoints": 700,
		"cracked_compliance_millipoints": -1_000,
		"operational_tradeoff": "CLAIMANT-PATH AUDIT TRAIL: clean closure adds +0.7 audit order; cracked closure loses an extra 1.0.",
	},
}
const CLAIM_RESOLUTION_CUTOFF_PROGRESS := 55.0
const CLAIM_RESOLUTION_CHOICE_IDS: Array[StringName] = [
	&"settle",
	&"deny",
	&"exception",
]
const CLAIM_RESOLUTION_DEFINITIONS := {
	&"standard": {
		"label": "STANDARD HANDLING",
		"short_label": "STANDARD",
		"cost_cents": 0,
		"work_basis_points": 10_000,
		"crack_basis_points": 0,
		"beneficiary": "BUREAU",
		"benefit": "No special filing cost or handling modifier.",
		"burden": "Claimant waits on ordinary Farm Mutual terms.",
	},
	&"settle": {
		"label": "HUMANE SETTLEMENT",
		"short_label": "SETTLE",
		"cost_cents": 120,
		"work_basis_points": 10_000,
		"crack_basis_points": -300,
		"beneficiary": "CLAIMANT",
		"benefit": "Fast approved support; shell risk -3%.",
		"burden": "Feed Fund pays $1.20 now.",
	},
	&"deny": {
		"label": "FAST DENIAL",
		"short_label": "DENY",
		"cost_cents": 0,
		"work_basis_points": 11_200,
		"crack_basis_points": 400,
		"beneficiary": "BUREAU",
		"benefit": "Peckwork +12% and no filing cost.",
		"burden": "Shell risk +4%; a clean denial returns as an appeal tomorrow.",
	},
	&"exception": {
		"label": "COVERAGE EXCEPTION",
		"short_label": "EXCEPTION",
		"cost_cents": 60,
		"work_basis_points": 9_400,
		"crack_basis_points": -500,
		"beneficiary": "CLAIMANT",
		"benefit": "Broader review and shell risk -5%.",
		"burden": "Feed Fund pays $0.60 now; peckwork -6%.",
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
		"promise": "Assign the sponsor to her trained file tray for the entire next shift.",
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
const LEGACY_INCIDENT_ORDER: Array[StringName] = [
	&"ledger_molt",
	&"wellness_request",
	&"farmer_story",
	&"feed_shortfall",
]
const INCIDENT_ORDER: Array[StringName] = [
	&"ledger_molt",
	&"wellness_request",
	&"farmer_story",
	&"feed_shortfall",
	&"calendar_overflow",
	&"credit_town_hall",
	&"nest_heatwave",
	&"cold_storage_audit",
	&"fox_drill",
	&"badge_scan",
	&"egg_showcase",
	&"return_to_sender",
]
const INCIDENT_DOCKET_SEED_OFFSET := 32_452_843
const AUTHORED_SCENARIO_SEEDS := [4703, 7919, 12011, 15013, 18041, 24029]
const SCENARIO_SEED_IDS := {
	4703: &"flock_walkout",
	7919: &"shell_audit",
	12011: &"harvest_surge",
	15013: &"thin_margin",
	18041: &"fox_season",
	24029: &"credit_scramble",
}
const FINAL_HEARING_INCIDENT_ID: StringName = &"final_hearing"
const SCENARIO_IDENTITIES := {
	&"harvest_surge": {
		"name": "HARVEST SURGE",
		"short": "SURGE",
		"icon": &"egg",
		"favored_directive": &"record_harvest",
		"favored_finale_option": &"back_farmer",
		"opening_rule": "Two rush files and a higher opening quota arrive before the first bell.",
		"victory_twist": "Prove that output can rise without making the flock disposable.",
		"climax_title": "THE FARMER DEMANDS A RECORD BASKET",
		"climax_body": "The trucks are waiting. The farmer offers permanent capacity if your final signature says output comes first.",
		"promise": "Harvest policy converts the rush into pace and Farmer Favor, but keeps its shell-risk tradeoff.",
	},
	&"shell_audit": {
		"name": "SHELL AUDIT",
		"short": "AUDIT",
		"icon": &"shield",
		"favored_directive": &"shell_assurance",
		"favored_finale_option": &"publish_ledger",
		"opening_rule": "Two appeal files arrive under an active shell-control inspection.",
		"victory_twist": "Finish with evidence the inspector can verify, not merely a clean headline.",
		"climax_title": "THE INSPECTOR DEMANDS ONE SIGNATURE",
		"climax_body": "Every basket is on the table. The inspector will accept a quiet assurance, a public ledger, or the farmer's personal guarantee.",
		"promise": "Assurance policy turns inspection pressure into lower crack risk and stronger compliance.",
	},
	&"flock_walkout": {
		"name": "FLOCK WALKOUT",
		"short": "WALKOUT",
		"icon": &"flock",
		"favored_directive": &"sustainable_flock",
		"favored_finale_option": &"sign_flock_charter",
		"opening_rule": "Mabel begins near a breaking point and the flock enters with organized solidarity.",
		"victory_twist": "Resolve whether worker voice becomes policy or remains another poster.",
		"climax_title": "THE FLOCK ASKS WHO OWNS THE FLOOR",
		"climax_body": "The hens will finish the clutch. Before they do, they want one promise that survives your probation badge.",
		"promise": "Sustainable policy turns worker pressure into trust, recovery, and steadier shells.",
		"rival_name": "Golden Comb Group",
		"rival_rule": "They lead on raw output; beat them by holding welfare and score together.",
	},
	&"thin_margin": {
		"name": "THIN MARGIN",
		"short": "MARGIN",
		"icon": &"fund",
		"favored_directive": &"sustainable_flock",
		"favored_finale_option": &"publish_ledger",
		"opening_rule": "Eight dollars are already committed and the quota rises by one.",
		"victory_twist": "Finish solvent without turning care into the first budget cut.",
		"climax_title": "THE LEDGER HAS ROOM FOR ONE PRINCIPLE",
		"climax_body": "The margin survived. The closing signature decides whether the savings belong to the farmer, the public record, or the flock.",
		"promise": "Sustainable policy reduces the human cost of a cash-starved opening.",
		"rival_name": "Pennyfeather Mutual",
		"rival_rule": "They win on cash alone; beat them with a solvent file that still protects the flock.",
	},
	&"fox_season": {
		"name": "FOX SEASON",
		"short": "FOX WATCH",
		"icon": &"warning",
		"favored_directive": &"shell_assurance",
		"favored_finale_option": &"sign_flock_charter",
		"opening_rule": "Two predator files arrive and every hen begins the day watching the windows.",
		"victory_twist": "Protect the basket without making surveillance the permanent workplace.",
		"climax_title": "SECURITY ASKS WHO THE LOCKS ARE FOR",
		"climax_body": "The fox is gone. The final filing decides whether protection becomes evidence, authority, or a flock guarantee.",
		"promise": "Assurance policy stabilizes shells while the flock absorbs a visible stress shock.",
		"rival_name": "Iron Roost Assurance",
		"rival_rule": "They lead on compliance; beat them without leaving trust behind the locked door.",
	},
	&"credit_scramble": {
		"name": "CREDIT SCRAMBLE",
		"short": "CREDIT",
		"icon": &"star",
		"favored_directive": &"record_harvest",
		"favored_finale_option": &"back_farmer",
		"opening_rule": "The farmer claims the opening basket and two repair files need visible owners.",
		"victory_twist": "Win public standing while keeping the flock visible in the record.",
		"climax_title": "THE FARMER HAS ALREADY WRITTEN THE HEADLINE",
		"climax_body": "The cameras are ready. Your signature decides whose work survives the announcement.",
		"promise": "Harvest policy recovers favor quickly, but attribution choices decide the ending.",
		"rival_name": "Sunrise Egg Office",
		"rival_rule": "They lead the publicity table; beat them by pairing output with attributed work.",
	},
}
const INCIDENT_RESPONSE_VERSION := 1
const INCIDENT_RESPONSE_HISTORY_LIMIT := 24
const INCIDENT_PIVOT_MASTERY_VERSION := 1
const INCIDENT_PAIR_ORDER: Array[StringName] = [
	&"ledger_story",
	&"wellness_feed",
	&"calendar_credit",
	&"climate_quality",
	&"security_surveillance",
	&"publicity_claimants",
]
const INCIDENT_SHORT_TITLES := {
	&"ledger_molt": "LEDGER MOLT",
	&"wellness_request": "WELLNESS REQUEST",
	&"farmer_story": "FARMER STORY",
	&"feed_shortfall": "FEED SHORTFALL",
	&"calendar_overflow": "MEETING OVERFLOW",
	&"credit_town_hall": "CREDIT TOWN HALL",
	&"nest_heatwave": "NEST HEATWAVE",
	&"cold_storage_audit": "COLD ROOM AUDIT",
	&"fox_drill": "FOX DRILL",
	&"badge_scan": "BADGE SCAN",
	&"egg_showcase": "EGG SHOWCASE",
	&"return_to_sender": "RETURN TO SENDER",
	FINAL_HEARING_INCIDENT_ID: "FINAL HEARING",
}
const INCIDENT_PAIR_SOURCE := {
	&"ledger_molt": &"farmer_story",
	&"farmer_story": &"ledger_molt",
	&"wellness_request": &"feed_shortfall",
	&"feed_shortfall": &"wellness_request",
	&"calendar_overflow": &"credit_town_hall",
	&"credit_town_hall": &"calendar_overflow",
	&"nest_heatwave": &"cold_storage_audit",
	&"cold_storage_audit": &"nest_heatwave",
	&"fox_drill": &"badge_scan",
	&"badge_scan": &"fox_drill",
	&"egg_showcase": &"return_to_sender",
	&"return_to_sender": &"egg_showcase",
}
const INCIDENT_PAIR_IDS := {
	&"ledger_molt": &"ledger_story",
	&"farmer_story": &"ledger_story",
	&"wellness_request": &"wellness_feed",
	&"feed_shortfall": &"wellness_feed",
	&"calendar_overflow": &"calendar_credit",
	&"credit_town_hall": &"calendar_credit",
	&"nest_heatwave": &"climate_quality",
	&"cold_storage_audit": &"climate_quality",
	&"fox_drill": &"security_surveillance",
	&"badge_scan": &"security_surveillance",
	&"egg_showcase": &"publicity_claimants",
	&"return_to_sender": &"publicity_claimants",
}
const INCIDENT_PAIR_LABELS := {
	&"ledger_story": "LEDGER / STORY",
	&"wellness_feed": "WELLNESS / FEED",
	&"calendar_credit": "MEETINGS / CREDIT",
	&"climate_quality": "CLIMATE / QUALITY",
	&"security_surveillance": "SECURITY / SURVEILLANCE",
	&"publicity_claimants": "PUBLICITY / CLAIMANTS",
}
const INCIDENT_FOLLOW_THROUGH_DEFINITIONS := {
	&"ledger_molt": {
		&"polish_story": {"id": &"story_surplus_to_patch", "label": "PRIOR STORY FILE / BASKET POLISHED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The presentation surplus takes $4 off the current emergency-patch quote.", "affected_option_id": &"patch"},
		&"show_ledger": {"id": &"transparency_to_shadow_sheet", "label": "PRIOR STORY FILE / ACTUAL LEDGER SHOWN", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The disclosed fault makes the unofficial spreadsheet worth +2 more speed.", "affected_option_id": &"spreadsheet"},
	},
	&"farmer_story": {
		&"patch": {"id": &"clean_audit_to_story", "label": "PRIOR LEDGER FILE / PATCH AUTHORIZED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The clean audit makes POLISH THE PRESENTATION BASKET worth +$4 more Feed Fund.", "affected_option_id": &"polish_story"},
		&"spreadsheet": {"id": &"shadow_evidence_to_ledger", "label": "PRIOR LEDGER FILE / SHADOW SHEET ACTIVE", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The shadow sheet reduces SHOW THE ACTUAL LEDGER's farmer-favor loss from -6 to -4.", "affected_option_id": &"show_ledger"},
	},
	&"wellness_request": {
		&"buy_grain": {"id": &"fed_flock_to_denial", "label": "PRIOR FEED FILE / LOCAL GRAIN BOUGHT", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The visible meal gives management cover worth +2 more farmer favor when denying breaks.", "affected_option_id": &"deny_breaks"},
		&"optimize_portions": {"id": &"savings_to_breaks", "label": "PRIOR FEED FILE / PORTIONS OPTIMIZED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The ration savings lower the rotating-break cost from $6 to $4.", "affected_option_id": &"grant_breaks"},
	},
	&"feed_shortfall": {
		&"grant_breaks": {"id": &"rested_flock_to_portions", "label": "PRIOR WELLNESS FILE / BREAKS COVERED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The rested-flock study increases optimized-portion savings from $8 to $10 daily feed cost.", "affected_option_id": &"optimize_portions"},
		&"deny_breaks": {"id": &"grievance_to_grain", "label": "PRIOR WELLNESS FILE / REQUEST DENIED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The grievance settlement lowers the local-grain cost from $16 to $12.", "affected_option_id": &"buy_grain"},
	},
	&"calendar_overflow": {
		&"credit_layers": {"id": &"layer_results_to_syncs", "label": "PRIOR CREDIT FILE / LAYERS NAMED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The layer results make attending every sync worth +2 more farmer favor.", "affected_option_id": &"attend_status_sync"},
		&"credit_roosters": {"id": &"manager_byline_to_cancel", "label": "PRIOR CREDIT FILE / ROOSTERS NAMED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The manager byline makes canceling this sync worth +2 more flock trust.", "affected_option_id": &"cancel_status_sync"},
	},
	&"credit_town_hall": {
		&"cancel_status_sync": {"id": &"cancel_bargain_to_roosters", "label": "PRIOR MEETING FILE / SYNC CANCELED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The cancellation bargain makes crediting the roosters worth +2 more farmer favor.", "affected_option_id": &"credit_roosters"},
		&"attend_status_sync": {"id": &"minutes_to_layers", "label": "PRIOR MEETING FILE / EVERY SYNC ATTENDED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The meeting minutes lower the cost of crediting the layers from $10 to $6.", "affected_option_id": &"credit_layers"},
	},
	&"nest_heatwave": {
		&"open_cold_room": {"id": &"cold_room_to_cooling", "label": "PRIOR QUALITY FILE / COLD ROOM OPENED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The audit record makes filing seasonal variance faster.", "affected_option_id": &"seasonal_variance"},
		&"stage_thermostat": {"id": &"staged_audit_to_variance", "label": "PRIOR QUALITY FILE / THERMOSTAT STAGED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The staged reading discounts emergency cooling by $4.", "affected_option_id": &"authorize_cooling"},
	},
	&"cold_storage_audit": {
		&"authorize_cooling": {"id": &"cooling_to_open_audit", "label": "PRIOR CLIMATE FILE / COOLING AUTHORIZED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The cooling receipt makes staging the thermostat easier upstairs.", "affected_option_id": &"stage_thermostat"},
		&"seasonal_variance": {"id": &"variance_to_staged_audit", "label": "PRIOR CLIMATE FILE / HEAT RECLASSIFIED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The variance memo makes opening the real cold room restore more trust.", "affected_option_id": &"open_cold_room"},
	},
	&"fox_drill": {
		&"reject_tags": {"id": &"privacy_to_evacuate", "label": "PRIOR ACCESS FILE / TAGS REJECTED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The privacy filing makes a desktop drill faster to certify.", "affected_option_id": &"desktop_drill"},
		&"accept_tags": {"id": &"tracking_to_desktop", "label": "PRIOR ACCESS FILE / TAGS ACCEPTED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The tracking rollout makes a real evacuation easier to trust.", "affected_option_id": &"run_evacuate"},
	},
	&"badge_scan": {
		&"run_evacuate": {"id": &"evacuation_to_privacy", "label": "PRIOR SAFETY FILE / EVACUATION RUN", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The real drill makes accepting tracking tags faster upstairs.", "affected_option_id": &"accept_tags"},
		&"desktop_drill": {"id": &"desktop_to_tracking", "label": "PRIOR SAFETY FILE / DESKTOP DRILL", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The paper drill supplies evidence for rejecting individual tracking.", "affected_option_id": &"reject_tags"},
	},
	&"egg_showcase": {
		&"reimburse_claimant": {"id": &"claimant_to_flock", "label": "PRIOR CLAIM FILE / CLAIMANT REPAID", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The repayment record makes the management deck unusually profitable.", "affected_option_id": &"send_deck"},
		&"classify_success": {"id": &"success_to_deck", "label": "PRIOR CLAIM FILE / RETURN RECLASSIFIED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The success memo makes sending the flock restore more trust.", "affected_option_id": &"send_flock"},
	},
	&"return_to_sender": {
		&"send_flock": {"id": &"flock_to_claimant", "label": "PRIOR SHOWCASE FILE / FLOCK PRESENT", "strategy_label": "PIVOT OPPORTUNITY", "summary": "Public authorship makes reclassifying a return faster upstairs.", "affected_option_id": &"classify_success"},
		&"send_deck": {"id": &"deck_to_success", "label": "PRIOR SHOWCASE FILE / DECK PRESENTED", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The showcase deck makes reimbursing the claimant restore more trust.", "affected_option_id": &"reimburse_claimant"},
	},
}
const INCIDENT_DEFINITIONS := {
	&"ledger_molt": {
		"title": "THE EGG LEDGER IS MOLTING",
		"body": "The legacy ledger server is emitting feathers, duplicate peckwork, and legally meaningful smoke.",
		"choices": [
			{
				"id": &"patch",
				"label": "AUTHORIZE EMERGENCY PATCH",
				"short_label": "EMERGENCY PATCH",
				"glance": "SAFETY +  /  ORDER +",
				"tagline": "Spend Feed Fund to protect shells and obedience.",
				"preview": "Cost $18  ·  +4 obedience  ·  -4% crack risk this shift",
				"outcome": "The ledger was patched. Compliance has declared the smoke intentional.",
				"cost_cents": 1800,
				"tone": &"quality",
				"precedent": {
					"target_incident_id": &"farmer_story",
					"target_label": "NEXT FARMER STORY",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The clean audit raises POLISH THE PRESENTATION BASKET from +$16 to +$20 Feed Fund.",
				},
			},
			{
				"id": &"spreadsheet",
				"label": "USE THE UNOFFICIAL SPREADSHEET",
				"short_label": "SHADOW SHEET",
				"glance": "SPEED +  /  SAFETY -",
				"tagline": "Keep the Fund; trade safety and obedience for speed.",
				"preview": "No cost  ·  +5% speed  ·  +6% crack risk  ·  -6 obedience",
				"outcome": "An unofficial spreadsheet is now mission-critical and completely unaudited.",
				"cost_cents": 0,
				"tone": &"danger",
				"precedent": {
					"target_incident_id": &"farmer_story",
					"target_label": "NEXT FARMER STORY",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The shadow sheet reduces SHOW THE ACTUAL LEDGER's farmer-favor loss from -6 to -4.",
				},
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
				"short_label": "ROTATING BREAK",
				"glance": "FLOCK +  /  STRAIN -",
				"tagline": "Spend Feed Fund to restore the flock before more peckwork.",
				"preview": "Cost $6  ·  -6 stress  ·  -5 fatigue  ·  +4 morale",
				"outcome": "A rotating break was approved and immediately described as a productivity pilot.",
				"cost_cents": 600,
				"tone": &"care",
				"precedent": {
					"target_incident_id": &"feed_shortfall",
					"target_label": "NEXT FEED SHORTFALL",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The rested-flock study raises OPTIMIZE THE PORTIONS from $8 to $10 lower daily feed cost.",
				},
			},
			{
				"id": &"deny_breaks",
				"label": "DENY THE ATTITUDE VARIANCE",
				"short_label": "DENY BREAK",
				"glance": "FAVOR +  /  STRAIN +",
				"tagline": "Protect favor now; push strain into morale and shells.",
				"preview": "+3 farmer favor  ·  -6 morale  ·  +6 stress  ·  +2.5% crack risk",
				"outcome": "The request was denied. The flock has been reminded that the wellness poster is the benefit.",
				"cost_cents": 0,
				"tone": &"danger",
				"precedent": {
					"target_incident_id": &"feed_shortfall",
					"target_label": "NEXT FEED SHORTFALL",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The grievance settlement lowers BUY LOCAL GRAIN from $16 to $12.",
				},
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
				"short_label": "POLISH STORY",
				"glance": "CASH +  /  NEXT QUOTA +",
				"tagline": "Take cash and favor now; raise tomorrow's quota.",
				"preview": "+$16 fund  ·  +8 farmer favor  ·  tomorrow's quota +1",
				"outcome": "The presentation has been polished. Tomorrow's target already reflects today's optimism.",
				"cost_cents": 0,
				"tone": &"danger",
				"precedent": {
					"target_incident_id": &"ledger_molt",
					"target_label": "NEXT LEDGER MOLT",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The presentation surplus takes $4 off the current AUTHORIZE EMERGENCY PATCH quote.",
				},
			},
			{
				"id": &"show_ledger",
				"label": "SHOW THE ACTUAL LEDGER",
				"short_label": "SHOW LEDGER",
				"glance": "FLOCK +  /  FAVOR -",
				"tagline": "Trade executive favor for obedience and a lower quota.",
				"preview": "-6 farmer favor  ·  +5 obedience  ·  +6 flock unity  ·  tomorrow's quota -1",
				"outcome": "The actual ledger was attached. The farmer has called this an avoidable transparency event.",
				"cost_cents": 0,
				"tone": &"quality",
				"precedent": {
					"target_incident_id": &"ledger_molt",
					"target_label": "NEXT LEDGER MOLT",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The disclosed fault raises USE THE UNOFFICIAL SPREADSHEET from +5% to +7% speed.",
				},
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
				"short_label": "BUY LOCAL GRAIN",
				"glance": "FLOCK +  /  STRAIN -",
				"tagline": "Spend Feed Fund to reduce flock strain and shell pressure.",
				"preview": "Cost $16  ·  +6 morale  ·  -4 stress  ·  -15% strain",
				"outcome": "Local grain arrived. Procurement has opened a review into its suspicious edibility.",
				"cost_cents": 1600,
				"tone": &"care",
				"precedent": {
					"target_incident_id": &"wellness_request",
					"target_label": "NEXT WELLNESS REQUEST",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The visible meal raises DENY THE ATTITUDE VARIANCE from +3 to +5 farmer favor.",
				},
			},
			{
				"id": &"optimize_portions",
				"label": "OPTIMIZE THE PORTIONS",
				"short_label": "CUT PORTIONS",
				"glance": "FEED COST -  /  FLOCK -",
				"tagline": "Cut feed today; accept morale, speed, and shell risk.",
				"preview": "Daily feed -$8  ·  -7 morale  ·  +5 stress  ·  +3% crack risk",
				"outcome": "Portions were optimized. The missing feed has been reclassified as efficiency.",
				"cost_cents": 0,
				"tone": &"danger",
				"precedent": {
					"target_incident_id": &"wellness_request",
					"target_label": "NEXT WELLNESS REQUEST",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The ration savings lower COVER A ROTATING BREAK from $6 to $4.",
				},
			},
		],
	},
	&"calendar_overflow": {
		"title": "THE ROOSTERS HAVE SCHEDULED A MEETING ABOUT MEETINGS",
		"body": "Every manager has added a status sync to explain why the flock has too many status syncs.",
		"choices": [
			{
				"id": &"cancel_status_sync",
				"label": "CANCEL THE STATUS SYNC",
				"short_label": "CANCEL SYNC",
				"glance": "SPEED +  /  FAVOR -",
				"tagline": "Recover production time; spend executive favor.",
				"preview": "+6% speed this shift  ·  -2% crack risk  ·  +2 obedience  ·  -2 farmer favor  ·  flock trust +2",
				"outcome": "The meeting was canceled. Management has requested a meeting to process the cancellation.",
				"cost_cents": 0,
				"tone": &"quality",
				"precedent": {
					"target_incident_id": &"credit_town_hall",
					"target_label": "NEXT CREDIT TOWN HALL",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The cancellation bargain raises CREDIT THE ROOSTERS from +10 to +12 farmer favor.",
				},
			},
			{
				"id": &"attend_status_sync",
				"label": "ATTEND EVERY STATUS SYNC",
				"short_label": "ATTEND SYNCS",
				"glance": "FAVOR +  /  SPEED -",
				"tagline": "Gain executive favor; lose production time and flock patience.",
				"preview": "-7% speed this shift  ·  +8 farmer favor  ·  +2 obedience  ·  flock stress +4",
				"outcome": "Every status sync was attended. The roosters have reported record participation in reporting.",
				"cost_cents": 0,
				"tone": &"danger",
				"precedent": {
					"target_incident_id": &"credit_town_hall",
					"target_label": "NEXT CREDIT TOWN HALL",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The meeting minutes discount CREDIT THE LAYERS from $10 to $6.",
				},
			},
		],
	},
	&"credit_town_hall": {
		"title": "THE FARMER WANTS ONE NAME ON THE TOWN HALL SLIDE",
		"body": "The flock produced the basket, the roosters produced a deck, and only one contribution fits the template.",
		"choices": [
			{
				"id": &"credit_layers",
				"label": "CREDIT THE LAYERS",
				"short_label": "CREDIT LAYERS",
				"glance": "FLOCK +  /  FAVOR -",
				"tagline": "Spend Feed Fund and favor to strengthen the flock.",
				"preview": "Cost $10  ·  -2 farmer favor  ·  +4 obedience  ·  morale +8  ·  stress -6  ·  tomorrow's quota -1  ·  -1% crack risk",
				"outcome": "The layers were named. The farmer has asked whether collective nouns count as individual recognition.",
				"cost_cents": 1000,
				"tone": &"care",
				"precedent": {
					"target_incident_id": &"calendar_overflow",
					"target_label": "NEXT MEETING OVERFLOW",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The layer results raise ATTEND EVERY STATUS SYNC from +8 to +10 farmer favor.",
				},
			},
			{
				"id": &"credit_roosters",
				"label": "CREDIT THE ROOSTERS",
				"short_label": "CREDIT ROOSTERS",
				"glance": "FAVOR +  /  FLOCK -",
				"tagline": "Take favor and speed now; deepen relationship debt.",
				"preview": "No cost  ·  +10 farmer favor  ·  +5% speed  ·  flock morale -5  ·  grievance +6",
				"outcome": "The roosters received the byline. The flock has been thanked for implementing management's eggs.",
				"cost_cents": 0,
				"tone": &"danger",
				"precedent": {
					"target_incident_id": &"calendar_overflow",
					"target_label": "NEXT MEETING OVERFLOW",
					"strategy_label": "PIVOT OPPORTUNITY",
					"summary": "The manager byline raises CANCEL THE STATUS SYNC from +2 to +4 flock trust.",
				},
			},
		],
	},
	&"nest_heatwave": {
		"title": "THE NEST FLOOR IS OVERHEATING",
		"body": "The cooling budget expired before the weather did. Shell losses are already climbing.",
		"witness_prompt": "has been moving overheated files by wing",
		"choices": [
			{
				"id": &"authorize_cooling", "label": "AUTHORIZE EMERGENCY COOLING", "short_label": "COOL THE FLOOR",
				"glance": "FLOCK +  /  FUND -", "tagline": "Spend now to protect hens and shells.",
				"preview": "Cost $12  /  strain -  /  shells +  /  trust +", "cost_cents": 1200, "tone": &"care",
				"outcome": "Cooling reached the nest floor. Finance has classified breathable air as a pilot.",
				"effects": {"morale_delta": 3.0, "stress_delta": -3.0, "fatigue_delta": -5.0, "crack_modifier": -0.03, "trust_delta": 2.0, "grievance_delta": -2.0},
				"precedent": {"target_incident_id": &"cold_storage_audit", "target_label": "NEXT COLD ROOM AUDIT", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The cooling receipt makes a transparent audit safer."},
			},
			{
				"id": &"seasonal_variance", "label": "FILE IT AS SEASONAL VARIANCE", "short_label": "FILE VARIANCE",
				"glance": "SPEED +  /  SHELLS -", "tagline": "Keep output moving; leave the heat with the flock.",
				"preview": "No cost  /  speed +  /  strain +  /  favor +", "cost_cents": 0, "tone": &"danger",
				"outcome": "The heat became a seasonal variance. The season has declined responsibility.",
				"effects": {"work_multiplier": 1.05, "fatigue_delta": 5.0, "executive_delta": 4.0, "crack_modifier": 0.02, "trust_delta": -2.0, "grievance_delta": 3.0},
				"precedent": {"target_incident_id": &"cold_storage_audit", "target_label": "NEXT COLD ROOM AUDIT", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The variance memo can support a staged thermostat reading."},
			},
		],
	},
	&"cold_storage_audit": {
		"title": "THE COLD ROOM AUDIT ARRIVED WARM",
		"body": "The inspector wants the real temperature log. The farmer wants a photogenic number.",
		"witness_prompt": "signed the temperature ledger everyone is disputing",
		"choices": [
			{
				"id": &"open_cold_room", "label": "OPEN THE REAL COLD ROOM", "short_label": "OPEN THE ROOM",
				"glance": "ORDER +  /  SPEED -", "tagline": "Show the real floor and accept the slowdown.",
				"preview": "speed -  /  obedience +  /  shells +  /  favor -", "cost_cents": 0, "tone": &"quality",
				"outcome": "The real cold room was opened. The inspector found several unphotogenic facts.",
				"effects": {"work_multiplier": 0.96, "compliance_delta": 5.0, "executive_delta": -2.0, "crack_modifier": -0.02, "trust_delta": 2.0, "grievance_delta": -2.0},
				"precedent": {"target_incident_id": &"nest_heatwave", "target_label": "NEXT NEST HEATWAVE", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The audit record discounts emergency cooling by $4."},
			},
			{
				"id": &"stage_thermostat", "label": "STAGE THE THERMOSTAT PHOTO", "short_label": "STAGE PHOTO",
				"glance": "FAVOR +  /  ORDER -", "tagline": "Protect the story; deepen compliance debt.",
				"preview": "speed +  /  favor +  /  obedience -  /  shells -", "cost_cents": 0, "tone": &"danger",
				"outcome": "The thermostat photographed beautifully. The cold room did not attend.",
				"effects": {"work_multiplier": 1.03, "compliance_delta": -6.0, "executive_delta": 6.0, "crack_modifier": 0.04, "trust_delta": -3.0, "grievance_delta": 4.0},
				"precedent": {"target_incident_id": &"nest_heatwave", "target_label": "NEXT NEST HEATWAVE", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The staged reading makes seasonal variance faster."},
			},
		],
	},
	&"fox_drill": {
		"title": "THE FOX ALARM NEEDS A PASSING SCORE",
		"body": "The alarm works. The exits work on paper. The flock would like to test the remaining parts.",
		"witness_prompt": "found the blocked west exit first",
		"choices": [
			{
				"id": &"run_evacuate", "label": "RUN THE REAL EVACUATION", "short_label": "EVACUATE",
				"glance": "SAFETY +  /  SPEED -", "tagline": "Lose production time; prove the route works.",
				"preview": "speed -  /  stress -  /  obedience +  /  unity +", "cost_cents": 0, "tone": &"quality",
				"outcome": "The flock reached the yard. The west exit reached a maintenance ticket.",
				"effects": {"work_multiplier": 0.93, "stress_delta": -4.0, "compliance_delta": 4.0, "solidarity_delta": 3.0, "trust_delta": 2.0, "grievance_delta": -2.0},
				"precedent": {"target_incident_id": &"badge_scan", "target_label": "NEXT BADGE SCAN", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The drill supplies evidence against individual tracking."},
			},
			{
				"id": &"desktop_drill", "label": "CERTIFY A DESKTOP DRILL", "short_label": "PAPER DRILL",
				"glance": "SPEED +  /  TRUST -", "tagline": "Keep output moving; certify the paperwork.",
				"preview": "speed +  /  favor +  /  stress +  /  trust -", "cost_cents": 0, "tone": &"danger",
				"outcome": "The desktop drill passed. The fox has not been informed of the paperwork.",
				"effects": {"work_multiplier": 1.03, "stress_delta": 4.0, "executive_delta": 3.0, "trust_delta": -2.0, "grievance_delta": 3.0},
				"precedent": {"target_incident_id": &"badge_scan", "target_label": "NEXT BADGE SCAN", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The paper drill makes tracking easier to certify."},
			},
		],
	},
	&"badge_scan": {
		"title": "THE FARMER WANTS LOCATION TAGS ON EVERY HEN",
		"body": "Management calls it flow telemetry. The flock calls it being followed to lunch.",
		"witness_prompt": "was tracked through three authorized breaks",
		"choices": [
			{
				"id": &"reject_tags", "label": "REJECT INDIVIDUAL TRACKING", "short_label": "REJECT TAGS",
				"glance": "TRUST +  /  FAVOR -", "tagline": "Protect privacy; spend executive favor.",
				"preview": "favor -  /  trust +  /  grievance -  /  unity +", "cost_cents": 0, "tone": &"care",
				"outcome": "Individual tags were rejected. The farmer has requested aggregate suspicion instead.",
				"effects": {"executive_delta": -4.0, "trust_delta": 4.0, "grievance_delta": -4.0, "solidarity_delta": 4.0},
				"precedent": {"target_incident_id": &"fox_drill", "target_label": "NEXT FOX DRILL", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The privacy filing strengthens a real evacuation drill."},
			},
			{
				"id": &"accept_tags", "label": "ACCEPT THE FLOW TAGS", "short_label": "ACCEPT TAGS",
				"glance": "SPEED +  /  FLOCK -", "tagline": "Gain throughput; trade away privacy.",
				"preview": "speed +  /  obedience +  /  stress +  /  grievance +", "cost_cents": 0, "tone": &"danger",
				"outcome": "The tags went live. Management can now locate every slowdown except management.",
				"effects": {"work_multiplier": 1.04, "compliance_delta": 3.0, "stress_delta": 4.0, "trust_delta": -3.0, "grievance_delta": 5.0},
				"precedent": {"target_incident_id": &"fox_drill", "target_label": "NEXT FOX DRILL", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The tracking rollout speeds a desktop certification."},
			},
		],
	},
	&"egg_showcase": {
		"title": "THE COUNTY SHOWCASE WANTS THE FLOCK'S BEST EGG",
		"body": "The invitation includes room for one egg, one manager, and no production staff.",
		"witness_prompt": "laid the egg selected for the showcase",
		"choices": [
			{
				"id": &"send_flock", "label": "SEND THE HEN WITH HER EGG", "short_label": "SEND THE HEN",
				"glance": "FLOCK +  /  FUND -", "tagline": "Pay travel; make authorship visible.",
				"preview": "Cost $8  /  morale +  /  favor +  /  trust +", "cost_cents": 800, "tone": &"care",
				"outcome": "The hen and her egg attended together. The program required a wider credit line.",
				"effects": {"morale_delta": 6.0, "stress_delta": -2.0, "executive_delta": 4.0, "solidarity_delta": 3.0, "trust_delta": 3.0, "grievance_delta": -2.0},
				"precedent": {"target_incident_id": &"return_to_sender", "target_label": "NEXT RETURNED BASKET", "strategy_label": "PIVOT OPPORTUNITY", "summary": "Public authorship makes claimant repair more credible."},
			},
			{
				"id": &"send_deck", "label": "SEND THE MANAGEMENT DECK", "short_label": "SEND THE DECK",
				"glance": "FAVOR +  /  FLOCK -", "tagline": "Keep production staffed; keep credit upstairs.",
				"preview": "speed +  /  favor ++  /  morale -  /  trust -", "cost_cents": 0, "tone": &"danger",
				"outcome": "The deck won Best Egg Narrative. The egg was listed under technical support.",
				"effects": {"work_multiplier": 1.03, "executive_delta": 8.0, "morale_delta": -5.0, "trust_delta": -4.0, "grievance_delta": 5.0},
				"precedent": {"target_incident_id": &"return_to_sender", "target_label": "NEXT RETURNED BASKET", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The showcase deck supports a success reclassification."},
			},
		],
	},
	&"return_to_sender": {
		"title": "A CRACKED BASKET HAS BEEN RETURNED",
		"body": "The claimant wants repayment. The farmer wants the return counted as engagement.",
		"witness_prompt": "packed the returned basket under quota pressure",
		"choices": [
			{
				"id": &"reimburse_claimant", "label": "REIMBURSE THE CLAIMANT", "short_label": "REPAY CLAIM",
				"glance": "ORDER +  /  FUND -", "tagline": "Pay the loss; repair the relationship.",
				"preview": "Cost $10  /  obedience +  /  trust +  /  favor -", "cost_cents": 1000, "tone": &"quality",
				"outcome": "The claimant was repaid. Accounting has discovered the customer was real.",
				"effects": {"compliance_delta": 4.0, "executive_delta": -2.0, "trust_delta": 4.0, "grievance_delta": -3.0, "solidarity_delta": 2.0},
				"precedent": {"target_incident_id": &"egg_showcase", "target_label": "NEXT EGG SHOWCASE", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The repair record makes visible flock authorship credible."},
			},
			{
				"id": &"classify_success", "label": "CLASSIFY IT AS ENGAGEMENT", "short_label": "COUNT ENGAGEMENT",
				"glance": "CASH +  /  TRUST -", "tagline": "Book the return as success; deepen the debt.",
				"preview": "+$8 fund  /  favor +  /  morale -  /  grievance +", "cost_cents": 0, "tone": &"danger",
				"outcome": "The return became engagement. The claimant remains statistically enthusiastic.",
				"effects": {"revenue_delta_cents": 800, "credited_delta_cents": 800, "executive_delta": 6.0, "morale_delta": -4.0, "trust_delta": -4.0, "grievance_delta": 5.0},
				"precedent": {"target_incident_id": &"egg_showcase", "target_label": "NEXT EGG SHOWCASE", "strategy_label": "PIVOT OPPORTUNITY", "summary": "The success memo makes the management deck more valuable."},
			},
		],
	},
	FINAL_HEARING_INCIDENT_ID: {
		"title": "THE PERMANENT RECORD NEEDS YOUR SIGNATURE",
		"body": "The farmer, the flock, and the ledger are finally in the same room. Only one promise can become office policy.",
		"witness_prompt": "carried the first file and now stands beside the final basket",
		"choices": [
			{
				"id": &"back_farmer", "label": "BACK THE FARMER'S QUOTA", "short_label": "FARMER'S QUOTA",
				"glance": "FAVOR ++  /  FLOCK --", "tagline": "Win executive backing; make output the permanent rule.",
				"preview": "favor +8  /  speed +6%  /  trust -6  /  grievance +6", "cost_cents": 0, "tone": &"danger",
				"outcome": "The farmer signed first. The new quota was posted before the applause ended.",
				"effects": {"work_multiplier": 1.06, "executive_delta": 8.0, "morale_delta": -4.0, "trust_delta": -6.0, "grievance_delta": 6.0, "solidarity_delta": -3.0},
			},
			{
				"id": &"sign_flock_charter", "label": "SIGN THE FLOCK CHARTER", "short_label": "FLOCK CHARTER",
				"glance": "FLOCK ++  /  FAVOR -", "tagline": "Make worker voice permanent; spend the closing reserve.",
				"preview": "Cost $8  /  morale +6  /  trust +5  /  obedience +4  /  favor -4", "cost_cents": 800, "tone": &"care",
				"outcome": "The flock charter was signed. The farmer asked whether permanent ink was strictly necessary.",
				"effects": {"compliance_delta": 4.0, "executive_delta": -4.0, "morale_delta": 6.0, "stress_delta": -4.0, "trust_delta": 5.0, "grievance_delta": -5.0, "solidarity_delta": 6.0},
			},
			{
				"id": &"publish_ledger", "label": "PUBLISH THE COMPLETE LEDGER", "short_label": "OPEN LEDGER",
				"glance": "ORDER ++  /  FAVOR -", "tagline": "Make every tradeoff inspectable; accept scrutiny from both sides.",
				"preview": "obedience +8  /  shell risk -2%  /  unity +4  /  favor -2", "cost_cents": 0, "tone": &"quality",
				"outcome": "The complete ledger was posted. Everyone found a number they wished had remained private.",
				"effects": {"compliance_delta": 8.0, "executive_delta": -2.0, "crack_modifier": -0.02, "trust_delta": 3.0, "grievance_delta": -2.0, "solidarity_delta": 4.0},
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
		"description": "Credit her work on the farmer's basket. Builds +6 lasting warmth with her nearest perchmate.",
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
		"description": "Push her faster, but lose 10 warmth with her nearest perchmate. Repeated pressure can create rivals.",
		"preview": "FREE  /  +14% speed  /  +2.5% crack risk  /  trust -12",
		"cost_cents": 0,
		"tone": &"danger",
	},
}
const PLAYBOOK_CONTRACT_DEFINITIONS := {
	&"relay_finish": {"label": "RELAY FINISH", "icon": &"route", "target": 3, "unlock_day": 4, "gain": "REWARD + WORKSHOP STAMP", "cost": "3 HENS FINISH ASSISTED CLEAN EGGS", "risk": "REPEATED HENS DO NOT COUNT"},
	&"care_circle": {"label": "CARE CIRCLE", "icon": &"flock", "target": 3, "unlock_day": 5, "gain": "REWARD + WORKSHOP STAMP", "cost": "KETTLE RELAYS WITH 3 HENS", "risk": "REQUIRES EQUIPPED TEAM KETTLE"},
	&"mixed_basket": {"label": "MIXED BASKET", "icon": &"route", "target": 3, "unlock_day": 5, "gain": "REWARD + WORKSHOP STAMP", "cost": "CLEAN EGGS FROM 3 FILE TYPES", "risk": "REPEATED TYPES DO NOT COUNT"},
	&"deadline_rescue": {"label": "DEADLINE RESCUE", "icon": &"shield", "target": 2, "unlock_day": 5, "gain": "REWARD + WORKSHOP STAMP", "cost": "2 LAST-HOUR PECKS + CLEAN FINISHES", "risk": "MUST FINISH ON TIME"},
	&"team_coaching": {"label": "TEAM COACHING", "icon": &"flock", "target": 3, "unlock_day": 5, "gain": "REWARD + WORKSHOP STAMP", "cost": "STRONG PECKS FOR 3 HENS", "risk": "REPEATED HENS DO NOT COUNT"},
	&"route_circuit": {"label": "ROUTE CIRCUIT", "icon": &"route", "target": 3, "unlock_day": 2, "gain": "REWARD + WORKSHOP STAMP", "cost": "3 DIFFERENT TRAYS", "risk": "NO FAILURE PENALTY"},
	&"precision_pair": {"label": "PRECISION PAIR", "icon": &"shield", "target": 2, "unlock_day": 3, "gain": "REWARD + WORKSHOP STAMP", "cost": "2 ASSISTED CLEAN EGGS", "risk": "CRACKS DO NOT COUNT"},
	&"flock_relay": {"label": "FLOCK RELAY", "icon": &"flock", "target": 3, "unlock_day": 4, "gain": "REWARD + WORKSHOP STAMP", "cost": "3 DIFFERENT HENS", "risk": "CRACKS DO NOT COUNT"},
	&"clean_pair": {"label": "CLEAN PAIR", "icon": &"shield", "target": 2, "reward": "CHOOSE ONE CLUTCH REWARD", "gain": "REWARD CHOICE", "cost": "NONE", "risk": "CHAIN MAY RESET"},
	&"fit_three": {"label": "FIT THREE", "icon": &"route", "target": 3, "reward": "CHOOSE ONE CLUTCH REWARD", "gain": "REWARD CHOICE", "cost": "NONE", "risk": "FIT CHAIN MAY BREAK"},
	&"peck_pair": {"label": "PECK PAIR", "icon": &"sync", "target": 2, "reward": "CHOOSE ONE CLUTCH REWARD", "gain": "REWARD CHOICE", "cost": "NONE", "risk": "TIMING CHAIN MAY RESET"},
}
const PLAYBOOK_PREPARATION_DEFINITIONS := {
	&"brace_shells": {"label": "BRACE SHELLS", "icon": &"shield", "gain": "SHELL RISK -2.5%", "cost": "PACE -3%", "risk": "LOWER OUTPUT"},
	&"clear_trays": {"label": "CLEAR TRAYS", "icon": &"route", "gain": "PACE +5%", "cost": "SHELL RISK +1.2%", "risk": "QUALITY EXPOSURE"},
	&"rest_flock": {"label": "REST FLOCK", "icon": &"care", "gain": "STRAIN -12%", "cost": "$2.00", "risk": "FEED FUND"},
}
const PLAYBOOK_MANAGER_INTERVENTION_DEFINITIONS := {
	&"ring_bell": {
		"label": "RING THE BELL",
		"icon": &"sync",
		"gain": "ATTENTION +1",
		"cost": "ONE INTERVENTION",
		"risk": "NO FLOCK RECOVERY",
	},
	&"coffee_run": {
		"label": "COFFEE RUN",
		"icon": &"care",
		"gain": "FLOCK RECOVERY",
		"cost": "$2.00 / ONE INTERVENTION",
		"risk": "FEED FUND",
	},
	&"emergency_review": {
		"label": "EMERGENCY REVIEW",
		"icon": &"shield",
		"gain": "SHELL RISK -1.5% / COMPLIANCE +3",
		"cost": "PACE -2% / ONE INTERVENTION",
		"risk": "LOWER OUTPUT",
	},
}
const PLAYBOOK_RIVAL_DEFINITIONS := {
	&"defend": {"label": "DEFEND LEAD", "icon": &"shield", "gain": "SHELL RISK -1.5%", "cost": "PACE -2%", "risk": "RIVAL KEEPS PACE"},
	&"counter": {"label": "COUNTER PUSH", "icon": &"rival", "gain": "PACE +4%", "cost": "SHELL RISK +1.2%", "risk": "QUALITY EXPOSURE"},
	&"ignore": {"label": "BACK THE FLOCK", "icon": &"care", "gain": "SOLIDARITY +2", "cost": "NO RIVAL MODIFIER", "risk": "MARGIN UNCHANGED"},
}
const PLAYBOOK_PARTNERSHIP_STYLE_DEFINITIONS := {
	&"precision_duet": {
		"label": "PRECISION DUET",
		"icon": &"sync",
		"gain": "PAIR XP +2 / ATTENTION +1",
		"cost": "LESS RECOVERY",
		"risk": "PERMANENT PAIR STYLE",
	},
	&"recovery_pact": {
		"label": "RECOVERY PACT",
		"icon": &"care",
		"gain": "PAIR MORALE +2 / STRESS -3",
		"cost": "NO EXTRA ATTENTION",
		"risk": "PERMANENT PAIR STYLE",
	},
}
const PLAYBOOK_DELEGATION_POLICY_DEFINITIONS := {
	&"specialty_first": {
		"label": "SPECIALTY FIRST",
		"icon": &"route",
		"gain": "MATCHED FILES FIRST",
		"cost": "180M DEADLINE GRACE",
		"risk": "URGENT FILES CAN OVERRIDE",
		"rule": "Prefer the hen's accredited lanes while the earliest file remains inside the disclosed grace window.",
	},
	&"deadline_first": {
		"label": "DEADLINE FIRST",
		"icon": &"clock",
		"gain": "EARLIEST FILE FIRST",
		"cost": "SPECIALTY MAY MISS",
		"risk": "MORE STRAIN / SHELL RISK",
		"rule": "Always take the earliest deadline across every tray, using file ID as the stable tie-break.",
	},
	&"protect_strain": {
		"label": "PROTECT STRAIN",
		"icon": &"care",
		"gain": "MATCHED WORK WHEN STRAINED",
		"cost": "SLOWER QUEUE CLEAR",
		"risk": "DEADLINES OVERRIDE AT 30M",
		"rule": "At 55+ stress, keep the hen in accredited lanes unless the earliest file leads by more than 30 minutes.",
	},
}
const PLAYBOOK_LOADOUT_DEFINITIONS := {
	&"pace_floor": {"label": "PACE FLOOR", "icon": &"route", "gain": "PACE +4%", "cost": "SHELL RISK +0.8%", "risk": "FAST / FRAGILE"},
	&"quality_floor": {"label": "QUALITY FLOOR", "icon": &"shield", "gain": "SHELL RISK -1.8%", "cost": "PACE -2%", "risk": "SLOWER CLUTCH"},
	&"care_floor": {"label": "CARE FLOOR", "icon": &"care", "gain": "STRAIN -10%", "cost": "PACE -1%", "risk": "MODEST OUTPUT"},
}
const PLAYBOOK_RECOVERY_DEFINITIONS := {
	&"steady_fund": {"label": "STEADY FUND", "icon": &"cash", "gain": "QUOTA -2", "cost": "FARMER FAVOR -2", "risk": "LOWER CEILING"},
	&"repair_flock": {"label": "REPAIR FLOCK", "icon": &"care", "gain": "STRAIN -8", "cost": "$3.00", "risk": "FEED FUND"},
	&"salvage_order": {"label": "SALVAGE ORDER", "icon": &"route", "gain": "PACE +6%", "cost": "SHELL RISK +2%", "risk": "QUALITY EXPOSURE"},
}
const PLAYBOOK_SIDE_GOAL_DEFINITIONS := {
	&"clean_carton": {"label": "CLEAN ×4", "icon": &"egg", "target": 4, "gain": "PERSONAL CLUTCH MARK"},
	&"lane_mastery": {"label": "MASTER 4 FILES", "icon": &"route", "target": 4, "gain": "LANE MASTERY MARK"},
	&"gold_file": {"label": "LAND GOLD", "icon": &"golden", "target": 1, "gain": "GOLD FILE MARK"},
	&"team_lift": {"label": "TEAM LIFT", "icon": &"sync", "target": 1, "gain": "BOND MARK"},
	&"fund_growth": {"label": "FUND +$10", "icon": &"cash", "target": 1000, "gain": "GROWTH MARK"},
}
const PLAYBOOK_REWARD_DEFINITIONS := {
	&"fund": {"label": "+$3 FEED FUND", "icon": &"cash", "gain": "$3.00", "cost": "NONE", "risk": "NO HEN GROWTH"},
	&"mastery": {"label": "+6 HEN XP", "icon": &"flock", "gain": "6 CAREER XP", "cost": "NONE", "risk": "NO CASH"},
	&"recovery": {"label": "FLOCK -4 STRAIN", "icon": &"care", "gain": "STRESS -4", "cost": "NONE", "risk": "NO CASH OR XP"},
}
const PLAYBOOK_PUSH_LUCK_DEFINITIONS := {
	&"bank_clutch": {
		"label": "BANK THE CLUTCH",
		"icon": &"shield",
		"gain": "SHELL RISK -2.5%",
		"cost": "PACE -5%",
		"risk": "LESS BONUS OUTPUT",
	},
	&"chase_premium": {
		"label": "CHASE PREMIUM",
		"icon": &"golden",
		"gain": "CLEAN VALUE +15%",
		"cost": "SHELL RISK +4%",
		"risk": "THE CLUTCH CAN BREAK",
	},
}
const PLAYBOOK_HERO_CASE_ORDER: Array[StringName] = [
	&"borrowed_nest",
	&"cracked_precedent",
	&"golden_rush",
	&"perch_promise",
	&"empty_feed_bin",
	&"three_tray_jam",
	&"quiet_appeal",
	&"last_basket",
]
const PLAYBOOK_HERO_CASE_DEFINITIONS := {
	&"borrowed_nest": {
		"label": "THE BORROWED NEST", "icon": &"clock",
		"complication": "A deadline file arrived under another hen's name.",
		"choices": {
			&"fast_handoff": {"label": "FAST HANDOFF", "icon": &"route", "gain": "FAVOR +2", "cost": "STRAIN +2", "risk": "CREDIT BLURS", "executive_confidence": 2.0, "stress": 2.0, "trust": 1.0},
			&"safe_review": {"label": "SAFE REVIEW", "icon": &"shield", "gain": "COMPLIANCE +3", "cost": "NO SPEED BONUS", "risk": "DEADLINE TIGHTENS", "compliance": 3.0, "stress": -1.0},
			&"flock_credit": {"label": "FLOCK CREDIT", "icon": &"flock", "gain": "TRUST +3 / SOLIDARITY +3", "cost": "FAVOR -1", "risk": "RIVAL KEEPS PACE", "executive_confidence": -1.0, "solidarity": 3.0, "trust": 3.0},
		},
	},
	&"cracked_precedent": {
		"label": "THE CRACKED PRECEDENT", "icon": &"shield",
		"complication": "A clean rule now carries a rework exception.",
		"choices": {
			&"settle_exception": {"label": "SETTLE", "icon": &"cash", "gain": "COMPLIANCE +2", "cost": "$2.00", "risk": "FUND", "revenue_cents": -200, "compliance": 2.0},
			&"deny_exception": {"label": "DENY", "icon": &"warning", "gain": "FAVOR +2", "cost": "SOLIDARITY -2", "risk": "TRUST -2", "executive_confidence": 2.0, "solidarity": -2.0, "trust": -2.0},
			&"file_exception": {"label": "FILE EXCEPTION", "icon": &"files", "gain": "COMPLIANCE +4", "cost": "FAVOR -1", "risk": "SLOWER FILE", "executive_confidence": -1.0, "compliance": 4.0},
		},
	},
	&"golden_rush": {
		"label": "THE GOLDEN RUSH", "icon": &"golden",
		"complication": "Premium value and the rival clock peaked together.",
		"choices": {
			&"defend_rush": {"label": "DEFEND", "icon": &"shield", "gain": "COMPLIANCE +2", "cost": "FAVOR -1", "risk": "LOWER CEILING", "executive_confidence": -1.0, "compliance": 2.0},
			&"counter_rush": {"label": "COUNTER", "icon": &"rival", "gain": "$2.50 / FAVOR +2", "cost": "STRAIN +3", "risk": "QUALITY", "revenue_cents": 250, "executive_confidence": 2.0, "stress": 3.0},
			&"back_flock_rush": {"label": "BACK FLOCK", "icon": &"care", "gain": "SOLIDARITY +4 / STRAIN -2", "cost": "NO PREMIUM", "risk": "MARGIN HOLDS", "solidarity": 4.0, "stress": -2.0},
		},
	},
	&"perch_promise": {
		"label": "THE PERCH PROMISE", "icon": &"sync",
		"complication": "A bonded pair can save the file at a personal cost.",
		"choices": {
			&"promise_team_lift": {"label": "TEAM LIFT", "icon": &"sync", "gain": "TRUST +3 / STRAIN -3", "cost": "ATTENTION USED", "risk": "PAIR DEPENDENCY", "trust": 3.0, "stress": -3.0, "attention": 1},
			&"promise_solo": {"label": "SOLO ROUTE", "icon": &"route", "gain": "FAVOR +2", "cost": "STRAIN +2", "risk": "NO BOND GROWTH", "executive_confidence": 2.0, "stress": 2.0},
			&"promise_recover": {"label": "RECOVER", "icon": &"care", "gain": "STRAIN -5", "cost": "$1.00", "risk": "NO SPEED BONUS", "revenue_cents": -100, "stress": -5.0, "trust": 1.0},
		},
	},
	&"empty_feed_bin": {
		"label": "THE EMPTY FEED BIN", "icon": &"cash",
		"complication": "Flock recovery competes with a thin Feed Fund.",
		"choices": {
			&"bin_coffee": {"label": "COFFEE RUN", "icon": &"care", "gain": "FLOCK STRAIN -4", "cost": "$2.00", "risk": "FUND", "revenue_cents": -200, "all_stress": -4.0},
			&"bin_steady": {"label": "STEADY FUND", "icon": &"cash", "gain": "$2.00", "cost": "FAVOR -1", "risk": "NO RECOVERY", "revenue_cents": 200, "executive_confidence": -1.0},
			&"bin_press": {"label": "PRESS ON", "icon": &"warning", "gain": "FAVOR +3", "cost": "FLOCK STRAIN +3", "risk": "QUALITY", "executive_confidence": 3.0, "all_stress": 3.0},
		},
	},
	&"three_tray_jam": {
		"label": "THE THREE-TRAY JAM", "icon": &"route",
		"complication": "Specialty fit conflicts with the earliest deadline.",
		"choices": {
			&"jam_specialty": {"label": "SPECIALTY FIRST", "icon": &"route", "gain": "TRUST +2", "cost": "DEADLINE RISK", "risk": "QUEUE", "trust": 2.0, "stress": -1.0},
			&"jam_deadline": {"label": "DEADLINE FIRST", "icon": &"clock", "gain": "FAVOR +2", "cost": "STRAIN +2", "risk": "FIT", "executive_confidence": 2.0, "stress": 2.0},
			&"jam_protect": {"label": "PROTECT STRAIN", "icon": &"care", "gain": "STRAIN -4", "cost": "FAVOR -1", "risk": "QUEUE", "executive_confidence": -1.0, "stress": -4.0},
		},
	},
	&"quiet_appeal": {
		"label": "THE QUIET APPEAL", "icon": &"files",
		"complication": "The technically correct file strains its named hen.",
		"choices": {
			&"appeal_signature": {"label": "SIGNATURE", "icon": &"flock", "gain": "TRUST +3", "cost": "FAVOR -1", "risk": "PERSONAL STAKE", "executive_confidence": -1.0, "trust": 3.0},
			&"appeal_coach": {"label": "CAREER COACH", "icon": &"goal", "gain": "XP +4 / TRUST +2", "cost": "$1.00", "risk": "FUND", "revenue_cents": -100, "career_xp": 4, "trust": 2.0},
			&"appeal_show": {"label": "SHOW ME", "icon": &"route", "gain": "ATTENTION +1 / STRAIN -2", "cost": "ONE RESCUE", "risk": "NO CASH", "attention": 1, "stress": -2.0},
		},
	},
	&"last_basket": {
		"label": "THE LAST BASKET", "icon": &"egg",
		"complication": "Quota is safe; the final clutch can bank or reach.",
		"choices": {
			&"basket_bank": {"label": "BANK CLUTCH", "icon": &"shield", "gain": "COMPLIANCE +3", "cost": "NO PREMIUM", "risk": "LOWER CEILING", "compliance": 3.0},
			&"basket_chase": {"label": "CHASE PREMIUM", "icon": &"golden", "gain": "$3.00 / FAVOR +2", "cost": "STRAIN +3", "risk": "QUALITY", "revenue_cents": 300, "executive_confidence": 2.0, "all_stress": 3.0},
			&"basket_end": {"label": "END SHIFT", "icon": &"care", "gain": "FLOCK STRAIN -3", "cost": "NO EXTRA OUTPUT", "risk": "NONE", "all_stress": -3.0, "solidarity": 2.0},
		},
	},
}
const PLAYBOOK_CHALLENGE_MODIFIER_DEFINITIONS := {
	&"rush_hour": {
		"label": "RUSH HOUR",
		"icon": &"route",
		"gain": "PACE +10%",
		"cost": "QUOTA +2",
		"risk": "SHELL RISK +1%",
		"rule": "Two extra eggs join the order; every fitted file moves faster.",
	},
	&"glass_carton": {
		"label": "GLASS CARTON",
		"icon": &"golden",
		"gain": "CLEAN VALUE +20%",
		"cost": "SHELL RISK +3%",
		"risk": "CRACKS PAY NOTHING",
		"rule": "Every sound or golden egg is worth more, but the grading rail is unforgiving.",
	},
	&"one_bell": {
		"label": "ONE BELL",
		"icon": &"warning",
		"gain": "PACE +8%",
		"cost": "SHOW ME DISABLED",
		"risk": "NO ROUTE RESCUE",
		"rule": "The floor runs faster, but the one-shot route rescue is unavailable.",
	},
}
const PLAYBOOK_COMBO_RECIPE_DEFINITIONS := {
	&"fast": {
		"id": &"file_flywheel",
		"label": "FILE FLYWHEEL",
		"icon": &"route",
		"effect": "PACE +3%",
		"steps": [
			{"id": &"fit_routes", "label": "FIT ×3", "target": 3},
			{"id": &"priority_peck", "label": "PECK ×1", "target": 1},
		],
	},
	&"safe": {
		"id": &"shell_seal",
		"label": "SHELL SEAL",
		"icon": &"shield",
		"effect": "SHELL RISK -1.5%",
		"steps": [
			{"id": &"clean_eggs", "label": "CLEAN ×2", "target": 2},
			{"id": &"bank_clutch", "label": "BANK CLUTCH", "target": 1},
		],
	},
	&"flock": {
		"id": &"perch_pact",
		"label": "PERCH PACT",
		"icon": &"care",
		"effect": "STRAIN -12%",
		"steps": [
			{"id": &"team_lift", "label": "TEAM LIFT", "target": 1},
			{"id": &"hen_signature", "label": "HEN SIGNATURE", "target": 1},
		],
	},
}
const PLAYBOOK_STRATEGY_PRESET_ORDER: Array[StringName] = [
	&"fast",
	&"safe",
	&"flock",
]
const PLAYBOOK_STRATEGY_PRESET_DEFINITIONS := {
	&"fast": {
		"label": "FAST PLAN",
		"icon": &"route",
		"contract_id": &"fit_three",
		"loadout_id": &"pace_floor",
		"preparation_id": &"clear_trays",
		"side_goal_id": &"lane_mastery",
		"gain": "PACE +9.2% / FIT REWARD",
		"cost": "SHELL RISK +2.0%",
		"risk": "FAST / FRAGILE",
		"promise": "Move fitted files quickly and turn a three-route chain into a reward draft.",
		"cost_cents": 0,
	},
	&"safe": {
		"label": "SAFE PLAN",
		"icon": &"shield",
		"contract_id": &"clean_pair",
		"loadout_id": &"quality_floor",
		"preparation_id": &"brace_shells",
		"side_goal_id": &"clean_carton",
		"gain": "SHELL RISK -4.3% / CLEAN REWARD",
		"cost": "PACE -4.9%",
		"risk": "LOWER OUTPUT",
		"promise": "Protect shells, build a clean clutch, and draft a reward without gambling banked progress.",
		"cost_cents": 0,
	},
	&"flock": {
		"label": "FLOCK PLAN",
		"icon": &"care",
		"contract_id": &"peck_pair",
		"loadout_id": &"care_floor",
		"preparation_id": &"rest_flock",
		"side_goal_id": &"team_lift",
		"gain": "STRAIN -20.8% / TEAM PLAY",
		"cost": "$2.00 / PACE -1%",
		"risk": "FEED FUND",
		"promise": "Protect the flock, coordinate a bonded pair, and turn two strong pecks into a reward draft.",
		"cost_cents": 200,
	},
}
const PLAYBOOK_HEN_PROPOSAL_DEFINITIONS := {
	&"own_lane": {"label": "TRUST MY LANE", "icon": &"flock", "gain": "FIT + TRUST", "cost": "ONE PROPOSAL", "risk": "SPECIALTY FIRST"},
	&"pair_perch": {"label": "PAIR MY PERCH", "icon": &"sync", "gain": "PAIR RECOVERY", "cost": "ONE PROPOSAL", "risk": "REQUIRES BOND"},
	&"protect_clutch": {"label": "PROTECT MY CLUTCH", "icon": &"care", "gain": "STRAIN -4", "cost": "PACE -2%", "risk": "ONE SHIFT"},
}
const PLAYBOOK_OFFICE_TOY_DEFINITIONS := {
	&"desk_bell": {"label": "RING DESK BELL", "icon": &"sync", "gain": "HEN REACTION", "cost": "NONE", "risk": "ONCE / SHIFT"},
	&"copy_test": {"label": "TEST THE COPIER", "icon": &"files", "gain": "HEN REACTION", "cost": "NONE", "risk": "ONCE / SHIFT"},
	&"cooler_break": {"label": "COOLER BREAK", "icon": &"care", "gain": "STRAIN -2", "cost": "NONE", "risk": "ONCE / SHIFT"},
}
const PLAYBOOK_DISPLAY_STYLE_ORDER: Array[StringName] = [&"brass", &"shell", &"flock"]
const PLAYBOOK_DISPLAY_STYLE_DEFINITIONS := {
	&"brass": {"label": "BRASS FILE", "icon": &"golden", "accent": "f0bd5f"},
	&"shell": {"label": "SHELL LEDGER", "icon": &"shield", "accent": "7bc3c8"},
	&"flock": {"label": "FLOCK PATCH", "icon": &"flock", "accent": "8ac47a"},
}
const PLAYBOOK_RARE_EPISODE_DEFINITIONS := {
	&"printer_revolt": {"label": "PRINTER REVOLT", "icon": &"files", "gain": "ATTENTION +1", "cost": "$1.00", "risk": "CLEAR THE JAM"},
	&"coffee_union": {"label": "COFFEE UNION", "icon": &"care", "gain": "FLOCK STRAIN -3", "cost": "PACE -1%", "risk": "ONE SHIFT"},
	&"bell_audit": {"label": "BELL AUDIT", "icon": &"shield", "gain": "COMPLIANCE +2", "cost": "MORALE -1", "risk": "VISIBLE TRADE"},
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
var incident_response_history: Array[Dictionary] = []
var incident_pivot_mastery_receipts: Array[Dictionary] = []
var upgrade_levels: Dictionary = {
	&"peckwork_tools": 0,
	&"shell_lamp": 0,
	&"nest_cushion": 0,
}
var first_clutch_reinvestment: Dictionary = {}
var active_playbook: Dictionary = {}
var career_workshop := CareerWorkshop.new()
var flock_relationships := FlockRelationships.new()
var hero_case_history: Array[Dictionary] = []
var rival_response_history: Array[Dictionary] = []
var requisition_spend_today_cents: int = 0
var requisition_spend_total_cents: int = 0
var orientation_procurement_match_today_cents: int = 0
var orientation_procurement_match_total_cents: int = 0
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
var owned_facilities: Dictionary = {
	&"candling_rework_bay": 0,
	PACKING_ANNEX_ID: 0,
	RECORDS_ANNEX_ID: 0,
	FARM_MUTUAL_SERVICE_COOP_ID: 0,
	FARM_MUTUAL_NEGOTIATION_ROOM_ID: 0,
	WELLNESS_NEST_ID: 0,
	TRAINING_ROOST_ID: 0,
	ROOSTER_OPERATIONS_OFFICE_ID: 0,
	IT_COOP_ID: 0,
	FLOCK_RELATIONS_OFFICE_ID: 0,
	FEED_PROCUREMENT_COOP_ID: 0,
	FARMER_RELATIONS_GALLERY_ID: 0,
	FARMGATE_DISPATCH_DEPOT_ID: 0,
}
var pinned_capital_plan_id: StringName = &""
var pinned_economic_watch_id: StringName = &"auto"
var last_facility_purchase_receipt: Dictionary = {}
var facility_commissioning_history: Array[Dictionary] = []
var campus_expansion_state: Dictionary = {
	"version": CAMPUS_EXPANSION_SAVE_VERSION,
	"parcel_owned": false,
	"services": {
		"circulation": false,
		"power": false,
		"cold_chain": false,
	},
	"pod_owned": false,
	"pod_socket_id": "",
	"capital_spend_total_cents": 0,
	"next_receipt_id": 1,
	"last_receipt": {},
	"history": [],
}
var packing_carton_progress: int = 0
var packing_cartons_today: int = 0
var packing_cartons_total: int = 0
var packing_value_bonus_today_cents: int = 0
var packing_value_bonus_total_cents: int = 0
var packing_carton_bonus_today_cents: int = 0
var packing_carton_bonus_total_cents: int = 0
var intake_rejections_today: int = 0
var intake_rejections_total: int = 0
var intake_missed_value_today_cents: int = 0
var intake_missed_value_total_cents: int = 0
var active_market_contract: Dictionary = {}
var market_contract_decline_receipt: Dictionary = {}
var last_market_contract_result: Dictionary = {}
var market_contracts_signed_total: int = 0
var market_contracts_succeeded_total: int = 0
var market_contracts_breached_total: int = 0
var market_clean_contract_streak: int = 0
var best_market_clean_contract_streak: int = 0
var market_contract_premium_today_cents: int = 0
var market_contract_premium_total_cents: int = 0
var market_contract_breach_today_cents: int = 0
var market_contract_breach_total_cents: int = 0
var market_pricing_outcomes: Dictionary = {
	"mutual_rate_success": 0,
	"mutual_rate_breach": 0,
	"community_access_rate_success": 0,
	"community_access_rate_breach": 0,
	"executive_select_rate_success": 0,
	"executive_select_rate_breach": 0,
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
var flock_relations_open_cases: Array[Dictionary] = []
var flock_relations_resolutions_used_today: int = 0
var flock_relations_resolved_total: int = 0
var flock_relations_denied_total: int = 0
var flock_relations_settlement_spend_total_cents: int = 0
var last_flock_relations_resolution: Dictionary = {}
var flock_relations_resolution_history: Array[Dictionary] = []
var next_flock_relations_case_id: int = 1
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
var peck_assist_timing_profile: StringName = &"standard"
var last_peck_assist: Dictionary = {}
var last_peck_assist_delivery: Dictionary = {}
var priority_credit_today_cents: int = 0
var priority_credit_total_cents: int = 0
var routing_momentum_chain: int = 0
var best_routing_momentum_chain: int = 0
var routing_momentum_peck_recharge_bank: int = 0
var routing_momentum_peck_recharges_used_today: int = 0
var routing_momentum_golden_charges: int = 0
var routing_momentum_golden_target_claim_id: int = -1
var routing_momentum_golden_target_worker_id: int = -1
var last_routing_dispatch: Dictionary = {}
var routing_momentum_break_serial: int = 0
var last_routing_momentum_break: Dictionary = {}
var routing_momentum_recovery_serial: int = 0
var last_routing_momentum_recovery: Dictionary = {}
var manager_roster: Array[Dictionary] = []
var last_manager_action: Dictionary = {}
var management_reports_today: int = 0
var management_reports_total: int = 0
var management_visibility_today: int = 0

var _tick_count: int = 0
var _runtime_projection_cache: Dictionary = {}
var _runtime_static_projection_cache: Dictionary = {}
var _runtime_live_projection_cache: Dictionary = {}
var _runtime_projection_cache_msec: int = -1
var _runtime_projection_cache_day: int = -1
var _runtime_projection_cache_phase: int = -1
var _runtime_projection_cache_builds: int = 0
var _runtime_projection_cache_hits: int = 0
var _runtime_projection_cache_exact_builds: int = 0
var _runtime_projection_cache_refresh_builds: int = 0
var _runtime_projection_cache_read_only_hits: int = 0
var _runtime_static_projection_cache_builds: int = 0
var _runtime_live_projection_cache_builds: int = 0
var _runtime_tick_snapshot_cache: Dictionary = {}
var _runtime_tick_snapshot_cache_day: int = -1
var _runtime_tick_snapshot_cache_phase: int = -1
var _runtime_tick_snapshot_cache_hits: int = 0

# One bounded quote bank for the current terms. Live preflight gates are never
# cached: funds, staffing, reserved capacity and signing authority remain exact.
var _market_quote_context: Array = []
var _market_quote_cache: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _claim_rng := RandomNumberGenerator.new()
var _incident_rng := RandomNumberGenerator.new()
var _career_seed: int = 1701
var _incident_bag: Array[StringName] = []
var _last_standard_incident_id: StringName = &""
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
var _routing_momentum_free_assist_claim_ids: Dictionary[int, bool] = {}
var _feed_procurement: FeedProcurementStateScript = FeedProcurementStateScript.new()
var _harvest_credit: HarvestCreditStateScript = HarvestCreditStateScript.new()
var _farmgate_dispatch: FarmgateDispatchStateScript = FarmgateDispatchStateScript.new()
var _campus_portfolio: CampusPortfolioStateScript = CampusPortfolioStateScript.new()
var _farm_treasury: FarmTreasuryStateScript = FarmTreasuryStateScript.new(5000, 0)
var _internship_program: InternshipProgramStateScript = InternshipProgramStateScript.new()
var _opening_challenge_configured := false
var _save_codec: SimulationSaveCodec = SimulationSaveCodec.new(self)
var _market_desk: MarketContractDesk = MarketContractDesk.new(self)
var _facility_ops: FacilityOperations = FacilityOperations.new(self)
var _playbook_authority: PlaybookAuthority = PlaybookAuthority.new(self)
var _flock_desk: FlockRelationsDesk = FlockRelationsDesk.new(self)


func _init(
	seed: int = 1701,
	initial_staff_count: int = MAXIMUM_STAFF_CAPACITY,
	incident_docket_seed: int = -1,
) -> void:
	_career_seed = clampi(
		seed if incident_docket_seed < 1 else incident_docket_seed,
		1,
		2_000_000_000,
	)
	_rng.seed = seed
	_claim_rng.seed = seed + 104729
	_incident_rng.seed = _career_seed + INCIDENT_DOCKET_SEED_OFFSET
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
	_initialize_manager_roster()
	_feed_procurement.begin_day(day)
	_farmgate_dispatch.begin_day(day)
	_campus_portfolio.begin_day(day, _campus_portfolio_context())
	quota_target = active_worker_count() * 4
	for lane in INITIAL_CLAIM_LANES:
		_enqueue_new_claim(lane)
	_sync_claims_waiting()
	_prepare_morning_directive()


## Applies the selected campaign's disclosed opening economy exactly once to a
## pristine Day 1 simulation. Validation finishes before any authority changes,
## so malformed contracts cannot partially alter a new file.
func configure_opening_challenge(contract: Dictionary) -> Dictionary:
	var rejected := {
		"accepted": false,
		"reason": "Opening challenge terms require a pristine Day 1 simulation.",
	}
	if _opening_challenge_configured or contract.is_empty():
		return rejected
	var opening_value: Variant = contract.get("opening_terms", null)
	if not opening_value is Dictionary:
		rejected["reason"] = "The selected challenge has no valid opening economy."
		return rejected
	var opening := opening_value as Dictionary
	for required_key in [
		"feed_fund_cents",
		"quota_target",
		"additional_claim_lanes",
		"pressure_label",
	]:
		if not opening.has(required_key):
			rejected["reason"] = "The selected challenge opening is incomplete."
			return rejected
	var fund_cents := int(opening.get("feed_fund_cents", -1))
	var opening_quota := int(opening.get("quota_target", -1))
	var lanes_value: Variant = opening.get("additional_claim_lanes", null)
	var pressure_label := String(opening.get("pressure_label", "")).strip_edges().to_upper()
	if (
		fund_cents < 0
		or fund_cents > 100_000
		or opening_quota < 1
		or opening_quota > 100
		or not lanes_value is Array
		or pressure_label.is_empty()
	):
		rejected["reason"] = "The selected challenge opening is outside supported limits."
		return rejected
	var additional_lanes: Array[StringName] = []
	for lane_value: Variant in lanes_value as Array:
		var lane := StringName(String(lane_value).strip_edges().to_lower())
		if not CLAIM_LANE_DEFINITIONS.has(lane):
			rejected["reason"] = "The selected challenge names an unknown opening file tray."
			return rejected
		additional_lanes.append(lane)
	if additional_lanes.size() > 4:
		rejected["reason"] = "The selected challenge opens too many additional files."
		return rejected
	var baseline_quota := active_worker_count() * 4
	var baseline_live_files := INITIAL_CLAIM_LANES.size()
	if (
		day != 1
		or minute_of_day != SHIFT_START_MINUTE
		or shift_phase != ShiftPhase.AWAITING_DIRECTIVE
		or eggs_today != 0
		or eggs_total != 0
		or claims_processed != 0
		or credited_today_cents != 0
		or revenue_cents != 5000
		or quota_target != baseline_quota
		or _outstanding_claim_count() != baseline_live_files
		or _outstanding_claim_count() + additional_lanes.size() > current_claim_capacity()
	):
		return rejected
	var before_fund_cents := revenue_cents
	var before_quota := quota_target
	var before_live_files := _outstanding_claim_count()
	revenue_cents = fund_cents
	_farm_treasury = FarmTreasuryStateScript.new(fund_cents, 0)
	quota_target = opening_quota
	for lane in additional_lanes:
		_enqueue_new_claim(lane)
	_apply_scenario_opening_structure()
	_sync_claims_waiting()
	_opening_challenge_configured = true
	return {
		"accepted": true,
		"challenge_id": String(contract.get("id", "")),
		"pressure_label": pressure_label,
		"before_fund_cents": before_fund_cents,
		"fund_cents": revenue_cents,
		"before_quota": before_quota,
		"quota_target": quota_target,
		"before_live_files": before_live_files,
		"live_files": _outstanding_claim_count(),
	}


func _initialize_manager_roster() -> void:
	manager_roster.clear()
	manager_roster.append(_new_manager_record(MANAGER_DEFAULT_HIRE_ORDER[0], 0, 1))


func _new_manager_record(candidate_id: StringName, slot_index: int, hired_day: int) -> Dictionary:
	var definition := MANAGER_CANDIDATE_DEFINITIONS.get(candidate_id, {}) as Dictionary
	return {
		"id": String(candidate_id),
		"candidate_id": String(candidate_id),
		"slot_index": slot_index,
		"hired_day": hired_day,
		"assignment_id": String(MANAGER_ASSIGNMENT_ORDER[slot_index % MANAGER_ASSIGNMENT_ORDER.size()]),
		"posture_id": String(StringName(definition.get("default_posture", &"coach"))),
		"posture_filed": false,
		"influence": 0,
		"rank": 0,
		"credit_claims": 0,
		"interventions": 0,
		"last_pip_worker_id": -1,
	}


# --- FacilityOperations delegators: implementation lives in facility_operations.gd ---
func _ensure_manager_posts_for_office_level() -> void:
	_facility_ops._ensure_manager_posts_for_office_level()


func facility_level(facility_id: StringName) -> int:
	return _facility_ops.facility_level(facility_id)


func has_facility(facility_id: StringName) -> bool:
	return _facility_ops.has_facility(facility_id)


func _claim_capacity_for_facilities_and_campus(
	facilities: Dictionary,
	campus_state: Dictionary,
	portfolio_bonus: int = 0,
) -> int:
	return _facility_ops._claim_capacity_for_facilities_and_campus(facilities, campus_state, portfolio_bonus)


func _service_coop_requirement(schedule: Array[int], target_level: int) -> int:
	return _facility_ops._service_coop_requirement(schedule, target_level)


func _facility_level_schedule_value(schedule: Array, level: int, fallback: int) -> int:
	return _facility_ops._facility_level_schedule_value(schedule, level, fallback)


func _facility_tier_requirement(schedule: Array, target_level: int) -> int:
	return _facility_ops._facility_tier_requirement(schedule, target_level)


func _facility_unlock_day_for_level(definition: Dictionary, target_level: int) -> int:
	return _facility_ops._facility_unlock_day_for_level(definition, target_level)


func _qualified_active_worker_count(minimum_career_level: int) -> int:
	return _facility_ops._qualified_active_worker_count(minimum_career_level)


func _farmgate_storage_capacity_for_level_and_campus(
	farmgate_level: int,
	campus_state: Dictionary,
	portfolio_bonus_eggs: int = 0,
) -> int:
	return _facility_ops._farmgate_storage_capacity_for_level_and_campus(farmgate_level, campus_state, portfolio_bonus_eggs)


func facility_effects() -> Dictionary:
	return _facility_ops.facility_effects()


func facility_catalog() -> Array[Dictionary]:
	return _facility_ops.facility_catalog()


func facility_status(facility_id: StringName) -> Dictionary:
	return _facility_ops.facility_status(facility_id)


func _facility_cost_for_level(definition: Dictionary, target_level: int) -> int:
	return _facility_ops._facility_cost_for_level(definition, target_level)


func _facility_maintenance_for_level(definition: Dictionary, target_level: int) -> int:
	return _facility_ops._facility_maintenance_for_level(definition, target_level)


func _facility_level_name(definition: Dictionary, target_level: int) -> String:
	return _facility_ops._facility_level_name(definition, target_level)


func _campus_services_for_state(state: Dictionary) -> Dictionary:
	return _facility_ops._campus_services_for_state(state)


func _campus_cold_chain_active_for_state(state: Dictionary) -> bool:
	return _facility_ops._campus_cold_chain_active_for_state(state)


func _campus_claim_capacity_bonus_for_state(state: Dictionary) -> int:
	return _facility_ops._campus_claim_capacity_bonus_for_state(state)


func _campus_daily_cost_for_state(state: Dictionary) -> int:
	return _facility_ops._campus_daily_cost_for_state(state)


func current_daily_campus_cost_cents() -> int:
	return _facility_ops.current_daily_campus_cost_cents()


func _campus_action_terms(action_id: StringName, item_id: StringName) -> Dictionary:
	return _facility_ops._campus_action_terms(action_id, item_id)


func _campus_state_action_reason(
	state: Dictionary,
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName,
) -> String:
	return _facility_ops._campus_state_action_reason(state, action_id, item_id, socket_id)


func _apply_campus_action_to_state(
	state: Dictionary,
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName,
) -> void:
	_facility_ops._apply_campus_action_to_state(state, action_id, item_id, socket_id)


func _campus_action_outcome(
	action_id: StringName,
	item_id: StringName,
	from_socket_id: StringName,
	socket_id: StringName,
) -> String:
	return _facility_ops._campus_action_outcome(action_id, item_id, from_socket_id, socket_id)


func campus_expansion_action_quote(
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName = &"",
) -> Dictionary:
	return _facility_ops.campus_expansion_action_quote(action_id, item_id, socket_id)


func purchase_campus_parcel(parcel_id: StringName = CAMPUS_PARCEL_ID) -> Dictionary:
	return _facility_ops.purchase_campus_parcel(parcel_id)


func commission_campus_service(service_id: StringName) -> Dictionary:
	return _facility_ops.commission_campus_service(service_id)


func place_campus_module(module_id: StringName, socket_id: StringName) -> Dictionary:
	return _facility_ops.place_campus_module(module_id, socket_id)


func relocate_campus_module(module_id: StringName, socket_id: StringName) -> Dictionary:
	return _facility_ops.relocate_campus_module(module_id, socket_id)


func campus_expansion_snapshot() -> Dictionary:
	return _facility_ops.campus_expansion_snapshot()


func _campus_portfolio_context(
	planning_override: Variant = null,
	worker_id_override: Array = [],
	worker_name_override: Dictionary = {},
	campus_state_override: Dictionary = {},
	target_day: int = -1,
) -> Dictionary:
	return _facility_ops._campus_portfolio_context(planning_override, worker_id_override, worker_name_override, campus_state_override, target_day)


func campus_portfolio_deed_quote(parcel_id: StringName) -> Dictionary:
	return _facility_ops.campus_portfolio_deed_quote(parcel_id)


func purchase_campus_portfolio_deed(parcel_id: StringName) -> Dictionary:
	return _facility_ops.purchase_campus_portfolio_deed(parcel_id)


func campus_portfolio_project_quote(module_id: StringName, pad_id: StringName) -> Dictionary:
	return _facility_ops.campus_portfolio_project_quote(module_id, pad_id)


func authorize_campus_portfolio_project(
	module_id: StringName,
	pad_id: StringName,
) -> Dictionary:
	return _facility_ops.authorize_campus_portfolio_project(module_id, pad_id)


func assign_campus_portfolio_worker(module_id: StringName, worker_id: int) -> Dictionary:
	return _facility_ops.assign_campus_portfolio_worker(module_id, worker_id)


func unassign_campus_portfolio_worker(module_id: StringName) -> Dictionary:
	return _facility_ops.unassign_campus_portfolio_worker(module_id)


func _campus_portfolio_assignment_for_worker(worker_id: int) -> StringName:
	return _facility_ops._campus_portfolio_assignment_for_worker(worker_id)


func campus_portfolio_snapshot(north_projection: Dictionary = {}) -> Dictionary:
	return _facility_ops.campus_portfolio_snapshot(north_projection)


func _facility_purchase_effect_copy(facility_id: StringName, level: int) -> Dictionary:
	return _facility_ops._facility_purchase_effect_copy(facility_id, level)


func facility_purchase_preflight(facility_id: StringName) -> Dictionary:
	return _facility_ops.facility_purchase_preflight(facility_id)


func purchase_facility(facility_id: StringName) -> Dictionary:
	return _facility_ops.purchase_facility(facility_id)


func daily_facility_expansion_cost_cents() -> int:
	return _facility_ops.daily_facility_expansion_cost_cents()


func current_daily_facility_maintenance_cents() -> int:
	return _facility_ops.current_daily_facility_maintenance_cents()


func current_daily_facility_cost_cents() -> int:
	return _facility_ops.current_daily_facility_cost_cents()


func _is_integral_number(value: Variant) -> bool:
	return _facility_ops._is_integral_number(value)


func _facility_claim_speed_multiplier(worker: ChickenState) -> float:
	return _facility_ops._facility_claim_speed_multiplier(worker)


func _store_farmgate_lot_with_campus_capacity(
	claim_id: int,
	laying_day: int,
	worker_id: int,
	worker_name: String,
	quality: StringName,
	value_cents: int,
	farmgate_level: int,
	shelf_shifts: int,
) -> Dictionary:
	return _facility_ops._store_farmgate_lot_with_campus_capacity(claim_id, laying_day, worker_id, worker_name, quality, value_cents, farmgate_level, shelf_shifts)


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


## Whose side the file has taken, derived from records the simulation already
## persists: incident responses (by authored tone), closing credit memos,
## flock petitions, and the restructuring dossier (weighted double). Nothing
## here is saved, so every existing file gets a complete ledger.
func complicity_ledger_snapshot() -> Dictionary:
	var acts: Array[Dictionary] = []
	for record: Dictionary in incident_response_history:
		var incident_id := StringName(String(record.get("incident_id", "")))
		var option_id := StringName(String(record.get("option_id", "")))
		var choice := _incident_choice_definition(incident_id, option_id)
		if choice.is_empty():
			continue
		acts.append({
			"day": int(record.get("day", 0)),
			"source": "incident",
			"label": "%s / %s" % [
				String(INCIDENT_SHORT_TITLES.get(incident_id, "OFFICE INCIDENT")),
				String(choice.get("short_label", choice.get("label", "RESPONSE"))),
			],
			"side": ComplicityLedgerScript.incident_side(StringName(choice.get("tone", &""))),
		})
	for style_id: StringName in CREDIT_STYLE_IDS:
		for _index in maxi(0, int(credit_choice_counts.get(style_id, 0))):
			acts.append({
				"source": "credit_memo",
				"label": "CREDIT MEMO",
				"side": ComplicityLedgerScript.credit_style_side(style_id),
			})
	for record: Dictionary in flock_petition_history:
		acts.append({
			"day": int(record.get("day", 0)),
			"source": "petition",
			"label": "%s / %s" % [
				String(record.get("petition_title", "FLOCK PETITION")),
				String(record.get("response_id", "")).replace("_", " ").to_upper(),
			],
			"side": ComplicityLedgerScript.petition_side(StringName(String(record.get("response_id", "")))),
		})
	if flock_restructuring_resolved:
		# The restructuring already counts once as a credit memo style; its
		# extra weight marks it as the file's heaviest single choice.
		acts.append({
			"day": int(flock_restructuring_record.get("day", FLOCK_RESTRUCTURING_SHIFT)),
			"source": "restructuring",
			"label": "FLOCK RESTRUCTURING / %s" % String(flock_restructuring_record.get("worker_name", "THE LOWEST-RANKED HEN")).to_upper(),
			"side": ComplicityLedgerScript.restructuring_side(
				StringName(String(flock_restructuring_record.get("option_id", "")))
			),
		})
	return ComplicityLedgerScript.compose(acts)


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
		"ledger": complicity_ledger_snapshot(),
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


## Three bounded, named outcomes for the final review. The epilogue reads the
## same authoritative worker, relationship, career, and restructuring state
## used by the simulation; it never persists or awards a second result.
func campaign_flock_epilogue() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var used_worker_ids: Dictionary = {}
	var restructured_name := String(flock_restructuring_record.get("worker_name", ""))
	if not restructured_name.is_empty():
		for worker: ChickenState in workers:
			if worker.display_name != restructured_name:
				continue
			var option_id := StringName(String(flock_restructuring_record.get("option_id", "")))
			var value := "REDEPLOYED"
			var outcome := "%s kept her chair with a corrected specialty route." % worker.display_name
			var tone: StringName = &"care"
			if option_id == &"nominate_variance":
				value = "RELEASED"
				outcome = "%s was removed as the variance; the flock keeps the precedent." % worker.display_name
				tone = &"danger"
			elif option_id == &"contest_ranking":
				value = "STOOD TOGETHER"
				outcome = "%s kept her chair after the flock contested the ranking together." % worker.display_name
				tone = &"solidarity"
			entries.append(_campaign_epilogue_entry(
				worker,
				"RESTRUCTURING",
				value,
				outcome,
				tone,
			))
			used_worker_ids[worker.id] = true
			break

	var trust_worker := _campaign_epilogue_worker(used_worker_ids, &"trust")
	if trust_worker != null:
		var relationship := trust_worker.relationship_label().to_upper()
		var trust_outcome := (
			"%s leaves the file trusting the manager enough to face another shift."
			% trust_worker.display_name
			if trust_worker.manager_trust >= 60.0 and trust_worker.grievance <= 35.0 else
			"%s leaves the file wary, with every credit decision still remembered."
			% trust_worker.display_name
		)
		entries.append(_campaign_epilogue_entry(
			trust_worker,
			"TRUST",
			relationship,
			trust_outcome,
			&"care" if trust_worker.manager_trust >= 60.0 else &"warning",
		))
		used_worker_ids[trust_worker.id] = true

	var career_worker := _campaign_epilogue_worker(used_worker_ids, &"career")
	if career_worker != null:
		entries.append(_campaign_epilogue_entry(
			career_worker,
			"CAREER",
			career_worker.career_title(),
			"%s closes probation with %d career XP and %d credited egg%s on her record."
			% [
				career_worker.display_name,
				career_worker.career_xp,
				career_worker.eggs_laid,
				"" if career_worker.eggs_laid == 1 else "s",
			],
			&"quality",
		))
		used_worker_ids[career_worker.id] = true

	var strain_worker := _campaign_epilogue_worker(used_worker_ids, &"strain")
	if strain_worker != null and entries.size() < 3:
		var burden := roundi((strain_worker.stress + strain_worker.fatigue) * 0.5)
		entries.append(_campaign_epilogue_entry(
			strain_worker,
			"STRAIN",
			"%d%% BURDEN" % burden,
			(
				"%s reaches the closing bell carrying visible strain into whatever comes next."
				% strain_worker.display_name
				if burden >= 45 else
				"%s reaches the closing bell with enough recovery left to begin again."
				% strain_worker.display_name
			),
			&"danger" if burden >= 45 else &"care",
		))
	while entries.size() > 3:
		entries.pop_back()
	return entries


func _campaign_epilogue_worker(used_worker_ids: Dictionary, axis: StringName) -> ChickenState:
	var selected: ChickenState = null
	var selected_score := -INF
	for worker: ChickenState in workers:
		if used_worker_ids.has(worker.id):
			continue
		var score := 0.0
		match axis:
			&"trust":
				score = worker.manager_trust - worker.grievance * 0.65
			&"career":
				score = float(worker.career_xp * 4 + worker.eggs_laid)
			&"strain":
				score = worker.stress + worker.fatigue + worker.grievance * 0.5
		if selected == null or score > selected_score:
			selected = worker
			selected_score = score
	return selected


func _campaign_epilogue_entry(
	worker: ChickenState,
	caption: String,
	value: String,
	outcome: String,
	tone: StringName,
) -> Dictionary:
	return {
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"caption": caption,
		"value": value,
		"outcome": outcome,
		"tone": tone,
		"employed": worker.employed,
		"career_title": worker.career_title(),
		"relationship_label": worker.relationship_label(),
	}


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


# --- MarketContractDesk delegators: implementation lives in market_contract_desk.gd ---


func _service_coop_premium_bonus_cents(base_premium_cents: int, level: int) -> int:
	return _market_desk._service_coop_premium_bonus_cents(base_premium_cents, level)


func _neutral_market_season_for_day(target_day: int) -> Dictionary:
	return _market_desk._neutral_market_season_for_day(target_day)


func market_season_for_day(target_day: int) -> Dictionary:
	return _market_desk.market_season_for_day(target_day)


func market_contract_clause_catalog() -> Array[Dictionary]:
	return _market_desk.market_contract_clause_catalog()


func market_reach_points() -> int:
	return _market_desk.market_reach_points()


func _market_reach_for_outcomes(outcomes: Dictionary) -> int:
	return _market_desk._market_reach_for_outcomes(outcomes)


func mutual_market_share_basis_points() -> int:
	return _market_desk.mutual_market_share_basis_points()


func market_pricing_status() -> Dictionary:
	return _market_desk.market_pricing_status()


func market_contract_offer_catalog() -> Array[Dictionary]:
	return _market_desk.market_contract_offer_catalog()


func market_contract_offer_preflight(
	offer_id: StringName,
	clause_id: StringName = &"standard_terms",
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	return _market_desk.market_contract_offer_preflight(offer_id, clause_id, pricing_id)


func market_contract_board_status() -> Dictionary:
	return _market_desk.market_contract_board_status()


func sign_market_contract(
	offer_id: StringName,
	clause_id: StringName = &"standard_terms",
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	return _market_desk.sign_market_contract(offer_id, clause_id, pricing_id)


func decline_market_contract() -> Dictionary:
	return _market_desk.decline_market_contract()


func _market_contract_quote_for_day(
	offer_id: StringName,
	target_day: int,
	service_coop_level: int,
	negotiation_room_level: int,
	clause_id: StringName,
	force_neutral_terms: bool = false,
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	return _market_desk._market_contract_quote_for_day(offer_id, target_day, service_coop_level, negotiation_room_level, clause_id, force_neutral_terms, pricing_id)


func _build_market_contract_quote_for_day(
	offer_id: StringName,
	target_day: int,
	service_coop_level: int,
	negotiation_room_level: int,
	clause_id: StringName,
	force_neutral_terms: bool = false,
	pricing_id: StringName = &"mutual_rate",
) -> Dictionary:
	return _market_desk._build_market_contract_quote_for_day(offer_id, target_day, service_coop_level, negotiation_room_level, clause_id, force_neutral_terms, pricing_id)


func _pending_market_contract_claim_count() -> int:
	return _market_desk._pending_market_contract_claim_count()


func _release_due_market_contract_claims() -> int:
	return _market_desk._release_due_market_contract_claims()


func _record_market_contract_completion(claim: ClaimState, quality: StringName) -> void:
	_market_desk._record_market_contract_completion(claim, quality)


func _settle_market_contract(completed_day: int) -> Dictionary:
	return _market_desk._settle_market_contract(completed_day)


func current_market_contract_reserve_cents() -> int:
	return _market_desk.current_market_contract_reserve_cents()


func _apply_market_contract_claim_snapshot(claim_snapshot: Dictionary) -> void:
	_market_desk._apply_market_contract_claim_snapshot(claim_snapshot)


func current_claim_capacity() -> int:
	return (
		_claim_capacity_for_facilities(owned_facilities)
		+ _campus_claim_capacity_bonus_for_state(campus_expansion_state)
		+ _campus_portfolio.claim_capacity_bonus(_campus_portfolio_context())
		+ _internship_program.claim_capacity_bonus()
	)


func _claim_capacity_for_facilities(facilities: Dictionary) -> int:
	var records_level := clampi(
		int(facilities.get(RECORDS_ANNEX_ID, facilities.get(String(RECORDS_ANNEX_ID), 0))),
		0,
		int((FACILITY_DEFINITIONS[RECORDS_ANNEX_ID] as Dictionary).get("max_level", 3)),
	)
	return BASE_CLAIM_CAPACITY + CLAIM_CAPACITY_PER_RECORDS_LEVEL * records_level


func farm_mutual_standing() -> int:
	## Standing is a derived view over the exact settled-outcome ledgers. Keeping
	## it derived makes legacy v12 history count without introducing a second
	## mutable currency that could drift from fulfillment and breach receipts.
	return maxi(
		0,
		MARKET_STANDING_SUCCESS_POINTS * market_contracts_succeeded_total
		- MARKET_STANDING_BREACH_POINTS * market_contracts_breached_total,
	)


func farm_mutual_standing_rank() -> StringName:
	var standing := farm_mutual_standing()
	if standing >= 12:
		return &"gold"
	if standing >= 6:
		return &"silver"
	if standing >= 2:
		return &"bronze"
	return &"unlisted"


func farm_mutual_standing_rank_label() -> String:
	return String(farm_mutual_standing_rank()).to_upper()


func farm_mutual_next_standing_threshold() -> int:
	var standing := farm_mutual_standing()
	for threshold in SERVICE_COOP_LEVEL_STANDING_REQUIREMENTS:
		if standing < threshold:
			return threshold
	return 12


func _signed_half_up_ratio(numerator: int, denominator: int) -> int:
	## Money and market quotes never pass through floats. For negative values,
	## round the magnitude half-up and then restore the sign symmetrically.
	if denominator <= 0 or numerator == 0:
		return 0
	var sign := -1 if numerator < 0 else 1
	var magnitude := absi(numerator)
	@warning_ignore("integer_division")
	var half_denominator: int = denominator / 2
	@warning_ignore("integer_division")
	return sign * ((magnitude + half_denominator) / denominator)


func claimant_satisfaction_score() -> int:
	return _claimant_satisfaction_for_outcomes(market_pricing_outcomes)


func _claimant_satisfaction_for_outcomes(outcomes: Dictionary) -> int:
	var score := 50
	for pricing_id in MARKET_PRICING_PROFILE_ORDER:
		var definition := MARKET_PRICING_PROFILE_DEFINITIONS[pricing_id] as Dictionary
		score += (
			maxi(0, int(outcomes.get("%s_success" % String(pricing_id), 0)))
			* int(definition.get("satisfaction_success_delta", 0))
		)
		score += (
			maxi(0, int(outcomes.get("%s_breach" % String(pricing_id), 0)))
			* int(definition.get("satisfaction_breach_delta", 0))
		)
	return clampi(score, 0, 100)


func wellness_strain_gain_basis_points() -> int:
	return _facility_level_schedule_value(
		WELLNESS_STRAIN_GAIN_BASIS_POINTS,
		facility_level(WELLNESS_NEST_ID),
		10_000,
	)


func wellness_strain_gain_multiplier() -> float:
	return float(wellness_strain_gain_basis_points()) / 10_000.0


func wellness_break_recovery_basis_points() -> int:
	return _facility_level_schedule_value(
		WELLNESS_BREAK_RECOVERY_BASIS_POINTS,
		facility_level(WELLNESS_NEST_ID),
		10_000,
	)


func wellness_break_recovery_multiplier() -> float:
	return float(wellness_break_recovery_basis_points()) / 10_000.0


func wellness_break_morale_millipoints() -> int:
	return _facility_level_schedule_value(
		WELLNESS_BREAK_MORALE_MILLIPOINTS,
		facility_level(WELLNESS_NEST_ID),
		0,
	)


func wellness_overnight_fatigue_recovery_millipoints() -> int:
	return _facility_level_schedule_value(
		WELLNESS_OVERNIGHT_FATIGUE_RECOVERY_MILLIPOINTS,
		facility_level(WELLNESS_NEST_ID),
		24_000,
	)


func wellness_overnight_stress_recovery_millipoints() -> int:
	return _facility_level_schedule_value(
		WELLNESS_OVERNIGHT_STRESS_RECOVERY_MILLIPOINTS,
		facility_level(WELLNESS_NEST_ID),
		10_000,
	)


func _apply_overnight_recovery(worker: ChickenState) -> void:
	worker.fatigue = maxf(
		0.0,
		worker.fatigue - float(wellness_overnight_fatigue_recovery_millipoints()) / 1000.0,
	)
	worker.stress = maxf(
		0.0,
		worker.stress - float(wellness_overnight_stress_recovery_millipoints()) / 1000.0,
	)


func career_sponsorship_cost_cents() -> int:
	return _facility_level_schedule_value(
		TRAINING_SPONSORSHIP_COSTS_CENTS,
		facility_level(TRAINING_ROOST_ID),
		CAREER_SPONSORSHIP_COST_CENTS,
	)


func pending_training_work_basis_points() -> int:
	return _facility_level_schedule_value(
		TRAINING_WORK_BASIS_POINTS,
		facility_level(TRAINING_ROOST_ID),
		roundi(ChickenState.CROSS_TRAINING_WORK_MULTIPLIER * 10_000.0),
	)


func pending_training_work_multiplier() -> float:
	return float(pending_training_work_basis_points()) / 10_000.0


func career_coaching_xp_bonus() -> int:
	return _facility_level_schedule_value(
		TRAINING_COACHING_XP_BONUS,
		facility_level(TRAINING_ROOST_ID),
		0,
	)


func personnel_action_limit() -> int:
	return _facility_level_schedule_value(
		ROOSTER_PERSONNEL_ACTION_LIMITS,
		facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		1,
	)


func supervisor_payroll_cents() -> int:
	var authorized_payroll := _facility_level_schedule_value(
		ROOSTER_SUPERVISOR_PAYROLL_CENTS,
		facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		0,
	)
	var promotion_premium := 0
	for manager in manager_roster:
		promotion_premium += maxi(0, int(manager.get("rank", 0))) * 100
	return authorized_payroll + promotion_premium


func manager_capacity() -> int:
	return clampi(facility_level(ROOSTER_OPERATIONS_OFFICE_ID) + 1, 1, 4)


func set_manager_assignment(manager_id: StringName, assignment_id: StringName) -> Dictionary:
	return _file_manager_instruction(manager_id, assignment_id, true)


func set_manager_posture(manager_id: StringName, posture_id: StringName) -> Dictionary:
	return _file_manager_instruction(manager_id, posture_id, false)


func recruit_manager(candidate_id: StringName) -> Dictionary:
	var definition := MANAGER_CANDIDATE_DEFINITIONS.get(candidate_id, {}) as Dictionary
	if definition.is_empty():
		return {"accepted": false, "reason": "That rooster is not in the screened management slate."}
	if not staffing_planning_open():
		return {"accepted": false, "reason": "Management appointments can only be filed during review."}
	if manager_roster.size() < 2:
		return {"accepted": false, "reason": "Commission Rooster Operations level 1 before appointing a successor."}
	for manager in manager_roster:
		if StringName(String(manager.get("candidate_id", ""))) == candidate_id:
			return {"accepted": false, "reason": "%s is already drawing supervisor payroll." % String(definition.get("name", "That rooster"))}
	var signing_cost := maxi(0, int(definition.get("signing_cost_cents", 0)))
	if spendable_fund_cents() < signing_cost:
		return {"accepted": false, "reason": "The succession filing needs $%.2f in spendable Feed Fund." % (float(signing_cost) / 100.0)}
	var slot_index := manager_roster.size() - 1
	var departing := manager_roster[slot_index]
	var departing_name := _manager_display_name(departing)
	var fund_before := revenue_cents
	revenue_cents -= signing_cost
	manager_roster[slot_index] = _new_manager_record(candidate_id, slot_index, day)
	last_manager_action = {
		"accepted": true,
		"action_id": &"manager_recruited",
		"manager_id": candidate_id,
		"choice_id": candidate_id,
		"day": day,
		"cost_cents": signing_cost,
		"fund_before_cents": fund_before,
		"fund_after_cents": revenue_cents,
		"replaced_manager_id": StringName(String(departing.get("candidate_id", ""))),
		"outcome": "%s appointed to the newest management post; %s has been strategically exited." % [
			String(definition.get("name", "A rooster")), departing_name,
		],
	}
	manager_action_resolved.emit(last_manager_action.duplicate(true))
	announcement_posted.emit(String(last_manager_action["outcome"]))
	snapshot_changed.emit(snapshot())
	return last_manager_action.duplicate(true)


func _file_manager_instruction(manager_id: StringName, choice_id: StringName, assignment: bool) -> Dictionary:
	var catalog := MANAGER_ASSIGNMENT_DEFINITIONS if assignment else MANAGER_POSTURE_DEFINITIONS
	var field := "assignment_id" if assignment else "posture_id"
	var action_id: StringName = &"manager_assignment" if assignment else &"manager_posture"
	if not catalog.has(choice_id):
		return {"accepted": false, "reason": "That management filing does not exist."}
	if not staffing_planning_open():
		return {"accepted": false, "reason": "Management instructions can only be filed during planning or review."}
	for manager in manager_roster:
		if StringName(String(manager.get("id", ""))) != manager_id:
			continue
		manager[field] = String(choice_id)
		if not assignment:
			manager["posture_filed"] = true
		manager["interventions"] = maxi(0, int(manager.get("interventions", 0))) + 1
		last_manager_action = {
			"accepted": true,
			"action_id": action_id,
			"manager_id": manager_id,
			"choice_id": choice_id,
			"day": day,
			"outcome": "%s filed %s." % [
				_manager_display_name(manager), String((catalog[choice_id] as Dictionary).get("label", choice_id))
			],
		}
		manager_action_resolved.emit(last_manager_action.duplicate(true))
		snapshot_changed.emit(snapshot())
		return last_manager_action.duplicate(true)
	return {"accepted": false, "reason": "That manager is not on the active roster."}


func rooster_surveillance_grievance_millipoints() -> int:
	return _facility_level_schedule_value(
		ROOSTER_SURVEILLANCE_GRIEVANCE_MILLIPOINTS,
		facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		0,
	)


func rooster_surveillance_stress_millipoints() -> int:
	return _facility_level_schedule_value(
		ROOSTER_SURVEILLANCE_STRESS_MILLIPOINTS,
		facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		0,
	)


func rooster_surveillance_solidarity_millipoints() -> int:
	return _facility_level_schedule_value(
		ROOSTER_SURVEILLANCE_SOLIDARITY_MILLIPOINTS,
		facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		0,
	)


func automation_work_basis_points() -> int:
	return _facility_level_schedule_value(
		IT_AUTO_WORK_BASIS_POINTS,
		facility_level(IT_COOP_ID),
		10_000,
	)


func automation_work_multiplier(worker: ChickenState = null) -> float:
	if worker != null and worker.assigned_lane != AUTO_ASSIGNMENT:
		return 1.0
	return float(automation_work_basis_points()) / 10_000.0


func automation_specialty_grace_minutes() -> int:
	return _facility_level_schedule_value(
		IT_AUTO_SPECIALTY_GRACE_MINUTES,
		facility_level(IT_COOP_ID),
		AUTO_SPECIALTY_GRACE_MINUTES,
	)


func automation_recognizes_secondary_specialties() -> bool:
	return facility_level(IT_COOP_ID) > 0


func automation_compliance_exposure_millipoints() -> int:
	return _facility_level_schedule_value(
		IT_COMPLIANCE_EXPOSURE_MILLIPOINTS,
		facility_level(IT_COOP_ID),
		0,
	)


func ledger_molt_patch_cost_cents() -> int:
	return _facility_level_schedule_value(
		IT_LEDGER_PATCH_COSTS_CENTS,
		facility_level(IT_COOP_ID),
		1800,
	)


func ledger_molt_spreadsheet_compliance_loss_millipoints() -> int:
	return _facility_level_schedule_value(
		IT_SPREADSHEET_COMPLIANCE_LOSS_MILLIPOINTS,
		facility_level(IT_COOP_ID),
		6000,
	)


func ledger_molt_spreadsheet_crack_basis_points() -> int:
	return _facility_level_schedule_value(
		IT_SPREADSHEET_CRACK_BASIS_POINTS,
		facility_level(IT_COOP_ID),
		600,
	)


# --- FlockRelationsDesk delegators: implementation lives in flock_relations_desk.gd ---
func flock_relations_case_capacity() -> int:
	return _flock_desk.flock_relations_case_capacity()


func flock_relations_resolution_limit() -> int:
	return _flock_desk.flock_relations_resolution_limit()


func _resolve_flock_restructuring(option_id: StringName) -> bool:
	return _flock_desk._resolve_flock_restructuring(option_id)


func _build_flock_petition_decision() -> Dictionary:
	return _flock_desk._build_flock_petition_decision()


func _can_apply_flock_petition_response(option_id: StringName, chosen: Dictionary) -> bool:
	return _flock_desk._can_apply_flock_petition_response(option_id, chosen)


func _apply_flock_petition_response(option_id: StringName, chosen: Dictionary) -> Dictionary:
	return _flock_desk._apply_flock_petition_response(option_id, chosen)


func _breach_compact_for_sponsor_release(worker_id: int) -> bool:
	return _flock_desk._breach_compact_for_sponsor_release(worker_id)


func _breach_specialty_compact_for_assignment(worker: ChickenState) -> bool:
	return _flock_desk._breach_specialty_compact_for_assignment(worker)


func _breach_safe_pace_compact(reason: StringName) -> bool:
	return _flock_desk._breach_safe_pace_compact(reason)


func _resolve_due_flock_compact(completed_day: int) -> Dictionary:
	return _flock_desk._resolve_due_flock_compact(completed_day)


func flock_relations_snapshot() -> Dictionary:
	return _flock_desk.flock_relations_snapshot()


func _flock_relations_action_cost_cents(action_id: StringName, severity: int) -> int:
	return _flock_desk._flock_relations_action_cost_cents(action_id, severity)


func resolve_flock_relations_case(case_id: int, action_id: StringName) -> Dictionary:
	return _flock_desk.resolve_flock_relations_case(case_id, action_id)


func _flock_relations_case_title(case_type: StringName) -> String:
	return _flock_desk._flock_relations_case_title(case_type)


func _flock_relations_case_severity(risk_score: int) -> int:
	return _flock_desk._flock_relations_case_severity(risk_score)


func _file_flock_relations_case_after_shift(completed_day: int) -> Array[Dictionary]:
	return _flock_desk._file_flock_relations_case_after_shift(completed_day)


func _apply_flock_relations_carry_penalties(completed_day: int) -> Array[Dictionary]:
	return _flock_desk._apply_flock_relations_carry_penalties(completed_day)


func _farmgate_base_storage_capacity_eggs() -> int:
	return _facility_level_schedule_value(
		FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS,
		facility_level(FARMGATE_DISPATCH_DEPOT_ID),
		0,
	)


func _farmgate_storage_capacity_eggs() -> int:
	return _farmgate_storage_capacity_for_level_and_campus(
		facility_level(FARMGATE_DISPATCH_DEPOT_ID),
		campus_expansion_state,
		_campus_portfolio.farmgate_capacity_bonus_eggs(_campus_portfolio_context()),
	)


func _farmgate_dispatch_capacity_eggs() -> int:
	return _facility_level_schedule_value(
		FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS,
		facility_level(FARMGATE_DISPATCH_DEPOT_ID),
		0,
	)


func _farmgate_shelf_life_shifts() -> int:
	return _facility_level_schedule_value(
		FARMGATE_DISPATCH_SHELF_LIFE_SHIFTS,
		facility_level(FARMGATE_DISPATCH_DEPOT_ID),
		0,
	)


# --- SimulationSaveCodec delegators: implementation lives in simulation_save_codec.gd ---
func export_save_state() -> Dictionary:
	return _save_codec.export_save_state()


func restore_save_state(data: Dictionary) -> bool:
	return _save_codec.restore_save_state(data)


func _validated_incident_response_history(value: Variant, saved_day: int) -> Dictionary:
	return _save_codec._validated_incident_response_history(value, saved_day)


func current_daily_portfolio_cost_cents() -> int:
	return _campus_portfolio.daily_cost_cents()


func capital_plan_snapshot() -> Dictionary:
	var status: Dictionary = {}
	if pinned_capital_plan_id != &"" and FACILITY_DEFINITIONS.has(pinned_capital_plan_id):
		status = facility_status(pinned_capital_plan_id)
	return {
		"pinned_capital_plan_id": pinned_capital_plan_id,
		"has_pinned_plan": pinned_capital_plan_id != &"",
		"facility": status,
		"last_facility_purchase_receipt": last_facility_purchase_receipt.duplicate(true),
		"commissioning_history": facility_commissioning_history.duplicate(true),
	}


func pin_economic_watch(watch_id: StringName) -> Dictionary:
	if watch_id not in ECONOMIC_WATCH_ORDER:
		return {
			"accepted": false,
			"action_id": &"pin_economic_watch",
			"watch_id": watch_id,
			"reason": "That watch is not on the filed management schedule.",
		}
	pinned_economic_watch_id = watch_id
	var receipt := {
		"accepted": true,
		"action_id": &"pin_economic_watch",
		"watch_id": watch_id,
		"reason": "",
	}
	snapshot_changed.emit(snapshot())
	return receipt


func pin_capital_plan(facility_id: StringName) -> Dictionary:
	if not FACILITY_DEFINITIONS.has(facility_id):
		return {
			"accepted": false,
			"action_id": &"pin_capital_plan",
			"facility_id": facility_id,
			"reason": "Facility code is not on the authorized capital schedule.",
		}
	var status := facility_status(facility_id)
	if bool(status.get("maxed", false)):
		return {
			"accepted": false,
			"action_id": &"pin_capital_plan",
			"facility_id": facility_id,
			"reason": "%s is already fully commissioned." % String(status.get("short_name", "FACILITY")),
		}
	pinned_capital_plan_id = facility_id
	var receipt := {
		"accepted": true,
		"action_id": &"pin_capital_plan",
		"facility_id": facility_id,
		"reason": "",
		"capital_plan": capital_plan_snapshot(),
	}
	snapshot_changed.emit(snapshot())
	return receipt


func clear_capital_plan() -> Dictionary:
	var previous_id := pinned_capital_plan_id
	pinned_capital_plan_id = &""
	var receipt := {
		"accepted": true,
		"action_id": &"clear_capital_plan",
		"facility_id": previous_id,
		"reason": "",
		"capital_plan": capital_plan_snapshot(),
	}
	snapshot_changed.emit(snapshot())
	return receipt


func packing_contract_status() -> Dictionary:
	var level := maxi(0, facility_level(PACKING_ANNEX_ID))
	var enabled := level > 0
	var value_bonus_percent := roundi(
		PACKING_VALUE_BONUS_PER_LEVEL * level * 100.0
	)
	var next_carton_bonus_cents := (
		PACKING_CARTON_BONUS_PER_LEVEL_CENTS * level if enabled else 0
	)
	return {
		"facility_id": PACKING_ANNEX_ID,
		"enabled": enabled,
		"level": level,
		"carton_size": PACKING_CARTON_SIZE,
		"carton_progress": packing_carton_progress,
		"good_eggs_until_carton": (
			PACKING_CARTON_SIZE - packing_carton_progress
			if enabled else
			PACKING_CARTON_SIZE
		),
		"cartons_today": packing_cartons_today,
		"cartons_total": packing_cartons_total,
		"value_bonus_percent": value_bonus_percent,
		"value_multiplier": 1.0 + PACKING_VALUE_BONUS_PER_LEVEL * level,
		"value_bonus_today_cents": packing_value_bonus_today_cents,
		"value_bonus_total_cents": packing_value_bonus_total_cents,
		"carton_bonus_today_cents": packing_carton_bonus_today_cents,
		"carton_bonus_total_cents": packing_carton_bonus_total_cents,
		"contract_credit_today_cents": (
			packing_value_bonus_today_cents + packing_carton_bonus_today_cents
		),
		"contract_credit_total_cents": (
			packing_value_bonus_total_cents + packing_carton_bonus_total_cents
		),
		"next_carton_bonus_cents": next_carton_bonus_cents,
	}


func farm_mutual_standing_status() -> Dictionary:
	var standing := farm_mutual_standing()
	var next_threshold := farm_mutual_next_standing_threshold()
	var seals: Array[Dictionary] = []
	for seal_value in [
		{ "id": &"bronze", "label": "BRONZE", "threshold": 2 },
		{ "id": &"silver", "label": "SILVER", "threshold": 6 },
		{ "id": &"gold", "label": "GOLD", "threshold": 12 },
	]:
		var seal := (seal_value as Dictionary).duplicate(true)
		seal["earned"] = standing >= int(seal["threshold"])
		seals.append(seal)
	return {
		"points": standing,
		"rank": farm_mutual_standing_rank(),
		"rank_label": farm_mutual_standing_rank_label(),
		"next_threshold": next_threshold,
		"points_to_next": maxi(0, next_threshold - standing),
		"clean_streak": market_clean_contract_streak,
		"best_clean_streak": best_market_clean_contract_streak,
		"seals": seals,
	}


func farm_mutual_service_coop_status() -> Dictionary:
	var status := facility_status(FARM_MUTUAL_SERVICE_COOP_ID)
	var level := maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID))
	return {
		"facility_id": FARM_MUTUAL_SERVICE_COOP_ID,
		"level": level,
		"max_level": 3,
		"premium_bonus_basis_points": (
			level * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"premium_bonus_percent": level * 50,
		"current_maintenance_cents": int(status.get("current_maintenance_cents", 0)),
		"next_level": int(status.get("next_level", level)),
		"next_required_standing": int(status.get("required_market_standing", 0)),
		"next_required_claim_capacity": int(status.get("required_claim_capacity", 0)),
		"next_required_active_staff": int(status.get("required_active_staff", 0)),
		"status": status,
	}


func farm_mutual_negotiation_room_status() -> Dictionary:
	var status := facility_status(FARM_MUTUAL_NEGOTIATION_ROOM_ID)
	var level := maxi(0, facility_level(FARM_MUTUAL_NEGOTIATION_ROOM_ID))
	return {
		"facility_id": FARM_MUTUAL_NEGOTIATION_ROOM_ID,
		"level": level,
		"owned": level > 0,
		"unlocked": level > 0,
		"can_negotiate": level > 0,
		"max_level": 1,
		"clause_limit": 1 if level > 0 else 0,
		"max_clause_slots": 1,
		"available_clauses": market_contract_clause_catalog(),
		"current_maintenance_cents": int(status.get("current_maintenance_cents", 0)),
		"required_market_standing": NEGOTIATION_ROOM_REQUIRED_STANDING,
		"required_service_coop_level": NEGOTIATION_ROOM_REQUIRED_SERVICE_COOP_LEVEL,
		"can_purchase": bool(status.get("can_purchase", false)),
		"reason": (
			"Negotiation Room commissioned; one clause slot is available per binder."
			if level > 0 else
			String(status.get("reason", "Negotiation Room is not yet commissioned."))
		),
		"status": status,
	}


func _apply_packing_contract_value(
	quality: StringName,
	graded_value_cents: int
) -> Dictionary:
	## The annex only brands sound product. The percentage premium is applied to
	## the graded claim value before flat policy, Priority Peck, and streak credit;
	## the sixth good egg then carries the exact carton settlement in its receipt.
	var level := maxi(0, facility_level(PACKING_ANNEX_ID))
	var value_cents := maxi(0, graded_value_cents)
	var receipt := {
		"eligible": false,
		"level": level,
		"quality": quality,
		"graded_value_cents": value_cents,
		"value_bonus_cents": 0,
		"carton_bonus_cents": 0,
		"carton_completed": false,
		"carton_progress": packing_carton_progress,
		"value_cents": value_cents,
	}
	if level <= 0 or quality not in [&"sound", &"golden"]:
		return receipt

	var value_bonus_cents := roundi(
		value_cents * PACKING_VALUE_BONUS_PER_LEVEL * level
	)
	value_cents += value_bonus_cents
	packing_value_bonus_today_cents += value_bonus_cents
	packing_value_bonus_total_cents += value_bonus_cents
	packing_carton_progress += 1
	var carton_bonus_cents := 0
	var carton_completed := false
	if packing_carton_progress >= PACKING_CARTON_SIZE:
		packing_carton_progress -= PACKING_CARTON_SIZE
		packing_cartons_today += 1
		packing_cartons_total += 1
		carton_bonus_cents = PACKING_CARTON_BONUS_PER_LEVEL_CENTS * level
		packing_carton_bonus_today_cents += carton_bonus_cents
		packing_carton_bonus_total_cents += carton_bonus_cents
		value_cents += carton_bonus_cents
		carton_completed = true
		announcement_posted.emit(
			"BRANDED CARTON CLOSED: six flock-produced eggs earned $%.2f under the farmer's label." % (
				float(carton_bonus_cents) / 100.0
			)
		)
	receipt.merge({
		"eligible": true,
		"value_bonus_cents": value_bonus_cents,
		"carton_bonus_cents": carton_bonus_cents,
		"carton_completed": carton_completed,
		"carton_progress": packing_carton_progress,
		"value_cents": value_cents,
	}, true)
	return receipt


func active_worker_count() -> int:
	var count := 0
	for worker in workers:
		if worker.employed:
			count += 1
	return count


func current_daily_hen_payroll_cents() -> int:
	var payroll := 0
	for worker in workers:
		if worker.employed:
			payroll += worker.daily_wage_cents()
	return payroll


func current_daily_supervisor_payroll_cents() -> int:
	return supervisor_payroll_cents()


func current_daily_fellow_payroll_cents() -> int:
	return _internship_program.daily_fellow_payroll_cents()


func current_daily_payroll_cents() -> int:
	return (
		current_daily_hen_payroll_cents()
		+ current_daily_supervisor_payroll_cents()
		+ current_daily_fellow_payroll_cents()
	)


func current_daily_operating_cost_cents() -> int:
	return (
		current_daily_feed_cost_cents()
		+ current_daily_facility_cost_cents()
		+ current_daily_payroll_cents()
	)


func farm_treasury_snapshot() -> Dictionary:
	## One canonical projection backs staffing, farmer review, web diagnostics, and
	## save inspection. The revolving line responds to current Farm Mutual standing,
	## while filed principal, invoices, and interest remain durable obligations.
	var projection: Dictionary = _farm_treasury.snapshot(maxi(0, farm_mutual_standing()))
	projection["capital_frozen"] = (
		int(projection.get("total_liabilities_cents", 0)) > 0
		and int(projection.get("credit_headroom_cents", 0)) <= 0
	)
	projection["interest_percent"] = float(
		int(projection.get("interest_basis_points", 0))
	) / 100.0
	projection["rating_label"] = ["FIELD FILE", "STEADY LEDGER", "PRIME ROOST"][clampi(
		int(projection.get("credit_rating", 0)),
		0,
		2,
	)]
	return projection


func farm_treasury_liabilities_cents() -> int:
	return maxi(0, _farm_treasury.total_liabilities_cents())


func farm_treasury_capital_frozen() -> bool:
	return (
		_farm_treasury.total_liabilities_cents() > 0
		and _farm_treasury.credit_headroom_cents(maxi(0, farm_mutual_standing())) <= 0
	)


func protected_reserve_cents() -> int:
	return (
		current_daily_operating_cost_cents()
		+ wage_arrears_cents
		+ current_market_contract_reserve_cents()
		+ farm_treasury_liabilities_cents()
	)


func spendable_fund_cents() -> int:
	## Discretionary actions may only spend money left after today's operating
	## obligations, signed breach exposure, unpaid wages, and filed treasury debt
	## are protected. An exhausted revolving line freezes capital requisitions.
	if farm_treasury_capital_frozen():
		return 0
	return maxi(
		0,
		revenue_cents - protected_reserve_cents()
	)


## One authoritative read model for the economic information that used to be
## scattered across Today, staffing, procurement, contracts, and Capital. It is
## derived entirely from owned simulation state: the UI may format these rows but
## never recompute prices, reserves, margins, trends, or bottleneck severity.
func economic_briefing_snapshot(contract_board_basis: Dictionary = {}) -> Dictionary:
	var treasury := farm_treasury_snapshot()
	var procurement := feed_procurement_snapshot()
	# A bundle already owns this exact read. Reuse it within this publication;
	# public standalone callers still build their own independent result.
	var contract_board := contract_board_basis if not contract_board_basis.is_empty() else market_contract_board_status()
	var operating_cost := current_daily_operating_cost_cents()
	var secured_income := maxi(0, credited_today_cents)
	var secured_margin := secured_income - operating_cost
	var break_even_remaining := maxi(0, -secured_margin)
	var current_season := market_season_for_day(day)
	var next_market_day := maxi(
		day + 1,
		int(current_season.get("end_day", day)) + 1,
	)
	var next_season := market_season_for_day(next_market_day)
	var current_demand := current_season.get("lane_demand_basis_points", {}) as Dictionary
	var next_demand := next_season.get("lane_demand_basis_points", {}) as Dictionary
	var opportunity_lane := _economic_highest_demand_lane(current_demand)
	var next_opportunity_lane := _economic_highest_demand_lane(next_demand)
	var history := _economic_history_rows(treasury.get("history", []) as Array)
	var trend := _economic_trend_snapshot(history)
	var bottlenecks := _economic_bottleneck_rows(
		treasury,
		procurement,
		secured_margin,
	)
	var recovery_actions := _economic_recovery_rows(
		treasury,
		procurement,
		contract_board,
	)
	var status_id: StringName = &"stable"
	var status_label := "OPERATING ROOM"
	if wage_arrears_cents > 0 or bool(treasury.get("capital_frozen", false)):
		status_id = &"critical"
		status_label = "RECOVERY REQUIRED"
	elif spendable_fund_cents() <= 0 or secured_margin < 0:
		status_id = &"tight"
		status_label = "MARGIN TIGHT"
	var economic_watches := _economic_watch_rows(
		treasury,
		procurement,
		secured_margin,
		bottlenecks,
	)
	var selected_watch: Dictionary = {}
	for watch: Dictionary in economic_watches:
		if StringName(watch.get("id", &"")) == pinned_economic_watch_id:
			selected_watch = watch.duplicate(true)
			break
	if selected_watch.is_empty() and not economic_watches.is_empty():
		selected_watch = economic_watches[0].duplicate(true)

	return {
		"version": 4,
		"day": day,
		"status_id": status_id,
		"status_label": status_label,
		"cash": {
			"feed_fund_cents": revenue_cents,
			"protected_reserve_cents": protected_reserve_cents(),
			"spendable_fund_cents": spendable_fund_cents(),
			"secured_income_today_cents": secured_income,
			"daily_operating_cost_cents": operating_cost,
			"secured_operating_margin_cents": secured_margin,
			"break_even_remaining_cents": break_even_remaining,
			"contract_breach_reserve_cents": current_market_contract_reserve_cents(),
			"wage_arrears_cents": wage_arrears_cents,
		},
		"costs": {
			"feed_cents": current_daily_feed_cost_cents(),
			"hen_payroll_cents": current_daily_hen_payroll_cents(),
			"supervisor_payroll_cents": current_daily_supervisor_payroll_cents(),
			"fellow_payroll_cents": current_daily_fellow_payroll_cents(),
			"expanded_perches_cents": daily_facility_expansion_cost_cents(),
			"facility_maintenance_cents": current_daily_facility_maintenance_cents(),
			"campus_services_cents": current_daily_campus_cost_cents(),
			"portfolio_operations_cents": current_daily_portfolio_cost_cents(),
		},
		"market": {
			"current": current_season.duplicate(true),
			"next": next_season.duplicate(true),
			"current_cause": String(current_season.get(
				"summary",
				"Farm Mutual's filed calendar sets the current book.",
			)),
			"current_days_remaining": maxi(
				0,
				int(current_season.get("days_remaining", 0)),
			),
			"forecast_certainty": "GUARANTEED CALENDAR",
			"forecast_uncertainty": (
				"The season and spot quote are filed; seeded file mix can still vary."
			),
			"next_market_day": next_market_day,
			"opportunity_lane_id": opportunity_lane,
			"opportunity_lane_label": _lane_display_name(opportunity_lane),
			"opportunity_demand_basis_points": int(
				current_demand.get(opportunity_lane, 0)
			),
			"next_opportunity_lane_id": next_opportunity_lane,
			"next_opportunity_lane_label": _lane_display_name(next_opportunity_lane),
			"next_opportunity_demand_basis_points": int(
				next_demand.get(next_opportunity_lane, 0)
			),
			"feed_spot_unit_price_cents": _feed_spot_unit_price_cents(day),
			"next_feed_spot_unit_price_cents": _feed_spot_unit_price_cents(
				next_market_day
			),
		},
		"capacity": {
			"live_files": _outstanding_claim_count(),
			"live_file_limit": current_claim_capacity(),
			"files_waiting": claims_waiting,
			"overdue_files": _overdue_claim_count(true),
			"rework_files": _queued_rework_count() + _active_rework_count(),
			"turned_away_today": intake_rejections_today,
			"missed_value_today_cents": intake_missed_value_today_cents,
			"active_staff": active_worker_count(),
			"staff_capacity": office_capacity,
		},
		"resources": _economic_resource_rows(treasury, procurement),
		"strategies": _economic_strategy_rows(),
		"bottlenecks": bottlenecks,
		"recovery_actions": recovery_actions,
		"history": history,
		"trend": trend,
		"management_watch": {
			"selected_id": pinned_economic_watch_id,
			"selected": selected_watch,
			"catalog": economic_watches,
		},
	}


func _economic_highest_demand_lane(demand: Dictionary) -> StringName:
	var selected: StringName = CLAIM_LANES[0]
	var selected_basis_points := int(demand.get(selected, 10_000))
	for lane: StringName in CLAIM_LANES:
		var lane_basis_points := int(demand.get(lane, 10_000))
		if lane_basis_points > selected_basis_points:
			selected = lane
			selected_basis_points = lane_basis_points
	return selected


func _economic_history_rows(source: Array) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var start_index := maxi(0, source.size() - 5)
	for index: int in range(start_index, source.size()):
		if not source[index] is Dictionary:
			continue
		var receipt := source[index] as Dictionary
		var liabilities := (
			int(receipt.get("closing_credit_principal_cents", 0))
			+ int(receipt.get("closing_vendor_arrears_cents", 0))
			+ int(receipt.get("closing_interest_arrears_cents", 0))
		)
		rows.append({
			"day": int(receipt.get("day", 0)),
			"inflow_cents": int(receipt.get("inflow_cents", 0)),
			"vendor_due_cents": int(receipt.get("total_vendor_due_cents", 0)),
			"labor_due_cents": int(receipt.get("labor_due_cents", 0)),
			"interest_cents": int(receipt.get("interest_charged_cents", 0)),
			"operating_margin_cents": int(receipt.get("operating_margin_cents", 0)),
			"closing_cash_cents": int(receipt.get("closing_cash_cents", 0)),
			"closing_liabilities_cents": liabilities,
			"profitable": bool(receipt.get("profitable", false)),
			"debt_free": bool(receipt.get("debt_free", false)),
		})
	return rows


func _economic_trend_snapshot(history: Array[Dictionary]) -> Dictionary:
	if history.is_empty():
		return {
			"status_id": &"awaiting_close",
			"status_label": "AWAITING FIRST CLOSE",
			"margin_change_cents": 0,
			"average_margin_cents": 0,
			"sample_count": 0,
		}
	var margin_total := 0
	for row: Dictionary in history:
		margin_total += int(row.get("operating_margin_cents", 0))
	var margin_change := 0
	if history.size() > 1:
		margin_change = (
			int(history[-1].get("operating_margin_cents", 0))
			- int(history[-2].get("operating_margin_cents", 0))
		)
	var status_id: StringName = &"steady"
	var status_label := "STEADY"
	if margin_change >= 100:
		status_id = &"improving"
		status_label = "IMPROVING"
	elif margin_change <= -100:
		status_id = &"tightening"
		status_label = "TIGHTENING"
	return {
		"status_id": status_id,
		"status_label": status_label,
		"margin_change_cents": margin_change,
		"average_margin_cents": _signed_half_up_ratio(
			margin_total,
			history.size(),
		),
		"sample_count": history.size(),
	}


func _economic_watch_rows(
	treasury: Dictionary,
	procurement: Dictionary,
	secured_margin: int,
	bottlenecks: Array[Dictionary],
) -> Array[Dictionary]:
	var primary_bottleneck := (
		bottlenecks[0]
		if not bottlenecks.is_empty() else
		{
			"label": "NO CRITICAL BOTTLENECK",
			"reason": "Current systems remain inside their filed limits.",
			"action": "Compare the next disclosed tradeoff.",
		}
	)
	var feed_stock := maxi(0, int(procurement.get("stock_scoops", 0)))
	var feed_demand := maxi(0, int(procurement.get("demand_scoops", 0)))
	var feed_shortage := maxi(0, int(procurement.get("spot_shortage_scoops", 0)))
	var live_files := _outstanding_claim_count()
	var live_capacity := current_claim_capacity()
	var capacity_percent := _signed_half_up_ratio(10_000 * live_files, maxi(1, live_capacity))
	var welfare := _flock_welfare_score()
	var reach := market_reach_points()
	var satisfaction := claimant_satisfaction_score()
	var share_basis_points := mutual_market_share_basis_points()
	var executive_select_open := (
		reach >= MARKET_PRICING_EXECUTIVE_REACH_REQUIREMENT
		and satisfaction >= MARKET_PRICING_EXECUTIVE_SATISFACTION_MINIMUM
	)
	var treasury_liabilities := maxi(0, int(treasury.get("total_liabilities_cents", 0)))
	return [
		{
			"id": &"auto",
			"label": "AUTO / PRIMARY CONSTRAINT",
			"status_id": &"clear" if int(primary_bottleneck.get("severity", 0)) <= 0 else &"attention",
			"status_label": String(primary_bottleneck.get("label", "CURRENT PRIORITY")),
			"current_label": "HIGHEST FILED PRIORITY",
			"target_label": "RESOLVE OR REASSESS",
			"why": String(primary_bottleneck.get("reason", "")),
			"action": String(primary_bottleneck.get("action", "")),
			"page_id": _economic_watch_page_for_bottleneck(
				StringName(primary_bottleneck.get("id", &"clear"))
			),
		},
		{
			"id": &"margin",
			"label": "SECURED MARGIN",
			"status_id": &"on_track" if secured_margin >= 0 else &"attention",
			"status_label": "BREAK-EVEN FILED" if secured_margin >= 0 else "BELOW BREAK-EVEN",
			"current_label": "%s$%.2f" % [
				"+" if secured_margin >= 0 else "-",
				absf(float(secured_margin)) / 100.0,
			],
			"target_label": "$0.00 OR BETTER",
			"why": (
				"Secured egg credit is compared with every filed operating cost; "
				+ "unearned eggs and binder premiums remain excluded."
			),
			"action": (
				"Finish sound work before optional spending. Review Treasury if "
				+ "$%.2f in liabilities constrains recovery." % (
					float(treasury_liabilities) / 100.0
				)
			),
			"page_id": &"capital",
		},
		{
			"id": &"feed",
			"label": "FEED COVERAGE",
			"status_id": &"on_track" if feed_shortage <= 0 else &"attention",
			"status_label": "RATION COVERED" if feed_shortage <= 0 else "SPOT EXPOSURE",
			"current_label": "%d STOCK / %d NEEDED" % [feed_stock, feed_demand],
			"target_label": "%d+ SCOOPS" % feed_demand,
			"why": (
				"%d scoops are exposed to the current spot quote after stored lots."
				% feed_shortage
			),
			"action": (
				"Open Ops during review to compare lot price, shelf life, capacity, "
				+ "and flock strain before authorizing Provisions."
			),
			"page_id": &"operations",
		},
		{
			"id": &"capacity",
			"label": "LIVE-FILE CAPACITY",
			"status_id": (
				&"attention"
				if intake_rejections_today > 0 or capacity_percent >= 8_500 else
				&"on_track"
			),
			"status_label": (
				"DEMAND TURNED AWAY"
				if intake_rejections_today > 0 else
				("NEAR LIMIT" if capacity_percent >= 8_500 else "ROOM AVAILABLE")
			),
			"current_label": "%d / %d FILES" % [live_files, live_capacity],
			"target_label": "BELOW 85%% / %d FILES" % _signed_half_up_ratio(
				85 * live_capacity,
				100,
			),
			"why": (
				"%d%% occupied; %d files worth $%.2f were turned away today."
				% [
					_signed_half_up_ratio(100 * live_files, maxi(1, live_capacity)),
					intake_rejections_today,
					float(intake_missed_value_today_cents) / 100.0,
				]
			),
			"action": (
				"Open Capital to compare Records capacity against its daily upkeep, "
				+ "or clear existing workflow before accepting outside folders."
			),
			"page_id": &"capital",
		},
		{
			"id": &"welfare",
			"label": "FLOCK WELFARE",
			"status_id": &"on_track" if welfare >= 70 else &"attention",
			"status_label": "CARE BUFFER" if welfare >= 70 else "CARE PRESSURE",
			"current_label": "%d / 100" % welfare,
			"target_label": "70+",
			"why": (
				"Morale, stress, fatigue, and grievance combine across employed hens; "
				+ "care pressure changes productivity and labor consequences."
			),
			"action": (
				"Open Flock to compare recovery, assignments, and care before adding "
				+ "overtime or another demanding binder."
			),
			"page_id": &"flock",
		},
		{
			"id": &"market",
			"label": "MUTUAL REACH",
			"status_id": &"on_track" if executive_select_open else &"building",
			"status_label": (
				"EXECUTIVE SELECT OPEN"
				if executive_select_open else
				"REACH BUILDING"
				if reach < MARKET_PRICING_EXECUTIVE_REACH_REQUIREMENT else
				"CLAIMANT TRUST LOW"
			),
			"current_label": "%d REACH / %d SENTIMENT / %.2f%% SHARE" % [
				reach,
				satisfaction,
				float(share_basis_points) / 100.0,
			],
			"target_label": "%d REACH / %d SENTIMENT" % [
				MARKET_PRICING_EXECUTIVE_REACH_REQUIREMENT,
				MARKET_PRICING_EXECUTIVE_SATISFACTION_MINIMUM,
			],
			"why": (
				"Executive Select requires both reach and claimant trust. Premium "
				+ "filings spend sentiment; fulfilled Mutual and Community Access "
				+ "binders rebuild it."
			),
			"action": (
				"Open Records during review to compare binder volume, premium, "
				+ "handling margin, claimant effect, and reach before signing."
			),
			"page_id": &"governance_records",
		},
	]


func _economic_watch_page_for_bottleneck(bottleneck_id: StringName) -> StringName:
	match bottleneck_id:
		&"feed":
			return &"operations"
		&"workflow":
			return &"flock"
		&"archive", &"break_even", &"treasury":
			return &"capital"
		_:
			return &"today"


func _economic_resource_rows(
	treasury: Dictionary,
	procurement: Dictionary,
) -> Array[Dictionary]:
	return [
		{
			"id": &"feed_fund",
			"label": "FEED FUND",
			"value_cents": revenue_cents,
			"source": "Sound and golden egg credit, fulfilled Mutual binders, and filed awards.",
			"use": "Feed, payroll, facilities, resolutions, procurement, and capital.",
			"limit": "Protected obligations are unavailable for discretionary spending.",
			"strategic_value": "Liquidity for surviving this shift and choosing the next one.",
		},
		{
			"id": &"protected_reserve",
			"label": "PROTECTED RESERVE",
			"value_cents": protected_reserve_cents(),
			"source": "Derived from payroll, upkeep, feed, breach exposure, arrears, and debt.",
			"use": "Prevents a purchase from silently consuming already-promised money.",
			"limit": "Not spendable and released only as obligations settle.",
			"strategic_value": "Turns solvency into a visible constraint instead of a surprise.",
		},
		{
			"id": &"treasury_headroom",
			"label": "TREASURY HEADROOM",
			"value_cents": int(treasury.get("credit_headroom_cents", 0)),
			"source": "Farm Mutual standing and a debt-free close record.",
			"use": "Automatically bridges vendors and interest, never flock wages.",
			"limit": "Interest accrues and an exhausted indebted line freezes capital.",
			"strategic_value": "Recovery time after a weak close without making failure free.",
		},
		{
			"id": &"feed_stock",
			"label": "FEED STOCK",
			"value": int(procurement.get("stock_scoops", 0)),
			"capacity": int(procurement.get("capacity_scoops", 0)),
			"unit": "scoops",
			"source": "One disclosed provisions order during eligible closing review.",
			"use": "Covers the flock's next ration before seasonal spot buying.",
			"limit": "Finite bins and dated lots create capacity and spoilage risk.",
			"strategic_value": "Hedge price pressure or buy fresher, kinder feed.",
		},
		{
			"id": &"farm_mutual_standing",
			"label": "FARM MUTUAL STANDING",
			"value": farm_mutual_standing(),
			"unit": "points",
			"source": "Two points per fulfilled binder, minus one per breach.",
			"use": "Gates Service Coop tiers, negotiation, and Treasury capacity.",
			"limit": "Standard-book days are neutral; breaches also break clean streaks.",
			"strategic_value": "Long-run client access earned by reliable file handling.",
		},
		{
			"id": &"live_file_capacity",
			"label": "LIVE-FILE CAPACITY",
			"value": _outstanding_claim_count(),
			"capacity": current_claim_capacity(),
			"unit": "files",
			"source": "Records facilities and commissioned routing infrastructure.",
			"use": "Holds accepted files and creates room for disclosed binder arrivals.",
			"limit": "Storage does not add workers; excess demand is turned away.",
			"strategic_value": "Captures opportunity only when staffing and routing can clear it.",
		},
	]


func _economic_bottleneck_rows(
	treasury: Dictionary,
	procurement: Dictionary,
	secured_margin: int,
) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var liabilities := int(treasury.get("total_liabilities_cents", 0))
	if wage_arrears_cents > 0 or liabilities > 0:
		rows.append({
			"id": &"treasury",
			"severity": 4 if wage_arrears_cents > 0 else 3,
			"label": "TREASURY PRESSURE",
			"reason": "$%.2f liabilities and $%.2f unpaid wages reduce future choices."
				% [float(liabilities) / 100.0, float(wage_arrears_cents) / 100.0],
			"action": "File a profitable low-risk close; cash repays interest, vendors, labor, then principal in that order.",
		})
	var spot_shortage := int(procurement.get("spot_shortage_scoops", 0))
	if spot_shortage > 0:
		rows.append({
			"id": &"feed",
			"severity": 2,
			"label": "FEED COVERAGE",
			"reason": "%d ration scoops are uncovered at the current seasonal spot quote."
				% spot_shortage,
			"action": "Use Provisions during review to hedge price, capacity, shelf life, and flock strain.",
		})
	var outstanding := _outstanding_claim_count()
	var capacity := current_claim_capacity()
	if intake_rejections_today > 0 or outstanding * 100 >= capacity * 85:
		rows.append({
			"id": &"archive",
			"severity": 4 if intake_rejections_today > 0 else 2,
			"label": "ARCHIVE CAPACITY",
			"reason": "%d of %d live-file slots are occupied; %d files were turned away today."
				% [outstanding, capacity, intake_rejections_today],
			"action": "Clear the oldest lane, decline extra binder work, or commission Records capacity.",
		})
	var overdue := _overdue_claim_count(true)
	var rework := _queued_rework_count() + _active_rework_count()
	if overdue + rework > 0:
		rows.append({
			"id": &"workflow",
			"severity": 3 if overdue > 0 else 2,
			"label": "WORKFLOW DEBT",
			"reason": "%d overdue and %d rework files are consuming future production."
				% [overdue, rework],
			"action": "Route matching specialties, use Priority Peck deliberately, and avoid adding preventable rush work.",
		})
	if secured_margin < 0:
		rows.append({
			"id": &"break_even",
			"severity": 1,
			"label": "BREAK-EVEN GAP",
			"reason": "$%.2f more secured egg credit is needed to cover today's filed operating cost."
				% (float(-secured_margin) / 100.0),
			"action": "Finish sound work before buying optional interventions; binder upside is not counted until earned.",
		})
	rows.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			var left_severity := int(left.get("severity", 0))
			var right_severity := int(right.get("severity", 0))
			if left_severity != right_severity:
				return left_severity > right_severity
			return String(left.get("id", "")) < String(right.get("id", ""))
	)
	if rows.size() > 4:
		rows.resize(4)
	if rows.is_empty():
		rows.append({
			"id": &"clear",
			"severity": 0,
			"label": "NO CRITICAL BOTTLENECK",
			"reason": "Current obligations, capacity, feed, and workflow remain inside their filed limits.",
			"action": "Compare the next contract or capital tradeoff before committing spare Feed Fund.",
		})
	return rows


func _economic_strategy_rows() -> Array[Dictionary]:
	## These are explanations of already-authoritative mechanics, not bonuses.
	## Keeping the counterweight beside each route makes it clear that the game
	## supports several viable operating styles without promising one dominant
	## upgrade path.
	return [
		{
			"id": &"throughput",
			"label": "THROUGHPUT ROOST",
			"lever": "Route specialties, Priority Peck, overtime, and packing capacity.",
			"upside": "Clear more sound files before deadlines and capture busy-book demand.",
			"counterweight": "Strain, cracks, rework, payroll, and welfare scrutiny rise if pushed blindly.",
		},
		{
			"id": &"quality",
			"label": "SHELL ASSURANCE",
			"lever": "Favor careful routing, shell checks, training, and deliberate rework.",
			"upside": "Protect golden credit, clean streaks, standing, and binder settlement.",
			"counterweight": "Slower handling can create overdue files and rejected demand.",
		},
		{
			"id": &"welfare",
			"label": "FLOCK STEWARDSHIP",
			"lever": "Choose kinder feed, humane doctrine, recovery time, and care facilities.",
			"upside": "Sustain morale, lower grievances, and preserve long-run productive capacity.",
			"counterweight": "Immediate expense and gentler targets may slow capital accumulation.",
		},
		{
			"id": &"contract",
			"label": "MUTUAL SPECIALIST",
			"lever": "Build standing, negotiate riders, and selectively bind seasonal file books.",
			"upside": "Earn premiums, outside files, and better Service Coop access.",
			"counterweight": "Breach reserves, clauses, and demand spikes make overcommitment expensive.",
		},
		{
			"id": &"capacity",
			"label": "CAPACITY BUILDER",
			"lever": "Commission Records, desks, managers, facilities, campus, and portfolio services.",
			"upside": "Raise file, staffing, and processing ceilings for later books.",
			"counterweight": "Every idle perch and service adds recurring cost before it earns anything.",
		},
	]


func _economic_recovery_rows(
	treasury: Dictionary,
	procurement: Dictionary,
	contract_board: Dictionary,
) -> Array[Dictionary]:
	var planning_open := shift_phase == ShiftPhase.REVIEW and pending_decision.is_empty()
	var has_idle_release_candidate := false
	if planning_open and active_worker_count() > MINIMUM_STAFF_COUNT:
		for worker: ChickenState in workers:
			if (
				worker.employed
				and worker.work_state == ChickenState.WorkState.IDLE
				and worker.current_claim == null
			):
				has_idle_release_candidate = true
				break
	var rows: Array[Dictionary] = [
		{
			"id": &"standard_book",
			"label": "FILE THE STANDARD BOOK",
			"available": bool(contract_board.get("planning_open", false)),
			"effect": "Decline optional binder exposure without losing standing.",
			"tradeoff": "Forfeit that binder's premium and outside file opportunity.",
		},
		{
			"id": &"treasury_bridge",
			"label": "USE TREASURY HEADROOM",
			"available": int(treasury.get("credit_headroom_cents", 0)) > 0,
			"effect": "Vendor and interest shortfalls draw automatically at close.",
			"tradeoff": "Credit never pays wages and opening principal accrues next-shift interest.",
		},
		{
			"id": &"downsize",
			"label": "RELEASE AN IDLE PERCH",
			"available": has_idle_release_candidate,
			"effect": "Reduce the next shift's wage and feed obligation.",
			"tradeoff": "Pay severance now and permanently surrender productive capacity.",
		},
		{
			"id": &"feed_hedge",
			"label": "AUTHORIZE PROVISIONS",
			"available": (
				planning_open
				and int(procurement.get("level", 0)) > 0
				and int(procurement.get("orders_used_today", 0))
					< int(procurement.get("order_limit", 1))
			),
			"effect": "Replace future seasonal spot exposure with one disclosed lot.",
			"tradeoff": "Cash is paid now; finite bins and expiry can turn excess stock into waste.",
		},
	]
	return rows


func _projected_spendable_after_obligation_change_cents(
	one_time_cost_cents: int,
	added_daily_operating_cents: int
) -> int:
	return _projected_spendable_from_base_cents(
		_projected_spendable_base_cents(),
		one_time_cost_cents,
		added_daily_operating_cents,
	)


## Change-independent part of the projection. A capital freeze is encoded as
## null so batched readers (one base, many candidate changes) stay exact.
func _projected_spendable_base_cents() -> Variant:
	if farm_treasury_capital_frozen():
		return null
	return (
		revenue_cents
		- wage_arrears_cents
		- current_daily_operating_cost_cents()
		- current_market_contract_reserve_cents()
		- farm_treasury_liabilities_cents()
	)


func _projected_spendable_from_base_cents(
	base_cents: Variant,
	one_time_cost_cents: int,
	added_daily_operating_cents: int
) -> int:
	## Keep this value raw rather than clamping it to zero: a negative projection
	## is the exact reserve deficit that must block the transaction atomically.
	if base_cents == null:
		if one_time_cost_cents > 0 or added_daily_operating_cents > 0:
			return -maxi(1, one_time_cost_cents + added_daily_operating_cents)
		# Frozen capital with no new obligation: the unfrozen formula applies.
		return (
			revenue_cents
			- maxi(0, one_time_cost_cents)
			- wage_arrears_cents
			- current_daily_operating_cost_cents()
			- current_market_contract_reserve_cents()
			- farm_treasury_liabilities_cents()
			- added_daily_operating_cents
		)
	return int(base_cents) - maxi(0, one_time_cost_cents) - added_daily_operating_cents


func _required_spendable_for_obligation_change_cents(
	one_time_cost_cents: int,
	added_daily_operating_cents: int
) -> int:
	return maxi(0, one_time_cost_cents) + maxi(0, added_daily_operating_cents)


func _prepare_farm_treasury_close_day(target_day: int) -> bool:
	## Normal play always closes consecutive days. Test/admin tools sometimes jump
	## the public day field, so neutral ledgers may adopt that chronology without
	## inventing transactions. Once debt/history exists, skipped days are filed as
	## zero-activity closes so interest and receipt continuity remain exact.
	var required_last_day := maxi(0, target_day - 1)
	if _farm_treasury.last_closed_day == required_last_day:
		return true
	if _farm_treasury.last_closed_day > required_last_day:
		return false
	var treasury_before := _farm_treasury.snapshot(maxi(0, farm_mutual_standing()))
	if (
		(_farm_treasury.history as Array).is_empty()
		and int(treasury_before.get("total_liabilities_cents", 0)) == 0
	):
		return _farm_treasury.initialize_from_cash(
			_farm_treasury.cash_cents,
			required_last_day,
		)
	while _farm_treasury.last_closed_day < required_last_day:
		var bridge_day: int = _farm_treasury.last_closed_day + 1
		var bridge_receipt: Dictionary = _farm_treasury.close_shift(
			bridge_day,
			maxi(0, farm_mutual_standing()),
			{},
			{},
			0,
		)
		if not bool(bridge_receipt.get("accepted", false)):
			return false
	return true


func _farm_treasury_close_breakdowns(
	live_cash_before_recurring_cents: int,
	credited_income_cents: int,
	feed_cost_cents: int,
	facility_expansion_cents: int,
	facility_maintenance_cents: int,
	campus_services_cents: int,
	portfolio_operations_cents: int,
	farmgate_shortfall_cents: int,
) -> Dictionary:
	## Reconcile every intrashift cash mutation against the prior filed close. Known
	## production credit remains legible; the residual captures capital purchases,
	## remedies, policy awards, and other already-applied actions exactly once.
	var income: Dictionary = {}
	var vendors: Dictionary = {}
	var known_income := maxi(0, credited_income_cents)
	if known_income > 0:
		income["production_and_bonus_income"] = known_income
	var residual: int = (
		live_cash_before_recurring_cents
		- _farm_treasury.cash_cents
		- known_income
	)
	if residual > 0:
		income["other_feed_fund_income"] = residual
	elif residual < 0:
		vendors["daytime_cash_outflows"] = -residual
	var vendor_rows := {
		"daily_feed_service": maxi(0, feed_cost_cents),
		"expanded_desk_lease": maxi(0, facility_expansion_cents),
		"facility_maintenance": maxi(0, facility_maintenance_cents),
		"north_meadow_services": maxi(0, campus_services_cents),
		"portfolio_operations": maxi(0, portfolio_operations_cents),
		"farmgate_settlement_shortfall": maxi(0, farmgate_shortfall_cents),
	}
	for raw_key in vendor_rows:
		var amount := int(vendor_rows[raw_key])
		if amount > 0:
			vendors[String(raw_key)] = amount
	return {
		"income": income,
		"vendors": vendors,
	}


func _announce_farm_treasury_close(receipt: Dictionary) -> void:
	var draw := int(receipt.get("credit_draw_cents", 0))
	var vendor_arrears := int(receipt.get("closing_vendor_arrears_cents", 0))
	var interest_arrears := int(receipt.get("closing_interest_arrears_cents", 0))
	if draw > 0:
		announcement_posted.emit(
			"TREASURY DRAW: Farm Mutual advanced $%.2f against the operating line."
			% (float(draw) / 100.0)
		)
	if vendor_arrears + interest_arrears > 0:
		announcement_posted.emit(
			"VENDOR EXCEPTION: $%.2f remains filed as unpaid invoices and interest."
			% (float(vendor_arrears + interest_arrears) / 100.0)
		)
	if bool(receipt.get("rating_advanced", false)):
		announcement_posted.emit(
			"TREASURY RATING ADVANCED: three profitable debt-free closes expanded the operating line."
		)
	var closing_liabilities := (
		int(receipt.get("closing_credit_principal_cents", 0))
		+ vendor_arrears
		+ interest_arrears
	)
	if (
		closing_liabilities > 0
		and int(receipt.get("closing_credit_principal_cents", 0))
		>= int(receipt.get("closing_credit_limit_cents", 0))
	):
		announcement_posted.emit(
			"CAPITAL FREEZE: the operating line is full; clear treasury liabilities before new expansion."
		)


func career_sponsorship_preflight(worker_id: int, target_lane: StringName) -> Dictionary:
	## Read-only planning check for a single cross-training authorization. Every
	## rejection reason is resolved before the apply API mutates Feed Fund or hen
	## state, so callers can safely refresh this receipt after any review action.
	var spendable := spendable_fund_cents()
	var sponsorship_cost := career_sponsorship_cost_cents()
	var training_work_basis_points := pending_training_work_basis_points()
	var training_work_multiplier := float(training_work_basis_points) / 10_000.0
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
	elif spendable < sponsorship_cost:
		reason = "Career Sponsorship denied: $%.2f more spendable Feed Fund required." % (
			float(sponsorship_cost - spendable) / 100.0
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
		"cost_cents": sponsorship_cost,
		"base_cost_cents": CAREER_SPONSORSHIP_COST_CENTS,
		"discount_cents": CAREER_SPONSORSHIP_COST_CENTS - sponsorship_cost,
		"spendable_fund_cents": spendable,
		"training_work_basis_points": training_work_basis_points,
		"training_work_multiplier": training_work_multiplier,
		"training_work_penalty_percent": roundi((1.0 - training_work_multiplier) * 100.0),
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
	var sponsorship_cost := int(preflight.get("cost_cents", career_sponsorship_cost_cents()))
	revenue_cents -= sponsorship_cost
	var training_penalty_percent := int(preflight.get("training_work_penalty_percent", 15))
	var outcome := (
		"Career Sponsorship approved for %s. %s training will reduce her next worked shift by %d%%."
		% [worker.display_name, _lane_display_name(target_lane), training_penalty_percent]
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
				# One Dividend governs three full shifts. The original eighteen-point
				# recovery could clear the generic Standard Book, but the dedicated
				# Flock Accord remained mathematically unreachable once normal fatigue
				# compounded across a full year. Thirty-four makes the expensive care policy
				# a real recovery tool while quota relief and a farmer-favor penalty
				# preserve its strategic cost.
				worker.morale = clampf(worker.morale + 34.0, 0.0, 100.0)
				worker.stress = clampf(worker.stress - 34.0, 0.0, 100.0)
				worker.fatigue = clampf(worker.fatigue - 34.0, 0.0, 100.0)
				worker.manager_trust = clampf(worker.manager_trust + 6.0, 0.0, 100.0)
				worker.grievance = clampf(worker.grievance - 6.0, 0.0, 100.0)
				worker_effects.append(_senior_worker_effect_receipt(worker, before_worker))
			solidarity = clampf(solidarity + 10.0, 0.0, 100.0)
			executive_confidence = clampf(executive_confidence - 4.0, 0.0, 100.0)
			quota_target = clampi(quota_target - 1, 1, 10_000)
			outcome = "The flock dividend was distributed. The farmer has requested a narrower definition of morale."
		&"harvest_forecast":
			revenue_cents += 6000
			# Two measured four-Forecast advanced years showed the compounding
			# problem: the original +10 / +3 stress / -4 trust / +5 grievance route
			# collapsed welfare to zero and reached only 74% of credited harvest;
			# +20 with reduced harm recovered 23% more credit but still missed the
			# frozen target by 3.6% and favor by six. Forecast remains an ugly labor
			# trade through higher quota, lower compliance, trust, and grievance,
			# but no longer adds direct strain that defeats its own production Book.
			executive_confidence = clampf(executive_confidence + 24.0, 0.0, 100.0)
			quota_target = clampi(quota_target + 2, 1, 10_000)
			compliance = clampf(compliance - 4.0, 0.0, 100.0)
			for worker in workers:
				if not worker.employed:
					continue
				var before_worker := _senior_worker_effect_snapshot(worker)
				worker.manager_trust = clampf(worker.manager_trust - 1.0, 0.0, 100.0)
				worker.grievance = clampf(worker.grievance + 1.0, 0.0, 100.0)
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
	return shift_phase == ShiftPhase.REVIEW and pending_decision.is_empty()


func _hire_feed_obligation_delta_cents() -> int:
	## Hiring happens in review, before today's ration is consumed. Reserve the
	## actual marginal seasonal shortage after existing bins, not a stale $2 flat.
	var projected_cost := _projected_feed_spot_cost_cents(
		_feed_demand_scoops() + 1,
		_feed_procurement.stock_scoops(),
		_feed_spot_unit_price_cents(),
	)
	return maxi(0, projected_cost - current_daily_feed_cost_cents())


func staffing_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	var action_available := staffing_planning_open() and not _staffing_action_used_today()
	var active_count := active_worker_count()
	var vacant_desk := _lowest_vacant_desk()
	var spendable := spendable_fund_cents()
	for worker in workers:
		var hire_cost := worker.hire_cost_cents()
		var release_cost := worker.release_cost_cents()
		var hire_added_daily_operating_cents := (
			_hire_feed_obligation_delta_cents() + worker.daily_wage_cents()
		)
		var hire_required_spendable_cents := _required_spendable_for_obligation_change_cents(
			hire_cost,
			hire_added_daily_operating_cents,
		)
		var hire_projected_spendable_cents := _projected_spendable_after_obligation_change_cents(
			hire_cost,
			hire_added_daily_operating_cents,
		)
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
			"hire_added_daily_operating_cents": hire_added_daily_operating_cents,
			"hire_required_spendable_cents": hire_required_spendable_cents,
			"hire_projected_spendable_fund_cents": hire_projected_spendable_cents,
			"hire_affordable": hire_projected_spendable_cents >= 0,
			"release_cost_cents": release_cost,
			"can_hire": (
				action_available
				and not worker.employed
				and worker.available_for_hire_day <= day
				and active_count < office_capacity
				and vacant_desk >= 0
				and hire_projected_spendable_cents >= 0
			),
			"can_release": (
				action_available
				and worker.employed
				and _campus_portfolio_assignment_for_worker(worker.id) == &""
				and active_count > MINIMUM_STAFF_COUNT
				and (
					int(active_market_contract.get("required_active_staff", 0)) <= 0
					or active_count - 1 >= int(active_market_contract.get("required_active_staff", 0))
				)
				and worker.work_state == ChickenState.WorkState.IDLE
				and worker.current_claim == null
				and spendable >= release_cost
			),
			"reason": _staffing_worker_action_reason(worker),
		})
	return catalog


func internship_program_seat_limit() -> int:
	return clampi(
		InternshipProgramStateScript.BASE_SEAT_LIMIT
			+ mini(1, maxi(0, facility_level(TRAINING_ROOST_ID))),
		InternshipProgramStateScript.BASE_SEAT_LIMIT,
		InternshipProgramStateScript.MAX_SEAT_LIMIT,
	)


func internship_program_snapshot() -> Dictionary:
	return _internship_program.snapshot(
		day,
		spendable_fund_cents(),
		staffing_planning_open(),
		internship_program_seat_limit(),
	)


func onboard_intern(candidate_id: StringName) -> Dictionary:
	var result := _internship_program.onboard(
		candidate_id,
		day,
		spendable_fund_cents(),
		staffing_planning_open(),
		internship_program_seat_limit(),
	)
	return _apply_internship_action(result)


func assign_intern(candidate_id: StringName, assignment_id: StringName) -> Dictionary:
	var result := _internship_program.assign(
		candidate_id,
		assignment_id,
		day,
		staffing_planning_open(),
	)
	return _apply_internship_action(result)


func resolve_intern_review(
	candidate_id: StringName,
	resolution_id: StringName,
) -> Dictionary:
	var result := _internship_program.resolve_review(
		candidate_id,
		resolution_id,
		day,
		spendable_fund_cents(),
		staffing_planning_open(),
	)
	if bool(result.get("accepted", false)):
		match resolution_id:
			&"recommendation_letter":
				compliance = minf(100.0, compliance + 1.0)
			&"paid_fellowship":
				compliance = minf(100.0, compliance + 2.0)
				solidarity = minf(100.0, solidarity + 2.0)
				executive_confidence = maxf(0.0, executive_confidence - 1.0)
	return _apply_internship_action(result)


func _apply_internship_action(result: Dictionary) -> Dictionary:
	if not bool(result.get("accepted", false)):
		return result
	var cost_cents := maxi(0, int(result.get("cost_cents", 0)))
	if cost_cents > revenue_cents:
		return {
			"accepted": false,
			"action_id": result.get("action_id", &"internship"),
			"candidate_id": result.get("candidate_id", &""),
			"reason": "The Feed Fund changed before the internship filing completed.",
		}
	revenue_cents -= cost_cents
	result["fund_after_cents"] = revenue_cents
	result["program"] = internship_program_snapshot()
	internship_action_resolved.emit(result.duplicate(true))
	announcement_posted.emit(String(result.get("outcome", "Internship filing completed.")))
	snapshot_changed.emit(snapshot())
	return result


func capacity_upgrade_status() -> Dictionary:
	var planning_open := staffing_planning_open()
	var cost := _capacity_upgrade_cost_cents()
	var available := office_capacity < MAXIMUM_STAFF_CAPACITY and cost >= 0
	var added_daily_operating_cents := (
		FACILITY_COST_PER_EXPANDED_SEAT_CENTS if available else 0
	)
	var required_spendable_cents := _required_spendable_for_obligation_change_cents(
		maxi(0, cost),
		added_daily_operating_cents,
	)
	var projected_spendable_cents := _projected_spendable_after_obligation_change_cents(
		maxi(0, cost),
		added_daily_operating_cents,
	)
	var affordable := available and projected_spendable_cents >= 0
	var reason := ""
	if office_capacity >= MAXIMUM_STAFF_CAPACITY:
		reason = "Every authorized workstation is already open."
	elif cost < 0:
		reason = "No expansion schedule exists for this office tier."
	elif shift_phase != ShiftPhase.REVIEW:
		reason = "Capacity plans are filed during shift review."
	elif not pending_decision.is_empty():
		reason = "Resolve the closing credit memo before filing capacity plans."
	elif not affordable:
		reason = "Expansion requires $%.2f more spendable Feed Fund." % (
			float(-projected_spendable_cents) / 100.0
		)
	return {
		"available": available,
		"planning_open": planning_open,
		"current_capacity": office_capacity,
		"next_capacity": mini(MAXIMUM_STAFF_CAPACITY, office_capacity + 1),
		"maximum_capacity": MAXIMUM_STAFF_CAPACITY,
		"cost_cents": maxi(0, cost),
		"added_daily_operating_cents": added_daily_operating_cents,
		"required_spendable_cents": required_spendable_cents,
		"spendable_fund_cents": spendable_fund_cents(),
		"projected_spendable_fund_cents": projected_spendable_cents,
		"affordable": affordable,
		"reason": reason,
	}


func purchase_staff_capacity() -> Dictionary:
	if shift_phase != ShiftPhase.REVIEW:
		return _rejected_staffing_action("Capacity plans are filed during shift review.")
	if not pending_decision.is_empty():
		return _rejected_staffing_action("Resolve the closing credit memo before filing capacity plans.")
	if office_capacity >= MAXIMUM_STAFF_CAPACITY:
		return _rejected_staffing_action("Every authorized workstation is already open.")
	var cost := _capacity_upgrade_cost_cents()
	if cost < 0:
		return _rejected_staffing_action("No expansion schedule exists for this office tier.")
	var added_daily_operating_cents := FACILITY_COST_PER_EXPANDED_SEAT_CENTS
	var required_spendable_cents := _required_spendable_for_obligation_change_cents(
		cost,
		added_daily_operating_cents,
	)
	var projected_spendable_cents := _projected_spendable_after_obligation_change_cents(
		cost,
		added_daily_operating_cents,
	)
	if projected_spendable_cents < 0:
		return _rejected_staffing_action(
			"Expansion denied: $%.2f more spendable Feed Fund required." % (
				float(-projected_spendable_cents) / 100.0
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
		"added_daily_operating_cents": added_daily_operating_cents,
		"required_spendable_cents": required_spendable_cents,
		"projected_spendable_fund_cents": projected_spendable_cents,
		"spendable_fund_cents": spendable_fund_cents(),
		"outcome": "A new workstation was authorized before anyone asked who would supervise it.",
	}
	office_capacity_changed.emit(office_capacity, cost)
	staffing_action_resolved.emit(result.duplicate(true))
	announcement_posted.emit(String(result["outcome"]))
	snapshot_changed.emit(snapshot())
	return result


func hire_worker(worker_id: int) -> Dictionary:
	if shift_phase != ShiftPhase.REVIEW:
		return _rejected_staffing_action("Hiring files are accepted during shift review.")
	if not pending_decision.is_empty():
		return _rejected_staffing_action("Resolve the closing credit memo before filing a hire.")
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
	var added_daily_operating_cents := (
		_hire_feed_obligation_delta_cents() + worker.daily_wage_cents()
	)
	var required_spendable_cents := _required_spendable_for_obligation_change_cents(
		cost,
		added_daily_operating_cents,
	)
	var projected_spendable_cents := _projected_spendable_after_obligation_change_cents(
		cost,
		added_daily_operating_cents,
	)
	if projected_spendable_cents < 0:
		return _rejected_staffing_action(
			"Hire denied: $%.2f more spendable Feed Fund required." % (
				float(-projected_spendable_cents) / 100.0
			)
		)

	revenue_cents -= cost
	worker.employed = true
	worker.desk_index = desk
	worker.available_for_hire_day = 0
	worker.hire_count += 1
	worker.employment_start_day = day
	worker.assigned_lane = AUTO_ASSIGNMENT
	worker.manually_routed = false
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
		"added_daily_operating_cents": added_daily_operating_cents,
		"required_spendable_cents": required_spendable_cents,
		"projected_spendable_fund_cents": projected_spendable_cents,
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
	var campus_assignment := _campus_portfolio_assignment_for_worker(worker_id)
	if campus_assignment != &"":
		return _rejected_staffing_action(
			"Release held: unassign this hen from %s in Campus Portfolio first."
			% String(campus_assignment).replace("_", " ").capitalize()
		)
	if (
		StringName(pending_decision.get("id", &"")) == &"flock_restructuring"
		and int(pending_decision.get("subject_worker_id", -1)) == worker_id
	):
		return _rejected_staffing_action("This hen is locked to the pending restructuring dossier.")
	if active_worker_count() <= MINIMUM_STAFF_COUNT:
		return _rejected_staffing_action("The office must retain at least three active hens.")
	var contracted_staff_floor := int(active_market_contract.get("required_active_staff", 0))
	if (
		contracted_staff_floor > 0
		and active_worker_count() - 1 < contracted_staff_floor
	):
		return _rejected_staffing_action(
			"Release held: the signed Farm Mutual binder commits at least %d active hens."
			% contracted_staff_floor
		)
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
	worker.manually_routed = false
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
	if shift_phase != ShiftPhase.REVIEW:
		return "Staffing files are accepted during shift review."
	if not pending_decision.is_empty():
		return "Resolve the closing credit memo before filing staffing changes."
	if _staffing_action_used_today():
		return "Today's hire or release file is already closed."
	if worker.employed:
		var campus_assignment := _campus_portfolio_assignment_for_worker(worker.id)
		if campus_assignment != &"":
			return "Unassign this hen from %s in Campus Portfolio before filing release." % (
				String(campus_assignment).replace("_", " ").capitalize()
			)
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
	var added_daily_operating_cents := (
		_hire_feed_obligation_delta_cents() + worker.daily_wage_cents()
	)
	var projected_spendable_cents := _projected_spendable_after_obligation_change_cents(
		worker.hire_cost_cents(),
		added_daily_operating_cents,
	)
	if projected_spendable_cents < 0:
		return "Hiring requires $%.2f more spendable Feed Fund, including daily feed and wage reserves." % (
			float(-projected_spendable_cents) / 100.0
		)
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
	return (
		clampi(PECK_ASSIST_LIMIT - peck_assists_used_today, 0, PECK_ASSIST_LIMIT)
		+ routing_momentum_peck_recharge_bank
	)


func _peck_assist_charge_limit() -> int:
	return PECK_ASSIST_LIMIT + routing_momentum_peck_recharge_bank


func _pending_peck_assist_delivery_snapshot() -> Array[Dictionary]:
	var claim_ids: Array[int] = []
	for claim_id in _pending_peck_assist_deliveries:
		claim_ids.append(int(claim_id))
	claim_ids.sort()
	var deliveries: Array[Dictionary] = []
	for claim_id in claim_ids:
		deliveries.append((_pending_peck_assist_deliveries[claim_id] as Dictionary).duplicate(true))
	return deliveries


func _upgrade_list_cost_for_level(upgrade_id: StringName, level_before: int) -> int:
	if not UPGRADE_DEFINITIONS.has(upgrade_id):
		return -1
	if level_before < 0 or level_before >= MAX_UPGRADE_LEVEL:
		return 0
	var definition := UPGRADE_DEFINITIONS[upgrade_id] as Dictionary
	return roundi(
		float(definition["base_cost_cents"])
		* pow(float(definition["growth"]), level_before)
	)


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
			"work_stress_basis_points": int(definition.get(
				"work_stress_basis_points",
				10_000,
			)),
			"sound_morale_millipoints": int(definition.get(
				"sound_morale_millipoints",
				0,
			)),
			"sound_compliance_millipoints": int(definition.get(
				"sound_compliance_millipoints",
				0,
			)),
			"cracked_compliance_millipoints": int(definition.get(
				"cracked_compliance_millipoints",
				0,
			)),
			"operational_tradeoff": String(definition.get(
				"operational_tradeoff",
				"",
			)),
		})
	return catalog


func claim_resolution_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for path_id in [&"standard", &"settle", &"deny", &"exception"]:
		var definition := CLAIM_RESOLUTION_DEFINITIONS[path_id] as Dictionary
		var row := definition.duplicate(true)
		row["id"] = path_id
		row["work_multiplier"] = (
			float(definition.get("work_basis_points", 10_000)) / 10_000.0
		)
		row["crack_modifier"] = (
			float(definition.get("crack_basis_points", 0)) / 10_000.0
		)
		catalog.append(row)
	return catalog


func claim_resolution_status(worker_id: int) -> Dictionary:
	var status := _claim_resolution_status(worker_id)
	status["catalog"] = claim_resolution_catalog()
	return status


## Live worker rows and command guards need eligibility, not a copied choice menu.
func _claim_resolution_status(worker_id: int) -> Dictionary:
	if worker_id < 0 or worker_id >= workers.size():
		return {
			"available": false,
			"reason": "No hen is selected.",
		}
	var worker := workers[worker_id]
	var claim := worker.current_claim
	if claim == null:
		return {
			"available": false,
			"reason": "This hen has no active claimant file.",
		}
	var before_cutoff := worker.work_progress <= CLAIM_RESOLUTION_CUTOFF_PROGRESS
	var available := (
		shift_phase == ShiftPhase.RUNNING
		and worker.work_state == ChickenState.WorkState.WORKING
		and before_cutoff
		and not claim.resolution_locked
	)
	var reason := ""
	if claim.resolution_locked:
		reason = "This claimant path is already filed and cannot be rewritten."
	elif shift_phase != ShiftPhase.RUNNING:
		reason = "Claimant paths can be filed only during a running shift."
	elif worker.work_state != ChickenState.WorkState.WORKING:
		reason = "The path must be filed while the hen is pecking the active file."
	elif not before_cutoff:
		reason = "The file is more than 55% complete; the outcome window has closed."
	var selected := (
		CLAIM_RESOLUTION_DEFINITIONS.get(claim.resolution_path, {}) as Dictionary
	).duplicate(true)
	selected["id"] = claim.resolution_path
	return {
		"available": available,
		"reason": reason,
		"worker_id": worker_id,
		"claim_id": claim.id,
		"progress": snappedf(worker.work_progress, 0.1),
		"cutoff_progress": CLAIM_RESOLUTION_CUTOFF_PROGRESS,
		"selected": selected,
	}


func set_claim_resolution(worker_id: int, path_id: StringName) -> Dictionary:
	if path_id not in CLAIM_RESOLUTION_CHOICE_IDS:
		return {
			"accepted": false,
			"reason": "Choose Settlement, Denial, or Coverage Exception.",
		}
	var status := _claim_resolution_status(worker_id)
	if not bool(status.get("available", false)):
		return {
			"accepted": false,
			"reason": String(status.get("reason", "The claimant path is unavailable.")),
		}
	var definition := CLAIM_RESOLUTION_DEFINITIONS[path_id] as Dictionary
	var cost_cents := int(definition.get("cost_cents", 0))
	if spendable_fund_cents() < cost_cents:
		return {
			"accepted": false,
			"reason": "%s requires $%.2f more spendable Feed Fund." % [
				String(definition.get("label", "CLAIMANT PATH")),
				float(cost_cents - spendable_fund_cents()) / 100.0,
			],
		}
	var worker := workers[worker_id]
	var claim := worker.current_claim
	revenue_cents -= cost_cents
	claim.resolution_path = path_id
	claim.resolution_locked = true
	claim.resolution_cost_cents = cost_cents
	var claimant := claim.claimant_profile()
	var outcome := "%s FILED FOR %s: %s  %s" % [
		String(definition.get("label", "CLAIMANT PATH")),
		String(claimant.get("name", "CLAIMANT")),
		String(definition.get("benefit", "")),
		String(definition.get("burden", "")),
	]
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return {
		"accepted": true,
		"worker_id": worker_id,
		"claim_id": claim.id,
		"path_id": path_id,
		"cost_cents": cost_cents,
		"beneficiary": String(definition.get("beneficiary", "")),
		"benefit": String(definition.get("benefit", "")),
		"burden": String(definition.get("burden", "")),
		"outcome": outcome,
	}


# --- PlaybookAuthority delegators: implementation lives in playbook_authority.gd ---
func set_worker_assignment(worker_id: int, lane: StringName) -> bool:
	return _playbook_authority.set_worker_assignment(worker_id, lane)


func personnel_action_count_today() -> int:
	return _playbook_authority.personnel_action_count_today()


func personnel_action_used_today() -> bool:
	return _playbook_authority.personnel_action_used_today()


func perform_personnel_action(worker_id: int, action_id: StringName) -> Dictionary:
	return _playbook_authority.perform_personnel_action(worker_id, action_id)


func _reset_active_playbook() -> void:
	_playbook_authority._reset_active_playbook()


func _ensure_active_playbook() -> void:
	_playbook_authority._ensure_active_playbook()


func _record_playbook_contract_completion() -> void:
	_playbook_authority._record_playbook_contract_completion()


func _playbook_proposal_id(worker_id: int) -> StringName:
	return _playbook_authority._playbook_proposal_id(worker_id)


func _playbook_combo_recipe_snapshot() -> Dictionary:
	return _playbook_authority._playbook_combo_recipe_snapshot()


func challenge_code() -> String:
	return _playbook_authority.challenge_code()


func playbook_snapshot(focused_worker_id: int = -1) -> Dictionary:
	return _playbook_authority.playbook_snapshot(focused_worker_id)


func perform_playbook_action(kind: StringName, choice_id: StringName, worker_id: int = -1) -> Dictionary:
	return _playbook_authority.perform_playbook_action(kind, choice_id, worker_id)


func _file_playbook_receipt(result: Dictionary) -> Dictionary:
	return _playbook_authority._file_playbook_receipt(result)


func _base_team_lift_ability(worker: ChickenState, partner: ChickenState) -> Dictionary:
	return _playbook_authority._base_team_lift_ability(worker, partner)


func _average_worker_stress() -> float:
	return _playbook_authority._average_worker_stress()


func _playbook_work_multiplier() -> float:
	return _playbook_authority._playbook_work_multiplier()


func _playbook_crack_modifier() -> float:
	return _playbook_authority._playbook_crack_modifier()


func _playbook_strain_multiplier() -> float:
	return _playbook_authority._playbook_strain_multiplier()


func routing_momentum_snapshot() -> Dictionary:
	var pace_active := routing_momentum_chain >= ROUTING_MOMENTUM_PACE_MILESTONE
	var next_milestone := 0
	var next_reward := ""
	var mastery_target_kind: StringName = &""
	if routing_momentum_chain < ROUTING_MOMENTUM_CELEBRATION_MILESTONE:
		for milestone in [
			ROUTING_MOMENTUM_PACE_MILESTONE,
			ROUTING_MOMENTUM_PECK_MILESTONE,
			ROUTING_MOMENTUM_GOLDEN_MILESTONE,
			ROUTING_MOMENTUM_CELEBRATION_MILESTONE,
		]:
			if routing_momentum_chain < milestone:
				next_milestone = milestone
				break
		match next_milestone:
			ROUTING_MOMENTUM_PACE_MILESTONE:
				next_reward = "PACE +15%"
			ROUTING_MOMENTUM_PECK_MILESTONE:
				next_reward = "PECK RECHARGE"
			ROUTING_MOMENTUM_GOLDEN_MILESTONE:
				next_reward = "GOLDEN FILE"
			ROUTING_MOMENTUM_CELEBRATION_MILESTONE:
				next_reward = "TEAM LIFT"
	else:
		# Once the authored reward ladder is mastered, the existing persistent
		# best chain becomes the progression. Rebuild the exact prior record after
		# a break, then aim at the next five-route crest; no new currency or farmable
		# economic modifier is introduced.
		if best_routing_momentum_chain > routing_momentum_chain:
			next_milestone = best_routing_momentum_chain
			next_reward = "REBUILD BEST"
			mastery_target_kind = &"rebuild"
		else:
			next_milestone = maxi(
				15,
				(floori(float(routing_momentum_chain) / ROUTING_MOMENTUM_MASTERY_INTERVAL) + 1)
				* ROUTING_MOMENTUM_MASTERY_INTERVAL,
			)
			next_reward = "MASTER RECORD"
			mastery_target_kind = &"record"
	return {
		"chain": routing_momentum_chain,
		"best_chain": best_routing_momentum_chain,
		"pace_active": pace_active,
		"pace_multiplier": ROUTING_MOMENTUM_PACE_MULTIPLIER if pace_active else 1.0,
		"peck_recharge_bank": routing_momentum_peck_recharge_bank,
		"golden_charges": routing_momentum_golden_charges,
		"golden_target_claim_id": routing_momentum_golden_target_claim_id,
		"golden_target_worker_id": routing_momentum_golden_target_worker_id,
		"golden_target_bound": routing_momentum_golden_target_claim_id >= 0,
		"next_milestone": next_milestone,
		"next_reward": next_reward,
		"mastery_active": routing_momentum_chain >= ROUTING_MOMENTUM_CELEBRATION_MILESTONE,
		"mastery_target_kind": mastery_target_kind,
		"mastery_interval": ROUTING_MOMENTUM_MASTERY_INTERVAL,
		"last_dispatch": last_routing_dispatch.duplicate(true),
		"break_serial": routing_momentum_break_serial,
		"last_break": last_routing_momentum_break.duplicate(true),
		"recovery_pending": (
			routing_momentum_break_serial > 0
			and int(last_routing_momentum_recovery.get("break_serial", 0))
			< routing_momentum_break_serial
		),
		"recovery_serial": routing_momentum_recovery_serial,
		"last_recovery": last_routing_momentum_recovery.duplicate(true),
	}


func _bind_routing_golden_target() -> Dictionary:
	if (
		routing_momentum_golden_charges <= 0
		or routing_momentum_golden_target_claim_id >= 0
	):
		return {}
	var selected_worker: ChickenState
	for worker in workers:
		if not worker.employed or worker.current_claim == null:
			continue
		if (
			selected_worker == null
			or worker.work_progress > selected_worker.work_progress
			or (
				is_equal_approx(worker.work_progress, selected_worker.work_progress)
				and worker.current_claim.id < selected_worker.current_claim.id
			)
		):
			selected_worker = worker
	if selected_worker == null:
		return {}
	routing_momentum_golden_target_claim_id = selected_worker.current_claim.id
	routing_momentum_golden_target_worker_id = selected_worker.id
	return {
		"claim_id": routing_momentum_golden_target_claim_id,
		"worker_id": routing_momentum_golden_target_worker_id,
		"worker_name": selected_worker.display_name,
		"lane": selected_worker.current_claim.lane,
	}


func _release_routing_golden_target() -> void:
	routing_momentum_golden_target_claim_id = -1
	routing_momentum_golden_target_worker_id = -1


func dispatch_worker_to_lane(worker_id: int, lane: StringName) -> Dictionary:
	## Authoritative boundary for the physical tray gesture. Only a genuine
	## assignment change can build momentum, preventing repeated clicks from
	## farming milestones without routing another file stream.
	if lane == AUTO_ASSIGNMENT or not CLAIM_LANE_DEFINITIONS.has(lane):
		return {"accepted": false, "reason": "Choose a staffed intake tray."}
	if worker_id < 0 or worker_id >= workers.size() or not workers[worker_id].employed:
		return {"accepted": false, "reason": "Choose an employed hen."}
	var worker := workers[worker_id]
	if worker.assigned_lane == lane and worker.manually_routed:
		return {
			"accepted": false,
			"reason": "%s is already routed to %s." % [
				worker.display_name,
				String(lane).replace("_", " ").capitalize(),
			],
		}
	var candidates := dispatch_candidates(lane)
	if candidates.is_empty():
		return {"accepted": false, "reason": "No employed hen can take this tray."}
	var selected: Dictionary = {}
	for candidate in candidates:
		if int(candidate.get("worker_id", -1)) == worker_id:
			selected = candidate
			break
	if selected.is_empty():
		return {"accepted": false, "reason": "That hen cannot take this tray."}

	var previous_lane := worker.assigned_lane
	worker.assigned_lane = lane
	worker.manually_routed = true
	_breach_specialty_compact_for_assignment(worker)
	var recommended := bool(selected.get("recommended", false))
	var fit_tier := StringName(String(selected.get("fit_tier", "risky")))
	var route_strategy := StringName(String(selected.get("strategy_id", "gambit")))
	var chain_before := routing_momentum_chain
	var reward: Dictionary = {}
	var break_receipt: Dictionary = {}
	var recovery_receipt: Dictionary = {}
	career_workshop.record_route(day, String(lane), recommended)
	var bell_earned := false
	if recommended and career_workshop.equipped == "relay_bell" and career_workshop.tuning == "standard" and String(lane) not in career_workshop.bell_lanes and routing_momentum_peck_recharge_bank == 0:
		career_workshop.bell_lanes.append(String(lane))
		routing_momentum_peck_recharge_bank = 1
		bell_earned = true
	if recommended:
		var previous_best_chain := best_routing_momentum_chain
		routing_momentum_chain += 1
		_record_playbook_contract_completion()
		best_routing_momentum_chain = maxi(
			best_routing_momentum_chain,
			routing_momentum_chain,
		)
		if (
			chain_before == 0
			and routing_momentum_break_serial > 0
			and int(last_routing_momentum_recovery.get("break_serial", 0))
			< routing_momentum_break_serial
		):
			routing_momentum_recovery_serial += 1
			recovery_receipt = {
				"serial": routing_momentum_recovery_serial,
				"day": day,
				"minute": minute_of_day,
				"break_serial": routing_momentum_break_serial,
				"broken_chain": int(last_routing_momentum_break.get("broken_chain", 0)),
				"worker_id": worker.id,
				"worker_name": worker.display_name,
				"lane": lane,
				"recovered_chain": routing_momentum_chain,
				"label": "FIT LINKED  x1",
				"detail": "The best-fit route rebuilt routing flow at x1.",
			}
			last_routing_momentum_recovery = recovery_receipt.duplicate(true)
		reward = _apply_routing_momentum_milestone(
			routing_momentum_chain,
			previous_best_chain,
		)
		if not reward.is_empty():
			# A chain milestone occurs once within a break epoch. This stable receipt
			# key lets presentation reject duplicate delivery callbacks without
			# persisting a second authority counter.
			reward["authority_key"] = "%d:%d:%d:%d" % [
				day,
				routing_momentum_break_serial,
				routing_momentum_chain,
				worker.id,
			]
			reward["worker_id"] = worker.id
			reward["lane"] = lane
	elif fit_tier == &"risky":
		break_receipt = _break_routing_momentum(
			"A poor-fit tray ended the live pace bonus.",
			&"poor_fit",
			worker.id,
		)
	var momentum_state := routing_momentum_snapshot()
	momentum_state.erase("last_dispatch")
	var receipt := {
		"accepted": true,
		"day": day,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"lane": lane,
		"previous_lane": previous_lane,
		"recommended": recommended,
		"fit_tier": fit_tier,
		"route_strategy": route_strategy,
		"consequence_preview": String(selected.get("consequence_preview", "FLOW RESETS")),
		"specialty_match": bool(selected.get("specialty_match", false)),
		"momentum_before": chain_before,
		"momentum_chain": routing_momentum_chain,
		"reward": reward.duplicate(true),
		"break": break_receipt.duplicate(true),
		"recovery": recovery_receipt.duplicate(true),
		"momentum": momentum_state,
	}
	last_routing_dispatch = receipt.duplicate(true)
	if not recovery_receipt.is_empty():
		routing_momentum_recovered.emit(recovery_receipt.duplicate(true))
	if recommended:
		announcement_posted.emit("BEST-FIT FLOW x%d: %s took the %s tray.%s" % [
			routing_momentum_chain,
			worker.display_name,
			String(lane).replace("_", " ").to_upper(),
			("  %s" % String(reward.get("label", ""))) if not reward.is_empty() else "",
		])
	elif fit_tier == &"safe":
		announcement_posted.emit("SAFE HOLD: %s took the %s tray without breaking flow." % [
			worker.display_name,
			String(lane).replace("_", " ").to_upper(),
		])
	if bell_earned:
		announcement_posted.emit("ROUTING BELL: +1 PECK RESERVE · %d other trays can still pay this shift." % (3 - career_workshop.bell_lanes.size()))
	snapshot_changed.emit(snapshot())
	return receipt


func _apply_routing_momentum_milestone(
	chain: int,
	previous_best_chain: int = -1,
) -> Dictionary:
	match chain:
		ROUTING_MOMENTUM_PACE_MILESTONE:
			return {
				"id": &"pace",
				"label": "PACE +15%",
				"description": "Best-fit routed work now moves 15% faster while the flow holds.",
			}
		ROUTING_MOMENTUM_PECK_MILESTONE:
			var charges_before := _peck_assist_charges_available()
			var limit_before := _peck_assist_charge_limit()
			if peck_assists_used_today > 0:
				peck_assists_used_today -= 1
				routing_momentum_peck_recharges_used_today += 1
			elif routing_momentum_peck_recharge_bank <= 0:
				routing_momentum_peck_recharge_bank = 1
			var charges_after := _peck_assist_charges_available()
			var limit_after := _peck_assist_charge_limit()
			var refilled := charges_after > charges_before
			return {
				"id": &"peck_recharge",
				"label": "PECK +1" if refilled else "PECK READY",
				"description": (
					"One Priority Peck was restored or banked."
					if refilled else
					"The Priority Peck reserve was already full."
				),
				"charges_before": charges_before,
				"charges_after": charges_after,
				"limit_before": limit_before,
				"limit_after": limit_after,
				"refilled": refilled,
				"banked": routing_momentum_peck_recharge_bank > 0,
			}
		ROUTING_MOMENTUM_GOLDEN_MILESTONE:
			routing_momentum_golden_charges = 1
			var target := _bind_routing_golden_target()
			return {
				"id": &"golden_file",
				"label": "GOLD SEALED" if not target.is_empty() else "GOLD READY",
				"description": (
					"File #%04d is sealed golden through grading." % int(target.get("claim_id", 0))
					if not target.is_empty() else
					"The next active file receives the golden seal."
				),
				"target": target.duplicate(true),
			}
		ROUTING_MOMENTUM_CELEBRATION_MILESTONE:
			var affected_workers: Array[Dictionary] = []
			for affected_worker in workers:
				if not affected_worker.employed:
					continue
				affected_workers.append({
					"worker_id": affected_worker.id,
					"worker_name": affected_worker.display_name,
					"morale_before": affected_worker.morale,
					"stress_before": affected_worker.stress,
					"fatigue_before": affected_worker.fatigue,
				})
			_adjust_workers(3.0, -2.0, -1.0)
			for affected_index in affected_workers.size():
				var affected := affected_workers[affected_index]
				var affected_worker_id := int(affected.get("worker_id", -1))
				if affected_worker_id < 0 or affected_worker_id >= workers.size():
					continue
				var affected_worker := workers[affected_worker_id]
				affected["morale_after"] = affected_worker.morale
				affected["stress_after"] = affected_worker.stress
				affected["fatigue_after"] = affected_worker.fatigue
				affected["morale_delta"] = affected_worker.morale - float(affected.get("morale_before", 0.0))
				affected["stress_delta"] = affected_worker.stress - float(affected.get("stress_before", 0.0))
				affected["fatigue_delta"] = affected_worker.fatigue - float(affected.get("fatigue_before", 0.0))
				affected_workers[affected_index] = affected
			var solidarity_before := solidarity
			solidarity = minf(100.0, solidarity + 1.0)
			var standard_deltas := true
			var affected_summaries: Array[String] = []
			for affected in affected_workers:
				var morale_delta := float(affected.get("morale_delta", 0.0))
				var stress_delta := float(affected.get("stress_delta", 0.0))
				var fatigue_delta := float(affected.get("fatigue_delta", 0.0))
				standard_deltas = (
					standard_deltas
					and is_equal_approx(morale_delta, 3.0)
					and is_equal_approx(stress_delta, -2.0)
					and is_equal_approx(fatigue_delta, -1.0)
				)
				affected_summaries.append("%s: morale %s%d, stress %s%d, fatigue %s%d" % [
					String(affected.get("worker_name", "Hen")),
					"+" if morale_delta >= 0.0 else "",
					roundi(morale_delta),
					"+" if stress_delta >= 0.0 else "",
					roundi(stress_delta),
					"+" if fatigue_delta >= 0.0 else "",
					roundi(fatigue_delta),
				])
			var solidarity_delta := solidarity - solidarity_before
			return {
				"id": &"team_lift",
				"label": "ALL +3 / -2 / -1" if standard_deltas else "ALL LIFTED",
				"description": (
					"Every employed hen: morale +3, stress -2, fatigue -1."
					if standard_deltas else
					"Every employed hen improved; exact capped deltas are retained per hen."
				),
				"accessible_text": "Team Lift. %s; solidarity %s%d." % [
					"; ".join(affected_summaries),
					"+" if solidarity_delta >= 0.0 else "",
					roundi(solidarity_delta),
				],
				"affected_workers": affected_workers,
				"affected_count": affected_workers.size(),
				"solidarity_before": solidarity_before,
				"solidarity_after": solidarity,
				"solidarity_delta": solidarity_delta,
			}
	if (
		chain > ROUTING_MOMENTUM_CELEBRATION_MILESTONE
		and chain % ROUTING_MOMENTUM_MASTERY_INTERVAL == 0
		and (previous_best_chain < 0 or chain > previous_best_chain)
	):
		return {
			"id": &"mastery_record",
			"label": "RECORD x%d" % chain,
			"description": "A new best-fit mastery record was filed.",
			"accessible_text": "New best-fit routing record: %d consecutive recommended tray assignments." % chain,
			"record_before": maxi(0, previous_best_chain),
			"record_after": chain,
			"interval": ROUTING_MOMENTUM_MASTERY_INTERVAL,
		}
	return {}


func _break_routing_momentum(
	reason: String,
	source: StringName = &"unknown",
	worker_id: int = -1,
	claim_id: int = -1,
) -> Dictionary:
	var broken_chain := routing_momentum_chain
	routing_momentum_chain = 0
	if broken_chain <= 0:
		return {}
	routing_momentum_break_serial += 1
	var receipt := {
		"serial": routing_momentum_break_serial,
		"day": day,
		"minute": minute_of_day,
		"source": source,
		"worker_id": worker_id,
		"claim_id": claim_id,
		"broken_chain": broken_chain,
		"reason": reason,
		"recovery_label": "BEST FIT  >  x1",
	}
	last_routing_momentum_break = receipt.duplicate(true)
	routing_momentum_broken.emit(receipt.duplicate(true))
	return receipt


## Read-only identity for the next physical file in a tray. Personalities are
## derived only from authoritative file facts, so the same queued file always
## communicates the same behavior without adding hidden rules or random rolls.
func dispatch_file_preview(lane: StringName) -> Dictionary:
	if not CLAIM_LANE_DEFINITIONS.has(lane):
		return {}
	var claim_index := _earliest_claim_index(lane)
	var claim := _claim_at(lane, claim_index)
	if claim == null:
		return {}
	var file := claim.snapshot(_current_operational_minute())
	_apply_market_contract_claim_snapshot(file)
	var personality_id: StringName = &"steady"
	var label := "STEADY"
	var symbol := "="
	var shape := "bar"
	var behavior := "BALANCED"
	var reason := "A standard file with room for a deliberate route."
	var minutes_left := int(file.get("minutes_until_deadline", 0))
	if bool(file.get("overdue", false)) or minutes_left <= 20:
		personality_id = &"rush"
		label = "RUSH"
		symbol = "!"
		shape = "diamond_exclamation"
		behavior = "DEADLINE FIRST"
		reason = "This file is overdue or within twenty minutes of its deadline."
	elif bool(file.get("is_rework", false)) or bool(file.get("is_claimant_follow_up", false)):
		personality_id = &"returned"
		label = "RETURNED"
		symbol = "↺"
		shape = "loop_arrow"
		behavior = "RECOVERY CHANCE"
		reason = "This file returned from an earlier result and needs a clean recovery."
	elif bool(file.get("market_contract_rush", false)) or int(file.get("value_cents", 0)) >= 1000:
		personality_id = &"prize"
		label = "PRIZE"
		symbol = "$"
		shape = "coin_diamond"
		behavior = "HIGH VALUE"
		reason = "This file carries an unusually valuable or contracted result."
	elif lane == &"predator_loss":
		personality_id = &"fragile"
		label = "FRAGILE"
		symbol = "◇"
		shape = "hollow_diamond"
		behavior = "PROTECT SHELL"
		reason = "Predator-loss work carries the tray's highest shell pressure."
	elif lane == &"appeals":
		personality_id = &"sensitive"
		label = "SENSITIVE"
		symbol = "?"
		shape = "split_stamp"
		behavior = "HANDLE WITH CARE"
		reason = "An appeal can redirect audit order and claimant follow-through."
	elif lane == &"nest_damage":
		personality_id = &"repair"
		label = "REPAIR"
		symbol = "+"
		shape = "patch_cross"
		behavior = "RESTORE MORALE"
		reason = "Nest-repair relief can restore the handler's morale."
	return {
		"claim_id": int(file.get("id", -1)),
		"lane": lane,
		"personality_id": personality_id,
		"label": label,
		"symbol": symbol,
		"shape": shape,
		"behavior": behavior,
		"reason": reason,
		"minutes_until_deadline": minutes_left,
		"overdue": bool(file.get("overdue", false)),
		"rework": bool(file.get("is_rework", false)),
		"value_cents": int(file.get("value_cents", 0)),
		"claimant_name": String(file.get("claimant_name", "")),
		"authoritative_source": "queued_claim",
	}


## Ranked, read-only candidates for the physical intake-tray dispatch gesture.
## The score intentionally favors specialty fit first, then hens who are already
## free for a new file, and finally a calm/energized tie-break. Routing remains
## authoritative in dispatch_worker_to_lane(); this is only a player-facing hint.
func dispatch_candidates(lane: StringName) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	if not CLAIM_LANE_DEFINITIONS.has(lane):
		return candidates
	var file_preview := dispatch_file_preview(lane)
	for worker in workers:
		if worker == null or not worker.employed:
			continue
		var specialty_match: bool = worker.has_specialty(lane)
		var ready: bool = worker.current_claim == null
		var score: float = (
			(1000.0 if specialty_match else 0.0)
			+ (120.0 if ready else 0.0)
			+ worker.morale * 0.25
			- worker.stress
			- worker.fatigue * 0.50
		)
		candidates.append({
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"lane": lane,
			"specialty_match": specialty_match,
			"ready": ready,
			"score": score,
			"stress": roundi(worker.stress),
			"fatigue": roundi(worker.fatigue),
		})
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var score_a := float(a.get("score", 0.0))
		var score_b := float(b.get("score", 0.0))
		if not is_equal_approx(score_a, score_b):
			return score_a > score_b
		return int(a.get("worker_id", -1)) < int(b.get("worker_id", -1))
	)
	for index in candidates.size():
		var recommended := index == 0
		var specialty_match := bool(candidates[index].get("specialty_match", false))
		var ready := bool(candidates[index].get("ready", false))
		var fit_tier := "best" if recommended else "safe" if specialty_match and ready else "risky"
		candidates[index]["recommended"] = recommended
		candidates[index]["fit_tier"] = fit_tier
		candidates[index]["fit_label"] = fit_tier.to_upper()
		candidates[index]["fit_shape"] = "star" if fit_tier == "best" else "check" if fit_tier == "safe" else "triangle"
		candidates[index]["pace_preview"] = "fast" if fit_tier == "best" else "steady" if fit_tier == "safe" else "slow"
		candidates[index]["shell_risk_preview"] = "low" if fit_tier == "best" else "guarded" if fit_tier == "safe" else "high"
		candidates[index]["reward_preview"] = "momentum" if fit_tier == "best" else "stable" if fit_tier == "safe" else "recovery"
		candidates[index]["strategy_id"] = "flow" if fit_tier == "best" else "hold" if fit_tier == "safe" else "gambit"
		candidates[index]["strategy_label"] = "FLOW" if fit_tier == "best" else "HOLD" if fit_tier == "safe" else "GAMBIT"
		candidates[index]["consequence_preview"] = "FLOW +1" if fit_tier == "best" else "FLOW HOLDS" if fit_tier == "safe" else "FLOW RESETS"
		candidates[index]["file_personality"] = file_preview.duplicate(true)
	return candidates


func _career_level_for_xp(career_xp_value: int) -> int:
	var level := 0
	for index in ChickenState.CAREER_THRESHOLDS.size():
		if career_xp_value < ChickenState.CAREER_THRESHOLDS[index]:
			break
		level = index
	return level


func _personnel_action_career_xp_award(
	worker: ChickenState,
	action_id: StringName,
	preferred: bool,
) -> int:
	if worker == null:
		return 0
	match action_id:
		&"share_credit":
			return 6
		&"career_coaching":
			return (22 if preferred else 18) + career_coaching_xp_bonus()
		&"quota_pressure":
			return 5
	return 0


func _personnel_action_wage_delta_cents(worker: ChickenState, career_xp_award: int) -> int:
	if worker == null or career_xp_award <= 0:
		return 0
	var current_level := worker.career_level()
	var projected_level := _career_level_for_xp(
		mini(ChickenState.MAX_CAREER_XP, worker.career_xp + career_xp_award)
	)
	return maxi(
		0,
		(projected_level - current_level) * ChickenState.CAREER_LEVEL_WAGE_CENTS,
	)


func personnel_action_catalog(worker_id: int = -1) -> Array[Dictionary]:
	var preferred_action: StringName = &""
	var selected_worker: ChickenState = null
	if worker_id >= 0 and worker_id < workers.size() and workers[worker_id].employed:
		selected_worker = workers[worker_id]
		preferred_action = _preferred_personnel_action(selected_worker)
	var catalog: Array[Dictionary] = []
	for action_id in PERSONNEL_ACTION_ORDER:
		var definition: Dictionary = PERSONNEL_ACTION_DEFINITIONS[action_id]
		var preview := String(definition["preview"])
		if action_id == &"career_coaching" and career_coaching_xp_bonus() > 0:
			preview = "-$4.00  /  +%d XP (+%d preferred)  /  -6%% speed  /  -3%% crack risk" % [
				18 + career_coaching_xp_bonus(),
				22 + career_coaching_xp_bonus(),
			]
		var preferred := preferred_action == action_id
		var career_xp_award := _personnel_action_career_xp_award(
			selected_worker,
			action_id,
			preferred,
		)
		var wage_delta_cents := _personnel_action_wage_delta_cents(
			selected_worker,
			career_xp_award,
		)
		if wage_delta_cents > 0:
			preview += "  /  +$%.2f daily wage on promotion" % (
				float(wage_delta_cents) / 100.0
			)
		catalog.append({
			"id": action_id,
			"name": String(definition["name"]),
			"short_name": String(definition["short_name"]),
			"description": String(definition["description"]),
			"preview": preview,
			"cost_cents": int(definition["cost_cents"]),
			"tone": StringName(definition["tone"]),
			"preferred": preferred,
			"career_xp_award": career_xp_award,
			"projected_wage_delta_cents": wage_delta_cents,
		})
	return catalog


func personnel_action_status() -> Dictionary:
	var actions := _personnel_actions_for_day(day)
	var action_limit := personnel_action_limit()
	var used := actions.size()
	var remaining := clampi(action_limit - used, 0, action_limit)
	var available := shift_phase == ShiftPhase.RUNNING and remaining > 0
	var reason := ""
	if remaining <= 0:
		reason = "Today's %d flock %s already filed." % [
			action_limit,
			"check-in is" if action_limit == 1 else "check-ins are",
		]
	elif shift_phase != ShiftPhase.RUNNING:
		reason = "Resolve the current management decision first."
	return {
		"available": available,
		"used_today": used > 0,
		"day": day,
		"reason": reason,
		"limit": action_limit,
		"used": used,
		"remaining": remaining,
		"actions": actions.duplicate(true),
		"last_action": (
			(actions[actions.size() - 1] as Dictionary).duplicate(true)
			if not actions.is_empty() else
			{}
		),
	}


func _build_identity_snapshot() -> Dictionary:
	var preset_id := StringName(String(active_playbook.get("strategy_preset_id", "")))
	var preset := PLAYBOOK_STRATEGY_PRESET_DEFINITIONS.get(preset_id, {}) as Dictionary
	# Default AUTO is a player routing choice, not proof that mastery was taught.
	# Only the filed mastery receipt may claim a taught delegation rule.
	var auto_count := 1 if bool(active_playbook.get("mastery_auto_used", false)) else 0
	var identity_label := String(preset.get("label", "OPEN BOOK"))
	if auto_count > 0:
		identity_label += " / TAUGHT FLOCK"
	return {
		"label": identity_label,
		"strategy": String(preset_id),
		"automated_hens": auto_count,
		"side_goal": String(active_playbook.get("side_goal_id", "")),
		"summary": "%s · %d routing rule%s · %s" % [
			identity_label,
			auto_count,
			"" if auto_count == 1 else "s",
			String(active_directive_snapshot().get("short_name", "POLICY OPEN")),
		],
	}


func _campaign_legacy_evidence_snapshot() -> Dictionary:
	var strongest_worker: ChickenState
	for candidate in workers:
		if not candidate.employed:
			continue
		if strongest_worker == null or candidate.career_xp > strongest_worker.career_xp:
			strongest_worker = candidate
	var strongest_name := "THE FLOCK"
	var strongest_title := "UNFILED"
	var relationship := "FORMING"
	if strongest_worker != null:
		strongest_name = strongest_worker.display_name
		strongest_title = strongest_worker.career_title()
		relationship = strongest_worker.relationship_label()
	var combo := _playbook_combo_recipe_snapshot()
	return {
		"build": _build_identity_snapshot(),
		"strongest_hen": {"name": strongest_name, "title": strongest_title, "career_xp": strongest_worker.career_xp if strongest_worker != null else 0},
		"relationship": relationship,
		"combo": {"label": String(combo.get("label", "NO COMBO")), "complete": bool(combo.get("complete", false))},
		"challenge_modifier": String(active_playbook.get("challenge_modifier_id", "")),
		"summary": "%s built %s; %s stands as %s; the flock relationship is %s." % [strongest_name, String(_build_identity_snapshot().get("label", "OPEN BOOK")), strongest_name, strongest_title, relationship],
	}


static func challenge_seed_from_code(code: String) -> int:
	return int(challenge_state_from_code(code).get("seed", -1))


static func challenge_state_from_code(code: String) -> Dictionary:
	var normalized := code.strip_edges().to_upper()
	if not normalized.begins_with("PO-"):
		return {}
	var parts := normalized.split("-")
	if parts.size() != 3 or not parts[1].is_valid_int() or not parts[2].begins_with("D"):
		return {}
	var day_text := parts[2].trim_prefix("D")
	if not day_text.is_valid_int():
		return {}
	var seed := int(parts[1])
	var coded_day := int(day_text)
	if seed < 0 or seed > 9999 or coded_day < 1 or coded_day > 99:
		return {}
	return {"seed": seed, "day": coded_day, "code": "PO-%04d-D%d" % [seed, coded_day]}


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
		_peck_assist_charge_limit(),
	]
	if not pending_deliveries.is_empty():
		var charge_prefix := (
			"Management attention is fully allocated; "
			if charges <= 0 else
			"%d/%d attention charges are ready; " % [charges, _peck_assist_charge_limit()]
		)
		reason = "%s%d clean assisted %s awaiting farmer delivery, and each presentation restores one charge." % [
			charge_prefix,
			pending_deliveries.size(),
			("egg is" if pending_deliveries.size() == 1 else "eggs are"),
		]
	elif charges <= 0:
		reason = "Management attention is fully allocated this shift; only a pending clean assisted delivery can restore a charge."
	elif charges == _peck_assist_charge_limit():
		reason = "All %d management-attention charges are ready." % _peck_assist_charge_limit()
	return {
		"charges": charges,
		"limit": _peck_assist_charge_limit(),
		"routing_recharge_banked": routing_momentum_peck_recharge_bank > 0,
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
	var timing_window := PECK_ASSIST_TIMING_PROFILES[peck_assist_timing_profile] as Dictionary
	var window_start := float(timing_window["window_start"])
	var window_end := float(timing_window["window_end"])
	var status := {
		"available": false,
		"remaining": remaining,
		"charges": remaining,
		"limit": _peck_assist_charge_limit(),
		"routing_recharge_banked": routing_momentum_peck_recharge_bank > 0,
		"gross_interventions": peck_assist_interventions_today,
		"refunds": peck_assist_refunds_today,
		"pending_delivery": (delivery_status.get("pending_delivery", {}) as Dictionary).duplicate(true),
		"pending_delivery_count": int(delivery_status.get("pending_delivery_count", 0)),
		"delivery_reason": String(delivery_status.get("reason", "")),
		"streak": peck_assist_streak,
		"best_streak": best_peck_assist_streak,
		"timing_assist_profile": peck_assist_timing_profile,
		"window_start": window_start,
		"window_end": window_end,
		"ideal_progress": PECK_ASSIST_IDEAL_PROGRESS,
		"gold_start": PECK_ASSIST_GOLD_START,
		"gold_end": PECK_ASSIST_GOLD_END,
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
		status["reason"] = "Wait until %s is actively pecking a file." % worker.display_name
		return status
	var claim_id := worker.current_claim.id
	status["claim_id"] = claim_id
	if _assisted_claim_ids.has(claim_id):
		status["window_state"] = &"used"
		status["reason"] = "This file already carries a Priority Peck stamp."
		return status
	if _missed_assist_claim_ids.has(claim_id):
		status["window_state"] = &"missed"
		status["reason"] = "The synchronization window closed; the next file can restart the chain."
		return status
	var progress := worker.work_progress
	var score := _peck_assist_timing_score(progress)
	status["timing_score"] = score
	status["timing_label"] = _peck_assist_timing_label(score)
	if progress < window_start:
		status["window_state"] = &"not_ready"
		status["reason"] = "Build the file rhythm to %d%% before stamping." % int(window_start)
		return status
	if progress > window_end:
		status["window_state"] = &"passed"
		status["reason"] = "The safe synchronization window has passed for this file."
		return status
	status["available"] = true
	status["window_state"] = &"open"
	status["reason"] = "Stamp near %d%% for the strongest speed and shell-quality bonus." % int(PECK_ASSIST_IDEAL_PROGRESS)
	return status


## Player comfort setting. It widens only the availability window; the ideal
## point, rating thresholds, rewards, and three-charge economy remain unchanged.
## This keeps motor-timing assistance fair and separate from career saves.
func set_peck_assist_timing_profile(profile: StringName) -> bool:
	var normalized := StringName(String(profile).to_lower())
	if not PECK_ASSIST_TIMING_PROFILES.has(normalized):
		return false
	if peck_assist_timing_profile == normalized:
		return true
	peck_assist_timing_profile = normalized
	snapshot_changed.emit(snapshot())
	return true


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
		return {"accepted": false, "reason": "The active file changed before the stamp landed."}
	career_workshop.begin_day(day)
	career_workshop.loadout_locked = true

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

	var workshop_effect := ""
	if rating in [&"perfect", &"strong"]:
		career_workshop.record_strong_peck(day, worker_id, claim_id, worker.current_claim.deadline_operational_minute - _current_operational_minute())
		workshop_effect = _apply_workshop_peck(worker, claim_id, rating)
		peck_assist_streak += 1
		_record_playbook_contract_completion()
	else:
		peck_assist_streak = 0
		_break_routing_momentum(
			"Priority Peck precision fell below STRONG.",
			&"peck_precision",
			worker.id,
			worker.current_claim.id if worker.current_claim != null else -1,
		)
	best_peck_assist_streak = maxi(best_peck_assist_streak, peck_assist_streak)
	var chain_bonus_progress := mini(peck_assist_streak, 5) * 2.0
	progress_gain += chain_bonus_progress
	# UI intervention may rescue a file, but it never lays or credits an egg.
	# The normal seated worker tick must still cross the finish line.
	worker.work_progress = minf(99.0, worker.work_progress + progress_gain)

	var used_routing_recharge := routing_momentum_peck_recharge_bank > 0
	if used_routing_recharge:
		routing_momentum_peck_recharge_bank = 0
		routing_momentum_peck_recharges_used_today += 1
		_routing_momentum_free_assist_claim_ids[claim_id] = true
	else:
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
		"routing_recharge_used": used_routing_recharge,
		"potential_priority_credit_cents": 20 * mini(peck_assist_streak, 5),
		"workshop_effect": workshop_effect,
	}
	result = _normalized_peck_assist_record(result)
	last_peck_assist = result.duplicate(true)
	announcement_posted.emit(
		"PRIORITY PECK %s: %s synchronized file #%04d. Chain x%d." % [
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
			"A valid completed file is required before attention can be restored.",
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
			"No clean assisted delivery is pending for file #%04d." % claim_id
		)
		return _rejected_peck_assist_delivery(claim_id, normalized_quality, missing_reason)
	var token := token_value as Dictionary
	var expected_quality := StringName(String(token.get("quality", "")))
	if normalized_quality != expected_quality:
		return _rejected_peck_assist_delivery(
			claim_id,
			normalized_quality,
			"File #%04d was graded %s, not %s; the delivery token remains pending." % [
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
		"reason": "%s file #%04d reached the farmer; one attention charge was restored." % [
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
			"effect_chips": _directive_effect_chips(directive_id),
			"tone": StringName(definition.get("tone", &"quality")),
		})
	return catalog


func _directive_effect_chips(directive_id: StringName) -> Array[Dictionary]:
	var chips: Array[Dictionary] = []
	if not DIRECTIVE_DEFINITIONS.has(directive_id):
		return chips
	var definition := DIRECTIVE_DEFINITIONS[directive_id] as Dictionary
	var pace_delta := roundi((float(definition.get("work_multiplier", 1.0)) - 1.0) * 100.0)
	if pace_delta != 0:
		chips.append({
			"id": &"pace",
			"icon": &"egg",
			"copy": "PACE %s%d%%" % ["+" if pace_delta > 0 else "", pace_delta],
			"detail": "Production pace changes by %s%d percent for this shift." % ["+" if pace_delta > 0 else "", pace_delta],
			"beneficial": pace_delta > 0,
		})
	var strain_delta := roundi((float(definition.get("stress_multiplier", 1.0)) - 1.0) * 100.0)
	if strain_delta != 0:
		chips.append({
			"id": &"strain",
			"icon": &"flock",
			"copy": "STRAIN %s%d%%" % ["+" if strain_delta > 0 else "", strain_delta],
			"detail": "Flock stress and fatigue growth change by %s%d percent for this shift." % ["+" if strain_delta > 0 else "", strain_delta],
			"beneficial": strain_delta < 0,
		})
	var risk_delta := roundi(float(definition.get("crack_modifier", 0.0)) * 100.0)
	if risk_delta != 0:
		chips.append({
			"id": &"risk",
			"icon": &"shield",
			"copy": "RISK %s%d%%" % ["+" if risk_delta > 0 else "", risk_delta],
			"detail": "Shell-crack risk changes by %s%d percentage points for this shift." % ["+" if risk_delta > 0 else "", risk_delta],
			"beneficial": risk_delta < 0,
		})
	var compliance_delta := roundi(float(definition.get("compliance_delta", 0.0)))
	if compliance_delta != 0:
		chips.append({
			"id": &"compliance",
			"icon": &"files",
			"copy": "RULES %s%d" % ["+" if compliance_delta > 0 else "", compliance_delta],
			"detail": "Coop compliance changes immediately by %s%d." % ["+" if compliance_delta > 0 else "", compliance_delta],
			"beneficial": compliance_delta > 0,
		})
	var feed_delta_cents := int(definition.get("feed_delta_cents", 0))
	if feed_delta_cents != 0:
		chips.append({
			"id": &"feed",
			"icon": &"cash",
			"copy": "FEED %s$%.0f" % ["+" if feed_delta_cents > 0 else "-", absf(float(feed_delta_cents)) / 100.0],
			"detail": "Daily feed cost changes by %s$%.2f for this shift." % ["+" if feed_delta_cents > 0 else "-", absf(float(feed_delta_cents)) / 100.0],
			"beneficial": feed_delta_cents < 0,
		})
	return chips


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
	if _harvest_credit.review_status == HarvestCreditStateScript.STATUS_OFFER_OPEN:
		announcement_posted.emit("NEXT SHIFT HELD: file or explicitly skip the Harvest Credit release.")
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
		context_lines.append("The ranking excludes file difficulty, breaks covered, and work reassigned by management.")
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
	_harvest_credit.release_credit_gate(completed_day)
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


func _feed_procurement_capacity_scoops() -> int:
	return _facility_level_schedule_value(
		FEED_PROCUREMENT_CAPACITY_SCOOPS,
		facility_level(FEED_PROCUREMENT_COOP_ID),
		0,
	) + _campus_portfolio.feed_capacity_bonus_scoops(_campus_portfolio_context())


func _feed_demand_scoops() -> int:
	## The legacy daily bill used $2.00 as one scoop. Keeping that conversion in
	## integer arithmetic preserves the original 3 + active-hen baseline while
	## translating authored directive and incident adjustments into real demand.
	var legacy_adjustment := feed_cents_per_day - LEGACY_FULL_ROSTER_FEED_CENTS
	var neutral_feed_cents := maxi(
		BASE_FEED_COST_CENTS,
		BASE_FEED_COST_CENTS
		+ FEED_COST_PER_ACTIVE_HEN_CENTS * active_worker_count()
		+ legacy_adjustment
		+ _daily_feed_adjustment_cents
		+ _incident_feed_adjustment_cents
	)
	@warning_ignore("integer_division")
	var baseline_demand := maxi(
		3,
		(neutral_feed_cents + FEED_BASE_SPOT_UNIT_PRICE_CENTS - 1)
		/ FEED_BASE_SPOT_UNIT_PRICE_CENTS,
	)
	return maxi(
		3,
		baseline_demand
		- _campus_portfolio.feed_demand_reduction_scoops(_campus_portfolio_context()),
	)


func _feed_season_basis_points(season_id: StringName) -> int:
	match season_id:
		&"spring_hatch_surge":
			return 9_000
		&"summer_predator_migration":
			return 11_000
		&"autumn_retention_audit":
			return 10_000
		&"winter_feed_fund_squeeze":
			return 13_500
	return 10_000


func _feed_spot_unit_price_cents(target_day: int = day) -> int:
	var season := market_season_for_day(target_day)
	return _signed_half_up_ratio(
		FEED_BASE_SPOT_UNIT_PRICE_CENTS
		* _feed_season_basis_points(StringName(season.get("id", &"baseline_neutral"))),
		10_000,
	)


func _feed_offer_unit_price_cents(offer_id: StringName, target_day: int) -> int:
	if not FEED_PROCUREMENT_OFFER_DEFINITIONS.has(offer_id):
		return -1
	var definition := FEED_PROCUREMENT_OFFER_DEFINITIONS[offer_id] as Dictionary
	return _signed_half_up_ratio(
		_feed_spot_unit_price_cents(target_day)
		* int(definition.get("unit_price_basis_points", 10_000)),
		10_000,
	)


func _projected_feed_spot_cost_cents(
	demand_scoops: int,
	stock_scoops: int,
	unit_price_cents: int
) -> int:
	return maxi(0, demand_scoops - maxi(0, stock_scoops)) * maxi(0, unit_price_cents)


func current_daily_feed_cost_cents() -> int:
	if _feed_procurement.ration_applied_day == day:
		return maxi(0, _feed_procurement.spot_spend_today_cents)
	return _projected_feed_spot_cost_cents(
		_feed_demand_scoops(),
		_feed_procurement.stock_scoops(),
		_feed_spot_unit_price_cents(),
	)


func _feed_order_projected_spendable_cents(order_cost_cents: int, projected_stock_scoops: int) -> int:
	var reserve_without_feed := protected_reserve_cents() - current_daily_feed_cost_cents()
	var projected_spot_obligation := _projected_feed_spot_cost_cents(
		_feed_demand_scoops(),
		projected_stock_scoops,
		_feed_spot_unit_price_cents(),
	)
	return (
		revenue_cents
		- maxi(0, order_cost_cents)
		- maxi(0, reserve_without_feed)
		- projected_spot_obligation
	)


func _feed_procurement_order_reason(
	offer_id: StringName,
	required_level: int,
	quantity_scoops: int,
	total_cost_cents: int
) -> String:
	var level := facility_level(FEED_PROCUREMENT_COOP_ID)
	if level <= 0:
		return "Commission the Flock Provisions Co-op before filing grain orders."
	if level < required_level:
		return "%s requires Provisions Co-op level %d." % [
			String((FEED_PROCUREMENT_OFFER_DEFINITIONS[offer_id] as Dictionary)["label"]),
			required_level,
		]
	if shift_phase != ShiftPhase.REVIEW:
		return "Provisions orders are filed during shift review."
	if not pending_decision.is_empty():
		return "Resolve the closing credit memo before filing provisions orders."
	if _feed_procurement.order_used_day == day:
		return "Today's one provisions order is already filed."
	var projected_stock := _feed_procurement.stock_scoops() + quantity_scoops
	if projected_stock > _feed_procurement_capacity_scoops():
		return "The order needs %d scoops of bin space; only %d remain." % [
			quantity_scoops,
			maxi(0, _feed_procurement_capacity_scoops() - _feed_procurement.stock_scoops()),
		]
	var projected_spendable := _feed_order_projected_spendable_cents(
		total_cost_cents,
		projected_stock,
	)
	if projected_spendable < 0:
		return "Order denied: $%.2f more spendable Feed Fund is required after protected obligations." % (
			float(-projected_spendable) / 100.0
		)
	return ""


func procurement_offer_catalog() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	var demand := _feed_demand_scoops()
	var stock := _feed_procurement.stock_scoops()
	var capacity := _feed_procurement_capacity_scoops()
	var level := facility_level(FEED_PROCUREMENT_COOP_ID)
	for offer_id in FEED_PROCUREMENT_OFFER_ORDER:
		var definition := FEED_PROCUREMENT_OFFER_DEFINITIONS[offer_id] as Dictionary
		var required_level := int(definition["required_level"])
		var quantity := demand * int(definition["quantity_multiplier"])
		var unit_price := _feed_offer_unit_price_cents(offer_id, day)
		var total_cost := quantity * unit_price
		var projected_stock := stock + quantity
		var reason := _feed_procurement_order_reason(
			offer_id,
			required_level,
			quantity,
			total_cost,
		)
		offers.append({
			"id": offer_id,
			"offer_id": offer_id,
			"label": String(definition["label"]),
			"description": String(definition["description"]),
			"required_level": required_level,
			"quantity_multiplier": int(definition["quantity_multiplier"]),
			"quantity_scoops": quantity,
			"unit_price_basis_points": int(definition["unit_price_basis_points"]),
			"unit_price_cents": unit_price,
			"total_cost_cents": total_cost,
			"shelf_shifts": int(definition["shelf_shifts"]),
			"expires_day": day + int(definition["shelf_shifts"]) - 1,
			"strain_basis_points": int(definition["strain_basis_points"]),
			"morale_delta": int(definition["morale_delta"]),
			"grievance_delta": int(definition["grievance_delta"]),
			"available": level >= required_level,
			"can_authorize": reason.is_empty(),
			"reason": reason,
			"projected_stock_scoops": projected_stock,
			"capacity_scoops": capacity,
			"projected_spendable_fund_cents": _feed_order_projected_spendable_cents(
				total_cost,
				projected_stock,
			),
		})
	return offers


func authorize_feed_order(offer_id: StringName) -> Dictionary:
	if not FEED_PROCUREMENT_OFFER_DEFINITIONS.has(offer_id):
		return {
			"accepted": false,
			"action_id": &"authorize_feed_order",
			"offer_id": offer_id,
			"reason": "Select a listed provisions offer.",
		}
	var selected: Dictionary = {}
	for offer in procurement_offer_catalog():
		if StringName(offer.get("offer_id", &"")) == offer_id:
			selected = offer
			break
	if selected.is_empty():
		return {
			"accepted": false,
			"action_id": &"authorize_feed_order",
			"offer_id": offer_id,
			"reason": "Select a listed provisions offer.",
		}
	if not bool(selected.get("can_authorize", false)):
		return {
			"accepted": false,
			"action_id": &"authorize_feed_order",
			"offer_id": offer_id,
			"reason": String(selected.get("reason", "Order is not currently available.")),
		}
	var outcome := "%s filed: %d scoops prepaid for $%.2f. Finance will call any spoilage a forecasting lesson." % [
		String(selected["label"]),
		int(selected["quantity_scoops"]),
		float(selected["total_cost_cents"]) / 100.0,
	]
	var receipt: Dictionary = _feed_procurement.authorize_lot(
		offer_id,
		String(selected["label"]),
		int(selected["quantity_scoops"]),
		int(selected["unit_price_cents"]),
		_feed_procurement_capacity_scoops(),
		day,
		outcome,
	)
	if not bool(receipt.get("accepted", false)):
		return receipt
	revenue_cents -= int(receipt["total_cost_cents"])
	receipt["spendable_fund_cents"] = spendable_fund_cents()
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return receipt


func farmer_relations_gallery_snapshot() -> Dictionary:
	var gallery := _harvest_credit.snapshot()
	var status := StringName(gallery.get("status", HarvestCreditStateScript.STATUS_LOCKED))
	var evidence := (gallery.get("frozen_evidence", {}) as Dictionary).duplicate(true)
	var attribution_style := StringName(gallery.get("attribution_style", &"contested_credit"))
	var attribution := {
		"balance": int(gallery.get("attribution_balance", 0)),
		"style_id": attribution_style,
		"style_label": _harvest_credit_attribution_style_label(attribution_style),
		"worker_id": int(evidence.get("top_worker_id", -1)),
		"worker_name": String(evidence.get("top_worker_name", "")),
	}
	var canonical_offers: Array[Dictionary] = []
	for offer_value in gallery.get("offers", []) as Array:
		var offer := (offer_value as Dictionary).duplicate(true)
		var campaign_id := StringName(offer.get("campaign_id", &""))
		offer.merge({
			"id": campaign_id,
			"tagline": _harvest_credit_campaign_tagline(campaign_id, evidence),
			"evidence": _harvest_credit_campaign_evidence(evidence),
			"preview": _harvest_credit_campaign_preview(campaign_id),
			"cost_cents": 0,
			"fund_delta_cents": int(offer.get("payout_cents", 0)),
			"can_authorize": bool(offer.get("available", false)),
			"enabled": bool(offer.get("available", false)),
			"standing_delta": int(offer.get("public_standing_delta", 0)),
			"standing_points_delta": int(offer.get("public_standing_delta", 0)),
		}, true)
		canonical_offers.append(offer)
	var last_receipt := (gallery.get("last_receipt", {}) as Dictionary).duplicate(true)
	if not last_receipt.is_empty():
		last_receipt.merge({
			"standing_delta": int(last_receipt.get("public_standing_delta", 0)),
			"standing_points_delta": int(last_receipt.get("public_standing_delta", 0)),
			"cost_cents": 0,
			"fund_delta_cents": int(last_receipt.get("payout_cents", 0)),
			"attribution": {
				"balance": int(last_receipt.get("attribution_after", 0)),
				"style_id": StringName(last_receipt.get("attribution_style", &"contested_credit")),
				"style_label": _harvest_credit_attribution_style_label(
					StringName(last_receipt.get("attribution_style", &"contested_credit"))
				),
				"worker_id": int(last_receipt.get("top_worker_id", -1)),
				"worker_name": String(last_receipt.get("top_worker_name", "")),
			},
		}, true)
	gallery.merge({
		"facility_id": FARMER_RELATIONS_GALLERY_ID,
		"level": facility_level(FARMER_RELATIONS_GALLERY_ID),
		"campaign_status": status,
		"completed_day": int(evidence.get("day", 0)),
		"campaign_limit": 1,
		"campaigns_used": 1 if status in [HarvestCreditStateScript.STATUS_FILED, HarvestCreditStateScript.STATUS_SKIPPED] else 0,
		"standing_points": int(gallery.get("public_standing", 0)),
		"standing_label": String(gallery.get("public_standing_label", "UNLISTED")),
		"standing_rank": String(gallery.get("public_standing_label", "UNLISTED")),
		"standing": {
			"points": int(gallery.get("public_standing", 0)),
			"label": String(gallery.get("public_standing_label", "UNLISTED")),
		},
		"attribution": attribution,
		"shift_evidence": evidence.duplicate(true),
		"source_digest": evidence.duplicate(true),
		"offers": canonical_offers,
		"last_receipt": last_receipt,
		"planning_phase": shift_phase == ShiftPhase.REVIEW,
		"credit_memo_pending": StringName(pending_decision.get("kind", &"")) in [
			&"credit_allocation", &"major_event",
		],
	}, true)
	return gallery


func _farmgate_auction_basis_points(season_id: StringName) -> int:
	match season_id:
		&"spring_hatch_surge":
			return 10_500
		&"summer_predator_migration":
			return 9_000
		&"autumn_retention_audit":
			return 12_000
		&"winter_feed_fund_squeeze":
			return 13_500
	return 10_500


func _farmgate_basis_points_half_up(value_cents: int, basis_points: int) -> int:
	return int((value_cents * basis_points + 5_000) / 10_000)


func _farmgate_mandate_label(mandate_id: StringName) -> String:
	match mandate_id:
		FarmgateDispatchStateScript.COUNTY_AUCTION:
			return "COUNTY AUCTION"
		FarmgateDispatchStateScript.REGIONAL_SHOWCASE:
			return "REGIONAL SHOWCASE"
		FarmgateDispatchStateScript.HOLD_BASKET:
			return "HOLD THE BASKET"
	return "FARMER PICKUP"


func _farmgate_mandate_description(mandate_id: StringName) -> String:
	match mandate_id:
		FarmgateDispatchStateScript.COUNTY_AUCTION:
			return "Dispatch the oldest eggs first at the frozen seasonal county quote, less 5% commission."
		FarmgateDispatchStateScript.REGIONAL_SHOWCASE:
			return "Send up to six golden-first premium eggs at the standing-adjusted regional rate, less a $3 listing fee."
		FarmgateDispatchStateScript.HOLD_BASKET:
			return "Sell nothing this shift and pay the cold-chain cost on every egg retained."
	return "Let the farmer collect the full basket at face value with no route fee."


func _farmgate_mandate_reason(mandate_id: StringName) -> String:
	var level := facility_level(FARMGATE_DISPATCH_DEPOT_ID)
	if mandate_id not in FarmgateDispatchStateScript.MANDATE_ORDER:
		return "Select a listed Farmgate mandate."
	if level <= 0:
		return "Commission the Farmgate Dispatch Depot before filing a mandate."
	if shift_phase != ShiftPhase.REVIEW:
		return "Dispatch mandates may only be filed during shift review."
	if (
		not _farmgate_dispatch.active_mandate.is_empty()
		and int(_farmgate_dispatch.active_mandate.get("target_day", 0)) == day
	):
		return "This shift already has a frozen dispatch mandate."
	if mandate_id == FarmgateDispatchStateScript.REGIONAL_SHOWCASE and level < 3:
		return "Regional Showcase requires the Regional Route Fleet."
	if mandate_id == FarmgateDispatchStateScript.HOLD_BASKET and revenue_cents < protected_reserve_cents():
		return "Hold the Basket requires the current Feed Fund to cover protected close obligations without a sale."
	return ""


func farmgate_dispatch_mandate_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	var level := facility_level(FARMGATE_DISPATCH_DEPOT_ID)
	var season := market_season_for_day(day)
	var county_basis_points := _farmgate_auction_basis_points(
		StringName(season.get("id", &"spring_hatch_surge"))
	)
	var standing := int(_harvest_credit.public_standing)
	var eligible_lots: Array[Dictionary] = []
	for lot in _farmgate_dispatch.lots:
		if int(lot.get("expires_day", 0)) >= day:
			eligible_lots.append(lot.duplicate(true))
	for mandate_id in FarmgateDispatchStateScript.MANDATE_ORDER:
		var reason := _farmgate_mandate_reason(mandate_id)
		var projected_basis_points := 10_000
		var projected_fee_cents := 0
		var projected_base_value_cents := 0
		if mandate_id == FarmgateDispatchStateScript.COUNTY_AUCTION:
			projected_basis_points = county_basis_points
			for index in mini(_farmgate_dispatch_capacity_eggs(), eligible_lots.size()):
				projected_base_value_cents += int(eligible_lots[index].get("value_cents", 0))
		elif mandate_id == FarmgateDispatchStateScript.REGIONAL_SHOWCASE:
			projected_basis_points = 16_000 + mini(2_500, maxi(0, standing) * 50)
			var showcase_lots := eligible_lots.duplicate(true)
			showcase_lots.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
				var left_golden := StringName(left.get("quality", &"")) == &"golden"
				var right_golden := StringName(right.get("quality", &"")) == &"golden"
				if left_golden != right_golden:
					return left_golden
				if int(left.get("value_cents", 0)) != int(right.get("value_cents", 0)):
					return int(left.get("value_cents", 0)) > int(right.get("value_cents", 0))
				return int(left.get("lot_id", 0)) < int(right.get("lot_id", 0))
			)
			for index in mini(FarmgateDispatchStateScript.SHOWCASE_EGG_LIMIT, showcase_lots.size()):
				projected_base_value_cents += int(showcase_lots[index].get("value_cents", 0))
			if projected_base_value_cents > 0:
				projected_fee_cents = FarmgateDispatchStateScript.SHOWCASE_LISTING_FEE_CENTS
		elif mandate_id == FarmgateDispatchStateScript.HOLD_BASKET:
			projected_basis_points = 0
		else:
			for lot in eligible_lots:
				projected_base_value_cents += int(lot.get("value_cents", 0))
		var projected_gross_cents := _farmgate_basis_points_half_up(
			projected_base_value_cents,
			projected_basis_points,
		)
		if mandate_id == FarmgateDispatchStateScript.COUNTY_AUCTION:
			projected_fee_cents = _farmgate_basis_points_half_up(projected_gross_cents, 500)
		var projected_capacity := (
			6
			if mandate_id == FarmgateDispatchStateScript.REGIONAL_SHOWCASE else
			(_farmgate_dispatch_capacity_eggs() if mandate_id == FarmgateDispatchStateScript.COUNTY_AUCTION else _farmgate_dispatch.stock_count())
		)
		catalog.append({
			"id": mandate_id,
			"label": _farmgate_mandate_label(mandate_id),
			"description": _farmgate_mandate_description(mandate_id),
			"can_authorize": reason.is_empty(),
			"reason": reason,
			"projected_capacity": projected_capacity,
			"projected_capacity_eggs": projected_capacity,
			"projected_basis_points": projected_basis_points,
			"projected_fee_cents": projected_fee_cents,
			"projected_payout_cents": maxi(0, projected_gross_cents - projected_fee_cents),
		})
	return catalog


func authorize_farmgate_dispatch(mandate_id: StringName) -> Dictionary:
	var reason := _farmgate_mandate_reason(mandate_id)
	if not reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"authorize_farmgate_dispatch",
			"mandate_id": mandate_id,
			"reason": reason,
		}
	var season := market_season_for_day(day)
	var outcome := "%s filed for Day %d; the quote and route capacity are now frozen." % [
		_farmgate_mandate_label(mandate_id),
		day,
	]
	var receipt := _farmgate_dispatch.authorize_mandate(
		mandate_id,
		day,
		facility_level(FARMGATE_DISPATCH_DEPOT_ID),
		_farmgate_dispatch_capacity_eggs(),
		StringName(season.get("id", &"spring_hatch_surge")),
		_farmgate_auction_basis_points(StringName(season.get("id", &"spring_hatch_surge"))),
		int(_harvest_credit.public_standing),
		revenue_cents,
		protected_reserve_cents(),
		outcome,
	)
	if bool(receipt.get("accepted", false)):
		announcement_posted.emit(outcome)
		snapshot_changed.emit(snapshot())
	return receipt


func farmgate_dispatch_snapshot() -> Dictionary:
	var level := facility_level(FARMGATE_DISPATCH_DEPOT_ID)
	var enabled := level > 0
	var season_source := market_season_for_day(day)
	var season := {
		"id": StringName(season_source.get("id", &"spring_hatch_surge")),
		"label": String(season_source.get("label", "SPRING HATCH SURGE")),
		"auction_basis_points": _farmgate_auction_basis_points(
			StringName(season_source.get("id", &"spring_hatch_surge"))
		),
	}
	var active: Dictionary = _farmgate_dispatch.active_mandate.duplicate(true)
	var active_id := StringName(active.get("mandate_id", &""))
	var oldest_age := 0
	var expiring_count := 0
	for lot in _farmgate_dispatch.lots:
		oldest_age = maxi(oldest_age, day - int(lot.get("laying_day", day)))
		if int(lot.get("expires_day", day + 1)) <= day:
			expiring_count += 1
	var status := "NOT COMMISSIONED"
	if enabled:
		status = "MANDATE FILED" if active_id != &"" else "FARMER PICKUP DEFAULT"
	return {
		"facility_id": FARMGATE_DISPATCH_DEPOT_ID,
		"level": level,
		"status": status,
		"enabled": enabled,
		"storage_capacity_eggs": _farmgate_storage_capacity_eggs(),
		"dispatch_capacity_eggs": _farmgate_dispatch_capacity_eggs(),
		"shelf_life_shifts": _farmgate_shelf_life_shifts(),
		"stock_count": _farmgate_dispatch.stock_count(),
		"stock_value_cents": _farmgate_dispatch.stock_value_cents(),
		"oldest_age_shifts": oldest_age,
		"expiring_count": expiring_count,
		"lots": _farmgate_dispatch.lots_snapshot(),
		"season": season,
		"active_mandate_id": active_id,
		"active_mandate_label": _farmgate_mandate_label(active_id) if active_id != &"" else "FARMER PICKUP DEFAULT",
		"active_mandate": active,
		"review_open": shift_phase == ShiftPhase.REVIEW,
		"mandate_filed_today": active_id != &"" and int(active.get("target_day", 0)) == day,
		"mandates": farmgate_dispatch_mandate_catalog(),
		"last_authorization_receipt": _farmgate_dispatch.last_authorization.duplicate(true),
		"last_settlement_receipt": _farmgate_dispatch.last_settlement.duplicate(true),
		"lifetime_gross_cents": _farmgate_dispatch.gross_total_cents,
		"lifetime_fees_cents": _farmgate_dispatch.fees_total_cents,
		"lifetime_carry_cents": _farmgate_dispatch.carrying_total_cents,
		"lifetime_disposal_cents": _farmgate_dispatch.disposal_total_cents,
		"lifetime_payout_cents": _farmgate_dispatch.payout_total_cents,
	}


func _harvest_credit_attribution_style_label(style_id: StringName) -> String:
	match style_id:
		&"flock_authored":
			return "FLOCK-ATTRIBUTED"
		&"farmer_authored":
			return "FARMER-ATTRIBUTED"
	return "CONTESTED CREDIT"


func _harvest_credit_campaign_tagline(campaign_id: StringName, evidence: Dictionary) -> String:
	var top_name := String(evidence.get("top_worker_name", "THE TOP LAYER")).to_upper()
	match campaign_id:
		&"layer_profile":
			return "%s receives the byline attached to her verified work." % top_name
		&"clutch_results_board":
			return "Publish the completed clutch as flock-authored performance."
		&"farmer_method":
			return "Publish every egg as evidence of the farmer's management method."
	return "File one evidence-bound public campaign."


func _harvest_credit_campaign_evidence(evidence: Dictionary) -> String:
	return "Day %d: %d/%d eggs, %d sound, %d cracked, %d golden; top layer %s." % [
		int(evidence.get("day", 0)),
		int(evidence.get("eggs", 0)),
		int(evidence.get("quota", 0)),
		int(evidence.get("sound", 0)),
		int(evidence.get("cracked", 0)),
		int(evidence.get("golden", 0)),
		String(evidence.get("top_worker_name", "UNFILED")).to_upper(),
	]


func _harvest_credit_campaign_preview(campaign_id: StringName) -> String:
	match campaign_id:
		&"layer_profile":
			return "Top layer morale +6, trust +8, grievance -6, XP +6; favor -2, obedience +2, unity +2."
		&"clutch_results_board":
			return "Flock morale +4, trust +5, grievance -4; favor -4, obedience +3, unity +6."
		&"farmer_method":
			return "Flock trust -4, grievance +5, stress +2; favor +6, obedience -2, unity +4, next quota +1."
	return "Public-credit consequences are unavailable."


func file_farmer_relations_campaign(campaign_id: StringName) -> Dictionary:
	var reason := _farmer_relations_campaign_hold_reason(campaign_id)
	if not reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"file_farmer_relations_campaign",
			"campaign_id": campaign_id,
			"reason": reason,
		}
	var quote := _harvest_credit.campaign_quote(campaign_id)
	if quote.is_empty():
		return {
			"accepted": false,
			"action_id": &"file_farmer_relations_campaign",
			"campaign_id": campaign_id,
			"reason": "Select a listed Harvest Credit campaign.",
		}
	var payout_cents := int(quote.get("payout_cents", 0))
	if revenue_cents > 2_000_000_000 - payout_cents:
		return {
			"accepted": false,
			"action_id": &"file_farmer_relations_campaign",
			"campaign_id": campaign_id,
			"reason": "The Feed Fund ledger cannot safely hold this publicity settlement.",
		}
	var outcome := _farmer_relations_campaign_outcome(campaign_id, payout_cents)
	var fund_before := revenue_cents
	var receipt := _harvest_credit.commit_campaign(campaign_id, outcome)
	if receipt.is_empty():
		return {
			"accepted": false,
			"action_id": &"file_farmer_relations_campaign",
			"campaign_id": campaign_id,
			"reason": "The Harvest Credit ledger changed before this campaign was filed.",
		}
	revenue_cents += payout_cents
	_apply_farmer_relations_campaign_effects(campaign_id, receipt)
	var result := receipt.duplicate(true)
	result.merge({
		"accepted": true,
		"action_id": &"file_farmer_relations_campaign",
		"fund_before_cents": fund_before,
		"fund_after_cents": revenue_cents,
		"fund_delta_cents": revenue_cents - fund_before,
		"standing_delta": int(receipt.get("public_standing_delta", 0)),
		"standing_points_delta": int(receipt.get("public_standing_delta", 0)),
		"cost_cents": 0,
	}, true)
	announcement_posted.emit(outcome)
	farmer_relations_campaign_resolved.emit(result.duplicate(true))
	snapshot_changed.emit(snapshot())
	return result


func skip_farmer_relations_campaign() -> Dictionary:
	var reason := _farmer_relations_campaign_hold_reason(&"layer_profile", true)
	if not reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"skip_farmer_relations_campaign",
			"reason": reason,
		}
	var receipt := _harvest_credit.skip_campaign()
	if receipt.is_empty():
		return {
			"accepted": false,
			"action_id": &"skip_farmer_relations_campaign",
			"reason": "The Harvest Credit ledger changed before the release was skipped.",
		}
	var result := receipt.duplicate(true)
	result.merge({
		"accepted": true,
		"action_id": &"skip_farmer_relations_campaign",
		"fund_before_cents": revenue_cents,
		"fund_after_cents": revenue_cents,
		"fund_delta_cents": 0,
		"standing_delta": 0,
		"standing_points_delta": 0,
		"cost_cents": 0,
	}, true)
	announcement_posted.emit(String(result.get("outcome", "No public release filed.")))
	farmer_relations_campaign_resolved.emit(result.duplicate(true))
	snapshot_changed.emit(snapshot())
	return result


func _farmer_relations_campaign_hold_reason(
	campaign_id: StringName,
	skipping: bool = false,
) -> String:
	if not skipping and campaign_id not in HarvestCreditStateScript.CAMPAIGN_ORDER:
		return "Select a listed Harvest Credit campaign."
	if shift_phase != ShiftPhase.REVIEW:
		return "Harvest Credit campaigns may only be filed during shift review."
	if facility_level(FARMER_RELATIONS_GALLERY_ID) <= 0:
		return "Commission the Harvest Credit Gallery before filing public work."
	if not pending_decision.is_empty():
		return "File the closing credit memo before publishing its public version."
	match _harvest_credit.review_status:
		HarvestCreditStateScript.STATUS_PRE_CREDIT:
			return "File the closing credit memo before publishing its public version."
		HarvestCreditStateScript.STATUS_FILED:
			return "This completed shift already has a filed Harvest Credit campaign."
		HarvestCreditStateScript.STATUS_SKIPPED:
			return "This completed shift's public release was already skipped."
		HarvestCreditStateScript.STATUS_LOCKED:
			return "The Gallery was not commissioned when this shift's evidence closed."
		HarvestCreditStateScript.STATUS_OFFER_OPEN:
			return ""
	return "No completed-shift publicity offer is open."


func _farmer_relations_campaign_outcome(campaign_id: StringName, payout_cents: int) -> String:
	var worker_name := String(_harvest_credit.frozen_evidence.get("top_worker_name", "THE TOP LAYER"))
	match campaign_id:
		&"layer_profile":
			return "%s received the public byline; the Gallery contract paid $%.2f." % [
				worker_name,
				float(payout_cents) / 100.0,
			]
		&"clutch_results_board":
			return "The flock's verified clutch reached the results wall; the Gallery contract paid $%.2f." % (float(payout_cents) / 100.0)
		&"farmer_method":
			return "The farmer's method claimed the completed clutch; the Gallery contract paid $%.2f and the next quota noticed." % (float(payout_cents) / 100.0)
	return "Harvest Credit campaign filed."


func _apply_farmer_relations_campaign_effects(campaign_id: StringName, receipt: Dictionary) -> void:
	var top_worker_id := int(receipt.get("top_worker_id", -1))
	match campaign_id:
		&"layer_profile":
			if top_worker_id >= 0 and top_worker_id < workers.size():
				var top_worker := workers[top_worker_id]
				top_worker.morale = minf(100.0, top_worker.morale + 6.0)
				top_worker.manager_trust = minf(100.0, top_worker.manager_trust + 8.0)
				top_worker.grievance = maxf(0.0, top_worker.grievance - 6.0)
				top_worker.add_career_xp(6)
			executive_confidence = maxf(0.0, executive_confidence - 2.0)
			compliance = minf(100.0, compliance + 2.0)
			solidarity = minf(100.0, solidarity + 2.0)
		&"clutch_results_board":
			for worker in workers:
				if not worker.employed:
					continue
				worker.morale = minf(100.0, worker.morale + 4.0)
				worker.manager_trust = minf(100.0, worker.manager_trust + 5.0)
				worker.grievance = maxf(0.0, worker.grievance - 4.0)
			executive_confidence = maxf(0.0, executive_confidence - 4.0)
			compliance = minf(100.0, compliance + 3.0)
			solidarity = minf(100.0, solidarity + 6.0)
		&"farmer_method":
			for worker in workers:
				if not worker.employed:
					continue
				worker.manager_trust = maxf(0.0, worker.manager_trust - 4.0)
				worker.grievance = minf(100.0, worker.grievance + 5.0)
				worker.stress = minf(100.0, worker.stress + 2.0)
			executive_confidence = minf(100.0, executive_confidence + 6.0)
			compliance = maxf(0.0, compliance - 2.0)
			solidarity = minf(100.0, solidarity + 4.0)
			quota_target = mini(10_000, quota_target + 1)


func feed_procurement_snapshot() -> Dictionary:
	var demand := _feed_demand_scoops()
	var stock := _feed_procurement.stock_scoops()
	var spot_quote := _feed_spot_unit_price_cents()
	var season := market_season_for_day(day)
	var season_id := StringName(season.get("id", &"baseline_neutral"))
	var end_day := int(season.get("end_day", day + FEED_CHARTER_LENGTH_SHIFTS - 1))
	var orders_used := 1 if _feed_procurement.order_used_day == day else 0
	return {
		"facility_id": FEED_PROCUREMENT_COOP_ID,
		"level": facility_level(FEED_PROCUREMENT_COOP_ID),
		"capacity_scoops": _feed_procurement_capacity_scoops(),
		"stock_scoops": stock,
		"demand_scoops": demand,
		"stock_after_demand_scoops": maxi(0, stock - demand),
		"spot_shortage_scoops": maxi(0, demand - stock),
		"coverage_shifts": float(stock) / maxf(1.0, float(demand)),
		"season": {
			"id": season_id,
			"label": String(season.get("label", "BASELINE NEUTRAL BOOK")),
			"start_day": int(season.get("start_day", day)),
			"end_day": end_day,
			"days_remaining": maxi(0, int(season.get("days_remaining", end_day - day + 1))),
			"price_basis_points": _feed_season_basis_points(season_id),
		},
		"charter": {
			"length_shifts": FEED_CHARTER_LENGTH_SHIFTS,
			"renewal_day": end_day + 1,
			"renewal_due": day == int(season.get("start_day", day)),
		},
		"base_spot_unit_price_cents": FEED_BASE_SPOT_UNIT_PRICE_CENTS,
		"spot_unit_price_cents": spot_quote,
		"spot_obligation_cents": current_daily_feed_cost_cents(),
		"order_limit": FEED_PROCUREMENT_ORDER_LIMIT,
		"orders_used_today": orders_used,
		"planning_open": (
			facility_level(FEED_PROCUREMENT_COOP_ID) > 0
			and shift_phase == ShiftPhase.REVIEW
			and pending_decision.is_empty()
		),
		"offers": procurement_offer_catalog(),
		"lots": _feed_procurement.lots_snapshot(),
		"procurement_spend_today_cents": _feed_procurement.procurement_spend_today_cents,
		"procurement_spend_total_cents": _feed_procurement.procurement_spend_total_cents,
		"spot_spend_today_cents": _feed_procurement.spot_spend_today_cents,
		"spot_spend_total_cents": _feed_procurement.spot_spend_total_cents,
		"spoiled_today_scoops": _feed_procurement.spoiled_today_scoops,
		"spoiled_total_scoops": _feed_procurement.spoiled_total_scoops,
		"spoiled_today_value_cents": _feed_procurement.spoiled_today_value_cents,
		"spoiled_total_value_cents": _feed_procurement.spoiled_total_value_cents,
		"consumed_today_scoops": _feed_procurement.consumed_today_scoops,
		"consumed_inventory_today_scoops": _feed_procurement.consumed_inventory_today_scoops,
		"consumed_spot_today_scoops": _feed_procurement.consumed_spot_today_scoops,
		"consumed_value_today_cents": _feed_procurement.consumed_value_today_cents,
		"active_ration": _feed_procurement.active_ration_snapshot(),
		"last_order": _feed_procurement.last_order.duplicate(true),
		"last_consumption": _feed_procurement.last_consumption.duplicate(true),
		"last_spoilage": _feed_procurement.last_spoilage.duplicate(true),
	}


func _consume_feed_for_shift() -> Dictionary:
	var old_ration: Dictionary = _feed_procurement.active_ration_snapshot()
	var receipt: Dictionary = _feed_procurement.consume(
		_feed_demand_scoops(),
		_feed_spot_unit_price_cents(),
		day,
	)
	if receipt.is_empty():
		return receipt
	var new_ration: Dictionary = _feed_procurement.active_ration_snapshot()
	var morale_delta := (
		float(new_ration.get("morale_millipoints", 0))
		- float(old_ration.get("morale_millipoints", 0))
	) / 1_000.0
	var grievance_delta := (
		float(new_ration.get("grievance_millipoints", 0))
		- float(old_ration.get("grievance_millipoints", 0))
	) / 1_000.0
	if not is_zero_approx(morale_delta):
		_adjust_workers(morale_delta, 0.0, 0.0)
	if not is_zero_approx(grievance_delta):
		_adjust_worker_relationships(0.0, grievance_delta)
	return receipt


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
	_ensure_active_playbook()
	_decision_serial += 1
	shift_phase = ShiftPhase.AWAITING_DIRECTIVE
	var scenario := scenario_identity_snapshot()
	var favored_directive := StringName(scenario.get("favored_directive", &""))
	var options: Array[Dictionary] = []
	for directive in directive_catalog():
		options.append({
			"id": directive["id"],
			"label": directive["name"],
			"short_label": directive["short_name"],
			"tagline": (
				"SCENARIO FIT  /  %s" % String(directive["tagline"])
				if StringName(directive["id"]) == favored_directive else
				String(directive["tagline"])
			),
			"preview": directive["preview"],
			"effect_chips": (directive.get("effect_chips", []) as Array).duplicate(true),
			"cost_cents": 0,
			"tone": directive["tone"],
			"scenario_fit": StringName(directive["id"]) == favored_directive,
		})
	var docket_id := String(case_docket_snapshot().get("id", "PO-1701"))
	var scenario_short := String(scenario.get("short", "BASELINE"))
	pending_decision = {
		"serial": _decision_serial,
		"kind": &"directive",
		"id": &"morning_directive",
		"day": day,
		"eyebrow": "MORNING DIRECTIVE  /  DAY %d  /  %s%s" % [
			day,
			docket_id,
			("  /  %s" % scenario_short) if favored_directive != &"" else "",
		],
		"title": "CHOOSE TODAY'S MANAGEMENT POLICY",
		"body": (
			String(scenario.get("opening_rule", "Match the highlighted scenario fit or choose a different tradeoff."))
			if favored_directive != &"" and day == 1 else
			String(scenario.get("victory_twist", "Choose the policy that prepares the permanent record."))
			if favored_directive != &"" and day == PROBATION_CAMPAIGN_SHIFTS else
			"Match the highlighted scenario fit or choose a different tradeoff."
			if favored_directive != &"" else
			"Choose the tradeoff that fits today's orders."
		),
		"options": options,
		"scenario": scenario.duplicate(true),
	}


func _apply_operations_shift_pressure() -> void:
	## Directive resolution is the single authoritative morning boundary. A
	## RUNNING checkpoint therefore already contains these deltas, while an
	## AWAITING_DIRECTIVE checkpoint cannot have received them yet.
	var grievance_delta := float(rooster_surveillance_grievance_millipoints()) / 1000.0
	var stress_delta := float(rooster_surveillance_stress_millipoints()) / 1000.0
	if grievance_delta > 0.0 or stress_delta > 0.0:
		for worker in workers:
			if not worker.employed:
				continue
			worker.grievance = clampf(worker.grievance + grievance_delta, 0.0, 100.0)
			worker.stress = clampf(worker.stress + stress_delta, 0.0, 100.0)
	solidarity = clampf(
		solidarity + float(rooster_surveillance_solidarity_millipoints()) / 1000.0,
		0.0,
		100.0,
	)
	compliance = clampf(
		compliance - float(automation_compliance_exposure_millipoints()) / 1000.0,
		0.0,
		100.0,
	)
	_apply_manager_posture_relationships()


func _manager_targets_worker(manager: Dictionary, worker: ChickenState) -> bool:
	if not worker.employed:
		return false
	match StringName(String(manager.get("assignment_id", "whole_flock"))):
		&"front_row":
			return worker.desk_index >= 0 and worker.desk_index <= 2
		&"back_row":
			return worker.desk_index >= 3
		&"auto_desk":
			return worker.assigned_lane == AUTO_ASSIGNMENT
		&"at_risk":
			var at_risk := _most_stressed_worker_id()
			return worker.id == at_risk
	return true


func _most_stressed_worker_id() -> int:
	var selected_id := -1
	var selected_risk := -INF
	for worker in workers:
		if not worker.employed:
			continue
		var risk := worker.stress + worker.grievance - worker.manager_trust * 0.25
		if risk > selected_risk:
			selected_risk = risk
			selected_id = worker.id
	return selected_id


func _manager_effect_for_worker(worker: ChickenState) -> Dictionary:
	var work_bp := 10_000
	var crack_bp := 0
	var directive_ids: Dictionary[StringName, bool] = {}
	for manager in manager_roster:
		if not _manager_targets_worker(manager, worker):
			continue
		if not bool(manager.get("posture_filed", false)):
			continue
		var posture_id := StringName(String(manager.get("posture_id", "coach")))
		var definition := MANAGER_POSTURE_DEFINITIONS.get(posture_id, {}) as Dictionary
		work_bp += int(definition.get("work_bp", 0))
		crack_bp += int(definition.get("crack_bp", 0))
		directive_ids[posture_id] = true
	var conflicts := 0
	if directive_ids.has(&"chase_quota") and directive_ids.has(&"protect_quality"):
		conflicts += 1
	if directive_ids.has(&"coach") and directive_ids.has(&"audit"):
		conflicts += 1
	var excess_managers := maxi(0, manager_roster.size() * 2 - active_worker_count())
	work_bp -= excess_managers * 200 + conflicts * 300
	return {
		"work_multiplier": clampf(float(work_bp) / 10_000.0, 0.65, 1.35),
		"crack_modifier": clampf(float(crack_bp) / 10_000.0, -0.20, 0.20),
		"conflicts": conflicts,
		"excess_managers": excess_managers,
	}


func _apply_manager_posture_relationships() -> void:
	management_reports_today = manager_roster.size()
	management_reports_total += management_reports_today
	management_visibility_today = 0
	for manager in manager_roster:
		var posture_id := StringName(String(manager.get("posture_id", "coach")))
		var definition := MANAGER_POSTURE_DEFINITIONS.get(posture_id, {}) as Dictionary
		if not bool(manager.get("posture_filed", false)):
			continue
		if posture_id == &"visibility":
			management_visibility_today += 1
			executive_confidence = minf(100.0, executive_confidence + 0.5)
		elif posture_id == &"audit":
			compliance = minf(100.0, compliance + 0.75)
		for worker in workers:
			if not _manager_targets_worker(manager, worker):
				continue
			worker.stress = clampf(worker.stress + float(definition.get("stress", 0.0)), 0.0, 100.0)
			worker.manager_trust = clampf(worker.manager_trust + float(definition.get("trust", 0.0)), 0.0, 100.0)
			worker.grievance = clampf(worker.grievance + float(definition.get("grievance", 0.0)), 0.0, 100.0)


func _resolve_directive(directive_id: StringName) -> bool:
	if shift_phase != ShiftPhase.AWAITING_DIRECTIVE or not DIRECTIVE_DEFINITIONS.has(directive_id):
		return false
	var definition: Dictionary = DIRECTIVE_DEFINITIONS[directive_id]
	var scenario := scenario_identity_snapshot()
	var scenario_fit := StringName(scenario.get("favored_directive", &"")) == directive_id
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
	_apply_scenario_directive_modifier(directive_id)
	_apply_operations_shift_pressure()
	_consume_feed_for_shift()
	var decision_id := StringName(pending_decision.get("id", &"morning_directive"))
	pending_decision.clear()
	shift_phase = ShiftPhase.RUNNING
	_release_due_market_contract_claims()
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
		"scenario": scenario.duplicate(true),
		"scenario_fit": scenario_fit,
	})
	snapshot_changed.emit(snapshot())
	return true


func _incident_choice_definition(incident_id: StringName, option_id: StringName) -> Dictionary:
	if not INCIDENT_DEFINITIONS.has(incident_id):
		return {}
	var definition := INCIDENT_DEFINITIONS[incident_id] as Dictionary
	for choice_value in definition.get("choices", []):
		if not choice_value is Dictionary:
			continue
		var choice := choice_value as Dictionary
		if StringName(choice.get("id", &"")) == option_id:
			return choice.duplicate(true)
	return {}


func _incident_response_snapshot(record: Dictionary) -> Dictionary:
	var incident_id := StringName(record.get("incident_id", &""))
	var option_id := StringName(record.get("option_id", &""))
	var choice := _incident_choice_definition(incident_id, option_id)
	if choice.is_empty():
		return {}
	var short_title := String(INCIDENT_SHORT_TITLES.get(incident_id, "OFFICE INCIDENT"))
	var option_label := String(choice.get("label", "RESPONSE"))
	var response := {
		"version": INCIDENT_RESPONSE_VERSION,
		"day": int(record.get("day", 0)),
		"serial": int(record.get("serial", 0)),
		"incident_id": incident_id,
		"incident_title": short_title,
		"option_id": option_id,
		"option_label": option_label,
		"tone": StringName(choice.get("tone", &"")),
		"outcome": String(choice.get("outcome", "Incident response recorded.")),
		"summary": "%s / %s" % [short_title, option_label],
	}
	var precedent := choice.get("precedent", {}) as Dictionary
	if not precedent.is_empty():
		response["precedent"] = precedent.duplicate(true)
	return response


func _record_standard_incident_response(
	incident_id: StringName,
	option_id: StringName,
	response_day: int = -1,
	serial: int = -1,
) -> Dictionary:
	if _incident_choice_definition(incident_id, option_id).is_empty():
		return {}
	if response_day < 1:
		response_day = day
	if serial < 1:
		serial = _decision_serial
	var case_memory := incident_follow_through_snapshot(incident_id)
	var case_pivot := _record_incident_pivot_mastery(
		incident_id, option_id, response_day, serial, case_memory
	)
	var record := {
		"version": INCIDENT_RESPONSE_VERSION,
		"day": response_day,
		"serial": serial,
		"incident_id": incident_id,
		"option_id": option_id,
	}
	incident_response_history.append(record)
	while incident_response_history.size() > INCIDENT_RESPONSE_HISTORY_LIMIT:
		incident_response_history.pop_front()
	var response := _incident_response_snapshot(record)
	if not case_pivot.is_empty():
		response["case_pivot"] = case_pivot.duplicate(true)
	return response


func incident_responses_for_day(target_day: int) -> Array[Dictionary]:
	var responses: Array[Dictionary] = []
	for record in incident_response_history:
		if int(record.get("day", 0)) != target_day:
			continue
		var response := _incident_response_snapshot(record)
		if not response.is_empty():
			responses.append(response)
	return responses


func _latest_incident_response(
	incident_id: StringName,
	response_history: Array,
) -> Dictionary:
	for index in range(response_history.size() - 1, -1, -1):
		var record_value: Variant = response_history[index]
		if (
			record_value is Dictionary
			and StringName((record_value as Dictionary).get("incident_id", &"")) == incident_id
		):
			return (record_value as Dictionary).duplicate(true)
	return {}


func incident_follow_through_snapshot(
	incident_id: StringName,
	response_history_value: Variant = null,
) -> Dictionary:
	var response_history: Array = incident_response_history
	if response_history_value is Array:
		response_history = response_history_value as Array
	var source_incident_id := StringName(INCIDENT_PAIR_SOURCE.get(incident_id, &""))
	if source_incident_id == &"":
		return {}
	var source := _latest_incident_response(source_incident_id, response_history)
	if source.is_empty():
		return {}
	var source_option := StringName(source.get("option_id", &""))
	var target_definitions := INCIDENT_FOLLOW_THROUGH_DEFINITIONS.get(incident_id, {}) as Dictionary
	var definition := target_definitions.get(source_option, {}) as Dictionary
	if definition.is_empty():
		return {}
	var follow_through := {
		"version": INCIDENT_RESPONSE_VERSION,
		"source_day": int(source.get("day", 0)),
		"source_serial": int(source.get("serial", 0)),
		"source_incident_id": StringName(source.get("incident_id", &"")),
		"source_option_id": source_option,
	}
	follow_through.merge(definition.duplicate(true), true)
	return follow_through


func _incident_pivot_receipt(
	incident_id: StringName,
	option_id: StringName,
	pivot_day: int,
	pivot_serial: int,
	case_memory: Dictionary,
) -> Dictionary:
	var affected_option_id := StringName(case_memory.get("affected_option_id", &""))
	if affected_option_id == &"" or option_id != affected_option_id:
		return {}
	var pair_id := StringName(INCIDENT_PAIR_IDS.get(incident_id, &""))
	var source_incident_id := StringName(case_memory.get("source_incident_id", &""))
	var source_option_id := StringName(case_memory.get("source_option_id", &""))
	var source_day := int(case_memory.get("source_day", 0))
	var source_serial := int(case_memory.get("source_serial", 0))
	if (
		pair_id == &""
		or pair_id != StringName(INCIDENT_PAIR_IDS.get(source_incident_id, &""))
		or StringName(INCIDENT_PAIR_SOURCE.get(incident_id, &"")) != source_incident_id
		or _incident_choice_definition(source_incident_id, source_option_id).is_empty()
		or _incident_choice_definition(incident_id, option_id).is_empty()
		or source_day < 1
		or source_day > pivot_day
		or source_serial < 1
		or source_serial >= pivot_serial
	):
		return {}
	return {
		"version": INCIDENT_PIVOT_MASTERY_VERSION,
		"pair_id": pair_id,
		"source_day": source_day,
		"source_serial": source_serial,
		"source_incident_id": source_incident_id,
		"source_option_id": source_option_id,
		"pivot_day": pivot_day,
		"pivot_serial": pivot_serial,
		"pivot_incident_id": incident_id,
		"pivot_option_id": option_id,
	}


func _record_incident_pivot_mastery(
	incident_id: StringName,
	option_id: StringName,
	pivot_day: int,
	pivot_serial: int,
	case_memory: Dictionary,
) -> Dictionary:
	var receipt := _incident_pivot_receipt(
		incident_id, option_id, pivot_day, pivot_serial, case_memory
	)
	if receipt.is_empty():
		return {}
	var pair_id := StringName(receipt.get("pair_id", &""))
	for existing: Dictionary in incident_pivot_mastery_receipts:
		if StringName(existing.get("pair_id", &"")) == pair_id:
			return {}
	incident_pivot_mastery_receipts.append(receipt.duplicate(true))
	return receipt


func incident_pivot_mastery_snapshot() -> Dictionary:
	var pair_ids: Array[String] = []
	var rows: Array[Dictionary] = []
	var mastered: Dictionary[StringName, bool] = {}
	for receipt: Dictionary in incident_pivot_mastery_receipts:
		var pair_id := StringName(receipt.get("pair_id", &""))
		if pair_id in INCIDENT_PAIR_ORDER and not mastered.has(pair_id):
			mastered[pair_id] = true
			pair_ids.append(String(pair_id))
	for pair_id: StringName in INCIDENT_PAIR_ORDER:
		rows.append({
			"pair_id": pair_id,
			"label": String(INCIDENT_PAIR_LABELS.get(pair_id, "CONNECTED CASE")),
			"mastered": mastered.has(pair_id),
		})
	var mastered_count := pair_ids.size()
	return {
		"version": INCIDENT_PIVOT_MASTERY_VERSION,
		"mastered_count": mastered_count,
		"total_count": INCIDENT_PAIR_ORDER.size(),
		"mastered_pair_ids": pair_ids,
		"rows": rows,
		"last_receipt": (
			incident_pivot_mastery_receipts.back().duplicate(true)
			if not incident_pivot_mastery_receipts.is_empty() else
			{}
		),
		"complete": mastered_count == INCIDENT_PAIR_ORDER.size(),
	}


func active_incident_precedent_snapshots() -> Array[Dictionary]:
	var precedents: Array[Dictionary] = []
	var represented_pairs: Dictionary[StringName, bool] = {}
	for index in range(incident_response_history.size() - 1, -1, -1):
		var record := incident_response_history[index]
		var response := _incident_response_snapshot(record)
		var source_incident_id := StringName(response.get("incident_id", &""))
		var pair_id := StringName(INCIDENT_PAIR_IDS.get(source_incident_id, &""))
		if pair_id == &"" or represented_pairs.has(pair_id):
			continue
		var precedent := response.get("precedent", {}) as Dictionary
		if precedent.is_empty():
			continue
		represented_pairs[pair_id] = true
		precedents.append({
			"version": INCIDENT_RESPONSE_VERSION,
			"pair_id": pair_id,
			"source_day": int(response.get("day", 0)),
			"source_incident_id": source_incident_id,
			"source_option_id": StringName(response.get("option_id", &"")),
			"source_summary": String(response.get("summary", "INCIDENT RESPONSE")),
			"target_incident_id": StringName(precedent.get("target_incident_id", &"")),
			"target_label": String(precedent.get("target_label", "NEXT RELATED CASE")),
			"strategy_label": String(precedent.get("strategy_label", "PIVOT OPPORTUNITY")),
			"summary": String(precedent.get("summary", "A prior response changes the next related case.")),
		})
	return precedents


func active_incident_precedent_snapshot() -> Dictionary:
	var precedents := active_incident_precedent_snapshots()
	return precedents[0].duplicate(true) if not precedents.is_empty() else {}


func _incident_choices(incident_id: StringName) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	if not INCIDENT_DEFINITIONS.has(incident_id):
		return choices
	var follow_through := incident_follow_through_snapshot(incident_id)
	var follow_through_id := StringName(follow_through.get("id", &""))
	var definition := INCIDENT_DEFINITIONS[incident_id] as Dictionary
	for choice_value in definition.get("choices", []):
		var choice := (choice_value as Dictionary).duplicate(true)
		var option_id := StringName(choice.get("id", &""))
		if incident_id == &"ledger_molt" and option_id == &"patch":
			choice["cost_cents"] = ledger_molt_patch_cost_cents()
			choice["preview"] = "Cost $%.2f  ·  +4 obedience  ·  -4%% crack risk this shift" % (
				float(ledger_molt_patch_cost_cents()) / 100.0
			)
		elif incident_id == &"ledger_molt" and option_id == &"spreadsheet":
			choice["cost_cents"] = 0
			choice["preview"] = "No cost  ·  +5%% speed  ·  +%.1f%% crack risk  ·  -%.1f obedience" % [
				float(ledger_molt_spreadsheet_crack_basis_points()) / 100.0,
				float(ledger_molt_spreadsheet_compliance_loss_millipoints()) / 1000.0,
			]
		elif incident_id == FINAL_HEARING_INCIDENT_ID:
			var scenario := scenario_identity_snapshot()
			var favored_option := StringName(scenario.get("favored_finale_option", &""))
			choice["scenario_fit"] = option_id == favored_option
			if option_id == favored_option:
				choice["tagline"] = "SCENARIO FIT  /  " + String(choice.get("tagline", "File the permanent rule."))
				choice["preview"] = String(choice.get("preview", "")) + "  /  scenario leverage +"
		match follow_through_id:
			&"transparency_to_shadow_sheet":
				if option_id == &"spreadsheet":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"+5% speed", "+7% speed"
					)
			&"story_surplus_to_patch":
				if option_id == &"patch":
					var discounted_patch_cents := maxi(0, int(choice.get("cost_cents", 0)) - 400)
					choice["cost_cents"] = discounted_patch_cents
					choice["preview"] = "Cost $%.2f  ·  +4 obedience  ·  -4%% crack risk this shift" % (
						float(discounted_patch_cents) / 100.0
					)
			&"shadow_evidence_to_ledger":
				if option_id == &"show_ledger":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"-6 farmer favor", "-4 farmer favor"
					)
			&"clean_audit_to_story":
				if option_id == &"polish_story":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"+$16 fund", "+$20 fund"
					)
			&"savings_to_breaks":
				if option_id == &"grant_breaks":
					choice["cost_cents"] = 400
					choice["preview"] = String(choice.get("preview", "")).replace("Cost $6", "Cost $4")
			&"fed_flock_to_denial":
				if option_id == &"deny_breaks":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"+3 farmer favor", "+5 farmer favor"
					)
			&"grievance_to_grain":
				if option_id == &"buy_grain":
					choice["cost_cents"] = 1200
					choice["preview"] = String(choice.get("preview", "")).replace("Cost $16", "Cost $12")
			&"rested_flock_to_portions":
				if option_id == &"optimize_portions":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"Daily feed -$8", "Daily feed -$10"
					)
			&"manager_byline_to_cancel":
				if option_id == &"cancel_status_sync":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"flock trust +2", "flock trust +4"
					)
			&"layer_results_to_syncs":
				if option_id == &"attend_status_sync":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"+8 farmer favor", "+10 farmer favor"
					)
			&"minutes_to_layers":
				if option_id == &"credit_layers":
					choice["cost_cents"] = 600
					choice["preview"] = String(choice.get("preview", "")).replace("Cost $10", "Cost $6")
			&"cancel_bargain_to_roosters":
				if option_id == &"credit_roosters":
					choice["preview"] = String(choice.get("preview", "")).replace(
						"+10 farmer favor", "+12 farmer favor"
					)
			&"staged_audit_to_variance":
				if option_id == &"authorize_cooling":
					choice["cost_cents"] = 800
					choice["preview"] = String(choice.get("preview", "")).replace("Cost $12", "Cost $8")
		var affected_option_id := StringName(follow_through.get("affected_option_id", &""))
		if affected_option_id != &"" and option_id == affected_option_id:
			choice["case_memory_active"] = true
			choice["case_memory_label"] = String(follow_through.get(
				"strategy_label", "PIVOT OPPORTUNITY"
			))
			if follow_through_id in [
				&"staged_audit_to_variance", &"variance_to_staged_audit", &"tracking_to_desktop",
				&"desktop_to_tracking", &"success_to_deck", &"deck_to_success",
			]:
				choice["preview"] = String(choice.get("preview", "")) + "  /  callback trust +"
			elif follow_through_id in [
				&"cold_room_to_cooling", &"cooling_to_open_audit", &"privacy_to_evacuate",
				&"evacuation_to_privacy", &"claimant_to_flock", &"flock_to_claimant",
			]:
				choice["preview"] = String(choice.get("preview", "")) + "  /  callback speed +"
		choices.append(choice)
	return choices


func _incident_option_cost_cents(incident_id: StringName, option_id: StringName) -> int:
	## Never trust a serialized presentation option for money. Facility ownership
	## cannot change mid-shift, so the authoritative tier schedule is stable from
	## incident opening through resolution and restoration.
	for choice in _incident_choices(incident_id):
		if StringName(choice.get("id", &"")) == option_id:
			return maxi(0, int(choice.get("cost_cents", 0)))
	return 0


func _refill_incident_bag() -> void:
	_incident_bag.assign(INCIDENT_ORDER)
	if _last_standard_incident_id == &"":
		# Keep the two taught day-one cases stable, then let the career seed author
		# the rest of the very first probation docket. The bag is consumed from the
		# back, so the onboarding cases are appended in reverse draw order after the
		# remaining ten cases have been shuffled. Previously all twelve cases were
		# merely reversed here, which meant a five-shift run never reached a seeded
		# shuffle and every replay docket produced the same strategic environment.
		_incident_bag.erase(&"ledger_molt")
		_incident_bag.erase(&"wellness_request")
		for index in range(_incident_bag.size() - 1, 0, -1):
			var swap_index := _incident_rng.randi_range(0, index)
			var held := _incident_bag[index]
			_incident_bag[index] = _incident_bag[swap_index]
			_incident_bag[swap_index] = held
		_incident_bag.append(&"wellness_request")
		_incident_bag.append(&"ledger_molt")
	else:
		for index in range(_incident_bag.size() - 1, 0, -1):
			var swap_index := _incident_rng.randi_range(0, index)
			var held := _incident_bag[index]
			_incident_bag[index] = _incident_bag[swap_index]
			_incident_bag[swap_index] = held
	# The bag is consumed from the back. Keep the rotation boundary readable:
	# a player never receives the same standard incident twice in a row.
	if (
		_incident_bag.size() > 1
		and _last_standard_incident_id != &""
		and _incident_bag.back() == _last_standard_incident_id
	):
		var held := _incident_bag[_incident_bag.size() - 1]
		_incident_bag[_incident_bag.size() - 1] = _incident_bag[0]
		_incident_bag[0] = held


func _next_standard_incident_id() -> StringName:
	if _incident_bag.is_empty():
		_refill_incident_bag()
	var incident_id: StringName = _incident_bag.pop_back()
	_last_standard_incident_id = incident_id
	return incident_id


func case_docket_snapshot() -> Dictionary:
	var last_response: Dictionary = {}
	if not incident_response_history.is_empty():
		last_response = _incident_response_snapshot(incident_response_history.back())
	var active_precedents := active_incident_precedent_snapshots()
	return {
		"id": "PO-%04d" % posmod(_career_seed, 10_000),
		"career_seed": _career_seed,
		"remaining_in_rotation": _incident_bag.size(),
		"rotation_size": INCIDENT_ORDER.size(),
		"last_incident_id": _last_standard_incident_id,
		"last_response": last_response,
		"active_precedent": active_precedents[0].duplicate(true) if not active_precedents.is_empty() else {},
		"active_precedents": active_precedents,
		"pivot_mastery": incident_pivot_mastery_snapshot(),
		"scenario": scenario_identity_snapshot(),
		"final_hearing": final_hearing_snapshot(),
	}


func scenario_identity_snapshot() -> Dictionary:
	# PO-1701 and internal economy fixtures remain neutral. Each selectable replay
	# docket receives one deterministic pressure identity that makes the best
	# morning policy depend on the current file instead of a global build.
	if _career_seed not in AUTHORED_SCENARIO_SEEDS:
		return {
			"id": &"baseline_book",
			"name": "BASELINE BOOK",
			"short": "BASELINE",
			"icon": &"files",
			"favored_directive": &"",
			"promise": "No docket policy receives a scenario advantage.",
		}
	var scenario_id: StringName = SCENARIO_SEED_IDS.get(_career_seed, &"harvest_surge")
	var result := (SCENARIO_IDENTITIES[scenario_id] as Dictionary).duplicate(true)
	result["id"] = scenario_id
	result["seed"] = _career_seed
	return result


static func replay_scenario_catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{
		"id": "baseline_book",
		"name": "BASELINE BOOK",
		"short": "BASELINE",
		"seed": 1701,
		"opening_rule": "The proven five-shift filing with no scenario advantage.",
	}]
	for seed_value in AUTHORED_SCENARIO_SEEDS:
		var scenario_id: StringName = SCENARIO_SEED_IDS[seed_value]
		var scenario := (SCENARIO_IDENTITIES[scenario_id] as Dictionary).duplicate(true)
		scenario["id"] = String(scenario_id)
		scenario["seed"] = seed_value
		result.append(scenario)
	return result


static func replay_scenario_seed(scenario_id: StringName) -> int:
	if scenario_id == &"baseline_book":
		return 1701
	for seed_value in AUTHORED_SCENARIO_SEEDS:
		if SCENARIO_SEED_IDS[seed_value] == scenario_id:
			return seed_value
	return 1701


func rival_coop_snapshot(probation_score: int, completed_shifts: int) -> Dictionary:
	var scenario := scenario_identity_snapshot()
	var rival_name := String(scenario.get("rival_name", "Golden Comb Group"))
	var benchmark := clampi(47 + completed_shifts * 6 + posmod(_career_seed, 4), 47, 82)
	var difference := probation_score - benchmark
	return {
		"name": rival_name,
		"benchmark": benchmark,
		"player_score": probation_score,
		"difference": difference,
		"standing": &"ahead" if difference >= 0 else &"behind",
		"short_label": "%+d VS %s" % [difference, rival_name.to_upper()],
		"rule": String(scenario.get("rival_rule", "Beat the outside benchmark without abandoning the filed plan.")),
	}


func _apply_scenario_opening_structure() -> void:
	# These are visible starting conditions, not hidden difficulty multipliers.
	# Baseline/legacy dockets remain byte-for-byte neutral.
	match StringName(scenario_identity_snapshot().get("id", &"baseline_book")):
		&"harvest_surge":
			_enqueue_new_claim(&"nest_damage")
			_enqueue_new_claim(&"predator_loss")
			quota_target += 1
		&"shell_audit":
			_enqueue_new_claim(&"appeals")
			_enqueue_new_claim(&"appeals")
			# The inspector explicitly trades one egg of volume for verified service;
			# the extra appeals remain real work without silently invalidating the
			# long-career assurance route.
			quota_target = maxi(1, quota_target - 1)
			compliance = minf(100.0, compliance + 4.0)
			_incident_crack_modifier += 0.01
		&"flock_walkout":
			if not workers.is_empty():
				workers[0].morale = maxf(0.0, workers[0].morale - 8.0)
				workers[0].manager_trust = maxf(0.0, workers[0].manager_trust - 10.0)
				workers[0].grievance = minf(100.0, workers[0].grievance + 18.0)
			solidarity = minf(100.0, solidarity + 12.0)
			# Organized hens cross-check one another's baskets even while the manager
			# relationship is strained. This keeps the scenario's pressure on trust
			# rather than turning it into an unrelated shell-quality trap.
			_incident_crack_modifier -= 0.024
		&"thin_margin":
			revenue_cents = maxi(0, revenue_cents - 800)
			quota_target += 1
			_adjust_workers(-2.0, 2.0, 1.0)
		&"fox_season":
			_enqueue_new_claim(&"predator_loss")
			_enqueue_new_claim(&"predator_loss")
			_adjust_workers(-4.0, 5.0, 3.0)
			_incident_crack_modifier += 0.008
		&"credit_scramble":
			_enqueue_new_claim(&"nest_damage")
			_enqueue_new_claim(&"nest_damage")
			executive_confidence = maxf(0.0, executive_confidence - 6.0)


func final_hearing_snapshot() -> Dictionary:
	var record := _latest_incident_response(FINAL_HEARING_INCIDENT_ID, incident_response_history)
	if record.is_empty():
		var scenario_id := StringName(scenario_identity_snapshot().get("id", &"baseline_book"))
		return {
			"resolved": false,
			"required": day == PROBATION_CAMPAIGN_SHIFTS and scenario_id != &"baseline_book",
			"scenario": scenario_identity_snapshot(),
			"legacy_evidence": _campaign_legacy_evidence_snapshot(),
		}
	var response := _incident_response_snapshot(record)
	response["resolved"] = true
	response["required"] = false
	response["scenario"] = scenario_identity_snapshot()
	response["legacy_evidence"] = _campaign_legacy_evidence_snapshot()
	response["charter_label"] = String(response.get("option_label", "PERMANENT RECORD"))
	return response


func _final_hearing_definition() -> Dictionary:
	var definition := (INCIDENT_DEFINITIONS[FINAL_HEARING_INCIDENT_ID] as Dictionary).duplicate(true)
	var scenario := scenario_identity_snapshot()
	var legacy := _campaign_legacy_evidence_snapshot()
	definition["title"] = String(scenario.get("climax_title", definition.get("title", "FINAL HEARING")))
	definition["body"] = "%s\n\nPERMANENT EVIDENCE  ·  %s" % [
		String(scenario.get("climax_body", definition.get("body", "The permanent record needs a signature."))),
		String(legacy.get("summary", "The flock arrives with a visible record.")),
	]
	definition["legacy_evidence"] = legacy
	return definition


func _apply_scenario_directive_modifier(directive_id: StringName) -> void:
	if _career_seed not in AUTHORED_SCENARIO_SEEDS:
		return
	if day > PROBATION_CAMPAIGN_SHIFTS:
		# The operating lesson learned during a replay scenario becomes its Senior
		# aftereffect. It is materially smaller than the opening fit bonus, but strong
		# enough that a shuffled incident order cannot erase one required service day.
		# Replay scenarios carry two additional opening obligations into the long
		# career. The learned operating cadence must cover one service day without
		# erasing the Board Book's shell, welfare, or compliance tests.
		_directive_work_multiplier *= 1.12
		var senior_scenario := StringName(scenario_identity_snapshot().get("id", &""))
		match senior_scenario:
			&"shell_audit":
				_directive_crack_modifier -= 0.012
				compliance = minf(100.0, compliance + 1.0)
				_adjust_workers(0.75, -0.75, -0.75)
			&"flock_walkout":
				_directive_crack_modifier -= 0.008
				_adjust_workers(1.0, -1.0, -1.0)
			&"harvest_surge":
				_directive_crack_modifier -= 0.006
				_adjust_workers(0.75, -0.50, -0.75)
			&"thin_margin":
				# A cash-starved docket should test solvency, not randomly erase the
				# assurance route's earned Senior shell-control identity.
				_directive_crack_modifier -= 0.012
				_adjust_workers(1.0, -1.0, -1.0)
			&"fox_season":
				_directive_crack_modifier -= 0.010
				_adjust_workers(0.75, -1.25, -1.0)
			&"credit_scramble":
				executive_confidence = minf(100.0, executive_confidence + 1.0)
		return
	# Authored scenario runs begin prepared rather than arbitrarily punished.
	# Reading the docket grants a small shell-control credit; matching its named
	# policy earns a larger, visible specialization with a retained tradeoff.
	_directive_crack_modifier -= 0.012
	var scenario := scenario_identity_snapshot()
	if StringName(scenario.get("id", &"")) == &"harvest_surge":
		_directive_work_multiplier *= 1.04
	if StringName(scenario.get("favored_directive", &"")) != directive_id:
		return
	match StringName(scenario.get("id", &"")):
		&"harvest_surge":
			_directive_work_multiplier *= 1.12
			executive_confidence = minf(100.0, executive_confidence + 12.0)
			_pending_quota_adjustment += 1
		&"shell_audit":
			_directive_crack_modifier -= 0.035
			compliance = minf(100.0, compliance + 4.0)
		&"flock_walkout":
			_directive_crack_modifier -= 0.018
			_adjust_workers(3.0, -3.0, -2.0)
			_adjust_worker_relationships(3.0, -3.0)
			executive_confidence = minf(100.0, executive_confidence + 3.0)
		&"thin_margin":
			_directive_work_multiplier *= 1.05
			_adjust_workers(4.0, -4.0, -3.0)
		&"fox_season":
			_directive_crack_modifier -= 0.030
			compliance = minf(100.0, compliance + 3.0)
			_adjust_workers(2.0, -4.0, -3.0)
		&"credit_scramble":
			_directive_work_multiplier *= 1.10
			executive_confidence = minf(100.0, executive_confidence + 8.0)


func _relationship_arc_stage(trust: float, grievance: float, prior_beats: int) -> Dictionary:
	if grievance >= 70.0 or trust <= 25.0:
		return {
			"standing": &"breaking",
			"standing_label": "BREAKING POINT",
			"request": "A protective response may keep this hen in the flock.",
		}
	if trust >= 70.0 and grievance <= 30.0:
		return {
			"standing": &"ally",
			"standing_label": "TRUSTED ALLY",
			"request": "This hen trusts you to remember who carried the file.",
		}
	if prior_beats > 0:
		return {
			"standing": &"remembering",
			"standing_label": "REMEMBERS",
			"request": "This response will confirm or reverse your earlier pattern.",
		}
	return {
		"standing": &"forming",
		"standing_label": "FORMING AN OPINION",
		"request": "This is the hen's first direct impression of your management.",
	}


func incident_character_arc_snapshot(incident_id: StringName) -> Dictionary:
	var pair_id := StringName(INCIDENT_PAIR_IDS.get(incident_id, &""))
	var final_hearing := incident_id == FINAL_HEARING_INCIDENT_ID
	if (pair_id == &"" and not final_hearing) or workers.is_empty():
		return {}
	var employed_workers: Array[ChickenState] = []
	for worker in workers:
		if worker.employed:
			employed_workers.append(worker)
	if employed_workers.is_empty():
		return {}
	# A connected pair always belongs to the same witness. The assignment is
	# deterministic, survives save/load without another schema field, and turns
	# the follow-through case into a relationship callback instead of trivia.
	var pair_index := maxi(0, INCIDENT_PAIR_ORDER.find(pair_id))
	if final_hearing:
		var scenario_ids: Array[StringName] = [
			&"harvest_surge", &"shell_audit", &"flock_walkout",
			&"thin_margin", &"fox_season", &"credit_scramble",
		]
		pair_index = maxi(0, scenario_ids.find(StringName(scenario_identity_snapshot().get("id", &""))))
	var witness := employed_workers[pair_index % employed_workers.size()]
	var prior_beats := 0
	for record in incident_response_history:
		var prior_incident := StringName(record.get("incident_id", &""))
		if (
			(final_hearing and prior_incident == FINAL_HEARING_INCIDENT_ID)
			or (not final_hearing and StringName(INCIDENT_PAIR_IDS.get(prior_incident, &"")) == pair_id)
		):
			prior_beats += 1
	var definition := INCIDENT_DEFINITIONS.get(incident_id, {}) as Dictionary
	var speaker_id := StringName(witness.display_name.to_lower().replace(" ", "_"))
	var stage := _relationship_arc_stage(witness.manager_trust, witness.grievance, prior_beats)
	return {
		"pair_id": &"permanent_record" if final_hearing else pair_id,
		"worker_id": witness.id,
		"worker_name": witness.display_name,
		"speaker_id": speaker_id,
		"beat": prior_beats + 1,
		"beat_label": "CALLBACK %d" % prior_beats if prior_beats > 0 else "FIRST IMPRESSION",
		"witness_prompt": String(definition.get("witness_prompt", "is named in this file")),
		"trust_before": witness.manager_trust,
		"grievance_before": witness.grievance,
		"standing": stage["standing"],
		"standing_label": stage["standing_label"],
		"request": stage["request"],
	}


func _maybe_open_incident() -> bool:
	if _incident_slot >= INCIDENT_MINUTES.size():
		return false
	if minute_of_day < INCIDENT_MINUTES[_incident_slot]:
		return false
	_decision_serial += 1
	var petition_decision: Dictionary = {}
	var is_petition_slot := (
		day in FLOCK_PETITION_DAYS and _incident_slot == FLOCK_PETITION_INCIDENT_SLOT
	)
	if is_petition_slot:
		petition_decision = _build_flock_petition_decision()
	if not petition_decision.is_empty():
		petition_decision["serial"] = _decision_serial
		pending_decision = petition_decision
	else:
		var incident_id: StringName
		var scenario_id := StringName(scenario_identity_snapshot().get("id", &"baseline_book"))
		var is_final_hearing: bool = (
			day == PROBATION_CAMPAIGN_SHIFTS
			and _incident_slot == INCIDENT_MINUTES.size() - 1
			and scenario_id != &"baseline_book"
			and not bool(final_hearing_snapshot().get("resolved", false))
		)
		if is_final_hearing:
			incident_id = FINAL_HEARING_INCIDENT_ID
		elif _career_seed == 1701 or is_petition_slot:
			# PO-1701 is the shipped balance baseline and the destination for legacy
			# saves. A petition slot with no eligible sponsor also retains its authored
			# structural fallback. New ordinary docket slots use the shuffled bag.
			var rotation_index := (
				(day - 1) * INCIDENT_MINUTES.size() + _incident_slot
			) % LEGACY_INCIDENT_ORDER.size()
			incident_id = LEGACY_INCIDENT_ORDER[rotation_index]
			_last_standard_incident_id = incident_id
		else:
			incident_id = _next_standard_incident_id()
		var definition: Dictionary = (
			_final_hearing_definition()
			if incident_id == FINAL_HEARING_INCIDENT_ID else
			INCIDENT_DEFINITIONS[incident_id]
		)
		var options: Array[Dictionary] = []
		for choice in _incident_choices(incident_id):
			options.append(choice.duplicate(true))
		var case_memory := incident_follow_through_snapshot(incident_id)
		var character_arc := incident_character_arc_snapshot(incident_id)
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
		if incident_id == FINAL_HEARING_INCIDENT_ID:
			pending_decision["eyebrow"] = "FINAL HEARING  /  PERMANENT CHOICE  /  AUTO-PAUSED  /  %s" % _format_time(minute_of_day)
			pending_decision["scenario"] = scenario_identity_snapshot()
			pending_decision["legacy_evidence"] = _campaign_legacy_evidence_snapshot()
		if not case_memory.is_empty():
			pending_decision["case_memory"] = case_memory.duplicate(true)
		if not character_arc.is_empty():
			pending_decision["character_arc"] = character_arc.duplicate(true)
			pending_decision["eyebrow"] = (
				"FINAL HEARING  /  %s WITNESSES  /  PERMANENT CHOICE  /  %s" % [
					String(character_arc.get("worker_name", "FLOCK")).to_upper(),
					_format_time(minute_of_day),
				]
				if incident_id == FINAL_HEARING_INCIDENT_ID else
				"INCIDENT  /  %s'S FILE  /  AUTO-PAUSED  /  %s" % [
					String(character_arc.get("worker_name", "FLOCK")).to_upper(),
					_format_time(minute_of_day),
				]
			)
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
	var cost_cents := (
		maxi(0, int(chosen.get("cost_cents", 0)))
		if is_flock_petition else
		_incident_option_cost_cents(incident_id, option_id)
	)
	var case_memory := pending_decision.get("case_memory", {}) as Dictionary
	var character_arc := pending_decision.get("character_arc", {}) as Dictionary
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
	var case_pivot: Dictionary = {}
	if is_flock_petition:
		petition_record = _apply_flock_petition_response(option_id, chosen)
	else:
		_apply_incident_effects(incident_id, option_id, case_memory)
		# The named witness carries a personal cost or protection on every docket,
		# including the PO-1701 baseline: the choice card names her before filing,
		# so the consequence must be real wherever the card makes that claim.
		_apply_incident_character_consequence(character_arc, StringName(chosen.get("tone", &"")))
	incidents_resolved_today += 1
	var outcome := String(chosen.get("outcome", "Incident response recorded."))
	var serial := int(pending_decision.get("serial", -1))
	var incident_response: Dictionary = {}
	if not is_flock_petition:
		incident_response = _record_standard_incident_response(incident_id, option_id, day, serial)
		case_pivot = incident_response.get("case_pivot", {}) as Dictionary
	var filed_precedent: Dictionary = {}
	if not is_flock_petition:
		filed_precedent = active_incident_precedent_snapshot()
	var resolution_summary := outcome
	if not filed_precedent.is_empty():
		resolution_summary = "%s PRECEDENT FILED / %s / %s" % [
			outcome,
			String(filed_precedent.get("target_label", "NEXT RELATED CASE")),
			String(filed_precedent.get("summary", "A prior response changes the next related case.")),
		]
	if not case_pivot.is_empty():
		var pivot_mastery := incident_pivot_mastery_snapshot()
		resolution_summary += " ADAPTIVE CASEWORK / %d OF %d PAIRS%s" % [
			int(pivot_mastery.get("mastered_count", 0)),
			int(pivot_mastery.get("total_count", INCIDENT_PAIR_ORDER.size())),
			" / COMMENDATION READY" if bool(pivot_mastery.get("complete", false)) else "",
		]
	pending_decision.clear()
	shift_phase = ShiftPhase.RUNNING
	shift_phase_changed.emit(shift_phase)
	announcement_posted.emit(resolution_summary)
	var result := {
		"serial": serial,
		"kind": &"incident",
		"decision_id": incident_id,
		"option_id": option_id,
		"outcome": outcome,
		"resolution_summary": resolution_summary,
		"day": day,
	}
	if is_flock_petition:
		result["category"] = FLOCK_PETITION_CATEGORY
		result["flock_petition"] = petition_record.duplicate(true)
		result["flock_compact"] = active_flock_compact.duplicate(true)
		result["work_to_rule"] = work_to_rule_snapshot()
	else:
		result["incident_response"] = incident_response.duplicate(true)
		result["case_memory"] = case_memory.duplicate(true)
		if not character_arc.is_empty():
			character_arc["option_label"] = String(chosen.get("short_label", chosen.get("label", "RESPONSE")))
			character_arc["tone"] = StringName(chosen.get("tone", &""))
			var worker_id := int(character_arc.get("worker_id", -1))
			for witness in workers:
				if witness.id == worker_id:
					character_arc["trust_after"] = witness.manager_trust
					character_arc["grievance_after"] = witness.grievance
					var stage_after := _relationship_arc_stage(
						witness.manager_trust,
						witness.grievance,
						int(character_arc.get("beat", 1)),
					)
					character_arc["standing_after"] = stage_after["standing"]
					character_arc["standing_label_after"] = stage_after["standing_label"]
					break
			result["character_arc"] = character_arc.duplicate(true)
		if not case_pivot.is_empty():
			result["case_pivot"] = case_pivot.duplicate(true)
			result["case_pivot_mastery"] = incident_pivot_mastery_snapshot()
		if not filed_precedent.is_empty():
			result["filed_precedent"] = filed_precedent.duplicate(true)
	decision_resolved.emit(result)
	snapshot_changed.emit(snapshot())
	return true


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
				workers[sponsor_id].manually_routed = false
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


func _apply_incident_effects(
	incident_id: StringName,
	option_id: StringName,
	follow_through: Dictionary = {},
) -> void:
	var follow_through_id := StringName(follow_through.get("id", &""))
	var choice := _incident_choice_definition(incident_id, option_id)
	var effect_bundle := choice.get("effects", {}) as Dictionary
	if not effect_bundle.is_empty():
		_apply_incident_effect_bundle(effect_bundle)
		if incident_id == FINAL_HEARING_INCIDENT_ID:
			var favored_option := StringName(scenario_identity_snapshot().get("favored_finale_option", &""))
			if option_id == favored_option:
				# A scenario-fit signature rewards reading the whole run without
				# turning any one charter into a universal best answer.
				match option_id:
					&"back_farmer":
						executive_confidence = minf(100.0, executive_confidence + 2.0)
						_incident_work_multiplier *= 1.02
					&"sign_flock_charter":
						_adjust_worker_relationships(2.0, -2.0)
						solidarity = minf(100.0, solidarity + 2.0)
					&"publish_ledger":
						compliance = minf(100.0, compliance + 2.0)
						_incident_crack_modifier -= 0.01
		# Connected-case pivots are small but tangible: they alter the option the
		# filed precedent named without introducing a second hidden ruleset.
		match follow_through_id:
			&"staged_audit_to_variance", &"variance_to_staged_audit", &"tracking_to_desktop", &"desktop_to_tracking", &"success_to_deck", &"deck_to_success":
				_adjust_worker_relationships(1.0, -1.0)
			&"cold_room_to_cooling", &"cooling_to_open_audit", &"privacy_to_evacuate", &"evacuation_to_privacy", &"claimant_to_flock", &"flock_to_claimant":
				_incident_work_multiplier *= 1.02
		return
	match incident_id:
		&"ledger_molt":
			if option_id == &"patch":
				compliance = minf(100.0, compliance + 4.0)
				_incident_crack_modifier -= 0.04
				_adjust_worker_relationships(1.0, -1.0)
			else:
				_incident_work_multiplier *= (
					1.07 if follow_through_id == &"transparency_to_shadow_sheet" else 1.05
				)
				_incident_crack_modifier += (
					float(ledger_molt_spreadsheet_crack_basis_points()) / 10_000.0
				)
				compliance = maxf(
					0.0,
					compliance
					- float(ledger_molt_spreadsheet_compliance_loss_millipoints()) / 1000.0,
				)
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
				executive_confidence = minf(
					100.0,
					executive_confidence
					+ (5.0 if follow_through_id == &"fed_flock_to_denial" else 3.0),
				)
				solidarity = minf(100.0, solidarity + 5.0)
				_incident_crack_modifier += 0.025
		&"farmer_story":
			if option_id == &"polish_story":
				_adjust_worker_relationships(-4.0, 5.0)
				var story_credit_cents := (
					2000 if follow_through_id == &"clean_audit_to_story" else 1600
				)
				revenue_cents += story_credit_cents
				credited_today_cents += story_credit_cents
				executive_confidence = minf(100.0, executive_confidence + 8.0)
				solidarity = maxf(0.0, solidarity - 5.0)
				_pending_quota_adjustment += 1
			else:
				_adjust_worker_relationships(4.0, -3.0)
				executive_confidence = maxf(
					0.0,
					executive_confidence
					- (4.0 if follow_through_id == &"shadow_evidence_to_ledger" else 6.0),
				)
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
				_incident_feed_adjustment_cents -= (
					1000 if follow_through_id == &"rested_flock_to_portions" else 800
				)
				_consume_feed_for_shift()
				_adjust_workers(-7.0, 5.0, 0.0)
				_adjust_worker_relationships(-3.0, 4.0)
				_incident_work_multiplier *= 0.96
				_incident_crack_modifier += 0.03
		&"calendar_overflow":
			if option_id == &"cancel_status_sync":
				_incident_work_multiplier *= 1.06
				_incident_crack_modifier -= 0.02
				compliance = minf(100.0, compliance + 2.0)
				executive_confidence = maxf(0.0, executive_confidence - 2.0)
				_adjust_worker_relationships(2.0, -2.0)
			else:
				_incident_work_multiplier *= 0.93
				executive_confidence = minf(100.0, executive_confidence + 8.0)
				compliance = minf(100.0, compliance + 2.0)
				_adjust_workers(0.0, 4.0, 0.0)
				_adjust_worker_relationships(-2.0, 3.0)
		&"credit_town_hall":
			if option_id == &"credit_layers":
				executive_confidence = maxf(0.0, executive_confidence - 2.0)
				compliance = minf(100.0, compliance + 4.0)
				_adjust_workers(8.0, -6.0, -4.0)
				_adjust_worker_relationships(6.0, -5.0)
				solidarity = minf(100.0, solidarity + 5.0)
				_pending_quota_adjustment -= 1
				_incident_crack_modifier -= 0.01
				_incident_golden_modifier += 0.02
			else:
				executive_confidence = minf(100.0, executive_confidence + 10.0)
				_incident_work_multiplier *= 1.05
				_adjust_workers(-5.0, 4.0, 0.0)
				_adjust_worker_relationships(-5.0, 6.0)
				solidarity = maxf(0.0, solidarity - 4.0)
	match follow_through_id:
		&"manager_byline_to_cancel":
			if incident_id == &"calendar_overflow" and option_id == &"cancel_status_sync":
				_adjust_worker_relationships(2.0, 0.0)
		&"layer_results_to_syncs":
			if incident_id == &"calendar_overflow" and option_id == &"attend_status_sync":
				executive_confidence = minf(100.0, executive_confidence + 2.0)
		&"cancel_bargain_to_roosters":
			if incident_id == &"credit_town_hall" and option_id == &"credit_roosters":
				executive_confidence = minf(100.0, executive_confidence + 2.0)


func _apply_incident_effect_bundle(effects: Dictionary) -> void:
	_incident_work_multiplier *= maxf(0.1, float(effects.get("work_multiplier", 1.0)))
	_incident_strain_multiplier *= maxf(0.1, float(effects.get("strain_multiplier", 1.0)))
	_incident_crack_modifier += float(effects.get("crack_modifier", 0.0))
	_incident_golden_modifier += float(effects.get("golden_modifier", 0.0))
	revenue_cents += int(effects.get("revenue_delta_cents", 0))
	credited_today_cents += int(effects.get("credited_delta_cents", 0))
	compliance = clampf(compliance + float(effects.get("compliance_delta", 0.0)), 0.0, 100.0)
	executive_confidence = clampf(
		executive_confidence + float(effects.get("executive_delta", 0.0)), 0.0, 100.0
	)
	solidarity = clampf(solidarity + float(effects.get("solidarity_delta", 0.0)), 0.0, 100.0)
	_pending_quota_adjustment += int(effects.get("quota_delta", 0))
	_adjust_workers(
		float(effects.get("morale_delta", 0.0)),
		float(effects.get("stress_delta", 0.0)),
		float(effects.get("fatigue_delta", 0.0)),
	)
	_adjust_worker_relationships(
		float(effects.get("trust_delta", 0.0)),
		float(effects.get("grievance_delta", 0.0)),
	)


func _apply_incident_character_consequence(character_arc: Dictionary, tone: StringName) -> void:
	var worker_id := int(character_arc.get("worker_id", -1))
	for worker in workers:
		if worker.id != worker_id or not worker.employed:
			continue
		# The named witness carries the personal cost or protection of the
		# response: a company-side answer is paid for by this hen, a flock-side
		# answer is covered for her. The choice card names her before filing.
		match ComplicityLedgerScript.incident_side(tone):
			ComplicityLedgerScript.SIDE_COMPANY:
				worker.manager_trust = clampf(worker.manager_trust - 6.0, 0.0, 100.0)
				worker.grievance = clampf(worker.grievance + 6.0, 0.0, 100.0)
				worker.stress = clampf(worker.stress + 6.0, 0.0, 100.0)
				worker.morale = clampf(worker.morale - 4.0, 0.0, 100.0)
			ComplicityLedgerScript.SIDE_FLOCK:
				worker.manager_trust = clampf(worker.manager_trust + 5.0, 0.0, 100.0)
				worker.grievance = clampf(worker.grievance - 4.0, 0.0, 100.0)
				worker.stress = clampf(worker.stress - 5.0, 0.0, 100.0)
				worker.morale = clampf(worker.morale + 3.0, 0.0, 100.0)
			_:
				worker.manager_trust = clampf(worker.manager_trust + 3.0, 0.0, 100.0)
				worker.grievance = clampf(worker.grievance - 2.0, 0.0, 100.0)
		return


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
	flock_relationships.begin_day(day)
	active_directive_id = &""
	pending_decision.clear()
	incidents_resolved_today = 0
	peck_assists_used_today = 0
	peck_assist_interventions_today = 0
	peck_assist_refunds_today = 0
	routing_momentum_peck_recharges_used_today = 0
	peck_assist_streak = 0
	last_peck_assist.clear()
	last_peck_assist_delivery.clear()
	flock_relations_resolutions_used_today = 0
	priority_credit_today_cents = 0
	_assisted_claim_ids.clear()
	_missed_assist_claim_ids.clear()
	_assist_quality_modifiers.clear()
	_assist_chain_by_claim_id.clear()
	_pending_peck_assist_deliveries.clear()
	_settled_peck_assist_delivery_ids.clear()
	_routing_momentum_free_assist_claim_ids.clear()
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
	_reset_active_playbook()


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
	if (
		not CLAIM_LANE_DEFINITIONS.has(lane)
		or _outstanding_claim_count() + _pending_market_contract_claim_count()
		>= current_claim_capacity()
	):
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


func _offer_new_claim(lane: StringName) -> bool:
	## Intake demand exists independently of archive space. A full bureau records
	## the opportunity it turned away, but never credits the Feed Fund for work the
	## flock did not accept and complete.
	if not CLAIM_LANE_DEFINITIONS.has(lane):
		return false
	if (
		_outstanding_claim_count() + _pending_market_contract_claim_count()
		>= current_claim_capacity()
	):
		_record_rejected_intake(lane)
		return false
	return _enqueue_new_claim(lane)


func _record_rejected_intake(lane: StringName) -> void:
	var definition := CLAIM_LANE_DEFINITIONS.get(lane, {}) as Dictionary
	if definition.is_empty():
		return
	var estimated_value_cents := maxi(0, int(definition.get("base_value_cents", 0)))
	intake_rejections_today += 1
	intake_rejections_total += 1
	intake_missed_value_today_cents += estimated_value_cents
	intake_missed_value_total_cents += estimated_value_cents
	if intake_rejections_today == 1 or intake_rejections_today % 3 == 0:
		announcement_posted.emit(
			"INTAKE ROOST FULL: %s left with an estimated $%.2f file. %d turned away today." % [
				String(definition.get("display_name", "CLAIM")),
				float(estimated_value_cents) / 100.0,
				intake_rejections_today,
			]
		)


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
	var automation_policy := (
		worker.automation_policy_id
		if worker.automation_policy_unlocked else
		&"specialty_first"
	)
	if automation_policy == &"deadline_first":
		return _remove_claim_at(urgent_lane, urgent_index)
	var trained_lanes: Array[StringName] = [worker.specialty]
	if (
		automation_recognizes_secondary_specialties()
		and worker.has_secondary_specialty()
		and worker.secondary_specialty not in trained_lanes
	):
		trained_lanes.append(worker.secondary_specialty)
	var trained_lane: StringName = &""
	var trained_index := -1
	var trained_claim: ClaimState
	for lane in trained_lanes:
		var candidate_index := _earliest_claim_index(lane)
		var candidate := _claim_at(lane, candidate_index)
		if candidate == null:
			continue
		if (
			trained_claim == null
			or candidate.deadline_operational_minute < trained_claim.deadline_operational_minute
			or (
				candidate.deadline_operational_minute == trained_claim.deadline_operational_minute
				and candidate.id < trained_claim.id
			)
		):
			trained_lane = lane
			trained_index = candidate_index
			trained_claim = candidate
	var specialty_grace_minutes := automation_specialty_grace_minutes()
	if automation_policy == &"protect_strain" and worker.stress >= 55.0:
		specialty_grace_minutes = 30
	if (
		trained_claim != null
		and trained_claim.deadline_operational_minute
			<= urgent_claim.deadline_operational_minute + specialty_grace_minutes
	):
		return _remove_claim_at(trained_lane, trained_index)
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


func _claim_resolution_work_multiplier(claim: ClaimState) -> float:
	if claim == null:
		return 1.0
	var definition := (
		CLAIM_RESOLUTION_DEFINITIONS.get(claim.resolution_path, {}) as Dictionary
	)
	return float(definition.get("work_basis_points", 10_000)) / 10_000.0


func _claim_resolution_crack_modifier(claim: ClaimState) -> float:
	if claim == null:
		return 0.0
	var definition := (
		CLAIM_RESOLUTION_DEFINITIONS.get(claim.resolution_path, {}) as Dictionary
	)
	return float(definition.get("crack_basis_points", 0)) / 10_000.0


func _claim_lane_stress_multiplier(claim: ClaimState) -> float:
	if claim == null or not claim.resolution_locked:
		return 1.0
	var definition := CLAIM_LANE_DEFINITIONS.get(claim.lane, {}) as Dictionary
	return float(definition.get("work_stress_basis_points", 10_000)) / 10_000.0


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
		source_claim.rework_depth + 1,
		source_claim.claimant_profile_id,
		&"standard",
		false,
		0,
		source_claim.is_claimant_follow_up,
	)
	_next_claim_id += 1
	_pending_rework.append(rework)
	_rework_total_created += 1


func _schedule_claimant_appeal(source_claim: ClaimState) -> void:
	if source_claim == null:
		return
	var definition := CLAIM_LANE_DEFINITIONS[&"appeals"] as Dictionary
	var claimant := source_claim.claimant_profile()
	var available_on_day := day + 1
	var arrival_minute := _operational_minute_for_shift_start(available_on_day)
	var service_window := int(definition.get("deadline_minutes", 360))
	var appeal := ClaimState.new(
		_next_claim_id,
		&"appeals",
		"CLAIMANT APPEAL  /  %s" % String(
			claimant.get("name", "UNFILED CLAIMANT"),
		),
		float(definition.get("base_difficulty", 1.3)) * 1.08,
		int(definition.get("base_value_cents", 820)),
		float(definition.get("crack_modifier", 0.055)) + 0.015,
		arrival_minute,
		arrival_minute + service_window,
		service_window,
		false,
		source_claim.id,
		available_on_day,
		source_claim.rework_depth + 1,
		source_claim.claimant_profile_id,
		&"standard",
		false,
		0,
		true,
	)
	_next_claim_id += 1
	_pending_rework.append(appeal)
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
			_apply_market_contract_claim_snapshot(claim_snapshot)
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


## Monotonic authoritative revision used to decide whether two lifecycle
## checkpoint requests can safely share the same committed snapshot.
func checkpoint_revision() -> int:
	return _tick_count


func advance_tick(publish_snapshot: bool = true) -> void:
	if shift_phase != ShiftPhase.RUNNING:
		return
	var probe_started := cost_probe.begin()
	_tick_count += 1
	minute_of_day += MINUTES_PER_TICK

	_release_due_rework()
	_release_due_market_contract_claims()
	if _tick_count % 3 == 0:
		_offer_new_claim(_choose_arrival_lane())

	cost_probe.finish(&"tick_arrivals", probe_started)
	probe_started = cost_probe.begin()
	for worker in workers:
		if not worker.employed:
			continue
		_update_worker(worker)

	cost_probe.finish(&"tick_workers", probe_started)
	probe_started = cost_probe.begin()
	if _maybe_open_incident():
		cost_probe.finish(&"tick_close", probe_started)
		if publish_snapshot:
			snapshot_changed.emit(snapshot())
		return

	if minute_of_day >= SHIFT_END_MINUTE:
		_complete_workday()

	if publish_snapshot:
		snapshot_changed.emit(snapshot())

	cost_probe.finish(&"tick_close", probe_started)


## Publishes one complete read model after a SimulationClock batch. Direct
## management transactions and direct advance_tick() calls retain their
## immediate snapshot contract; only clock-serviced accelerated ticks coalesce.
func publish_current_snapshot() -> void:
	# The clock's sole consumer treats the emitted read model as immutable and
	# immediately derives its own bounded presentation subsets. Reuse the frozen
	# nested projection bundle here instead of deep-copying the entire campus,
	# facility, staffing, and contract graph on every accelerated tick.
	snapshot_changed.emit(snapshot(true, true))


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


func begin_first_clutch_reinvestment(
	worker_id: int,
	claim_id: int,
	quality: StringName,
	created_value_cents: int
) -> Dictionary:
	## The Office calls this only after the exact physical egg reaches the farmer.
	## The egg value is already in authoritative revenue; this method stages a
	## purchase-only procurement match and never mints cash.
	var normalized_quality := StringName(String(quality))
	if not first_clutch_reinvestment.is_empty():
		var existing := first_clutch_reinvestment_status()
		var same_trigger := (
			worker_id == int(existing.get("trigger_worker_id", -1))
			and claim_id == int(existing.get("trigger_claim_id", -1))
			and normalized_quality == StringName(existing.get("trigger_quality", &""))
			and created_value_cents == int(existing.get("created_value_cents", -1))
		)
		existing.merge({
			"accepted": same_trigger,
			"created": false,
			"idempotent": same_trigger,
			"reason": (
				"This exact First Clutch collection already has a durable reinvestment record."
				if same_trigger else
				"A different First Clutch collection is already on the durable procurement ledger."
			),
		}, true)
		return existing
	if worker_id != FIRST_CLUTCH_WORKER_ID:
		return _rejected_first_clutch_reinvestment(
			"First Clutch reinvestment is reserved for Mabel's induction file.",
		)
	if claim_id < 1:
		return _rejected_first_clutch_reinvestment(
			"A valid collected egg receipt is required before reinvestment can open.",
		)
	if normalized_quality not in [&"sound", &"golden", &"cracked"]:
		return _rejected_first_clutch_reinvestment(
			"The collected egg must carry a valid shell grade.",
		)
	if created_value_cents < 1 or created_value_cents > 2_000_000_000:
		return _rejected_first_clutch_reinvestment(
			"The collected egg must carry a positive integer-cent value.",
		)
	if (
		worker_id >= workers.size()
		or not workers[worker_id].employed
		or workers[worker_id].eggs_laid < 1
		or eggs_total < 1
	):
		return _rejected_first_clutch_reinvestment(
			"Mabel's authoritative production ledger does not contain a completed egg.",
		)

	var offered_options: Array[Dictionary] = []
	var highest_list_cost := 0
	for upgrade_id in UPGRADE_ORDER:
		if offered_options.size() >= FIRST_CLUTCH_REINVESTMENT_OFFER_LIMIT:
			break
		var level_before := upgrade_level(upgrade_id)
		if level_before >= MAX_UPGRADE_LEVEL:
			continue
		var list_cost := _upgrade_list_cost_for_level(upgrade_id, level_before)
		offered_options.append({
			"id": String(upgrade_id),
			"level_before": level_before,
			"next_level": level_before + 1,
			"list_cost_cents": list_cost,
		})
		highest_list_cost = maxi(highest_list_cost, list_cost)
	var protected_reserve := protected_reserve_cents()
	var spendable_at_collection := spendable_fund_cents()
	var procurement_match := mini(
		ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS,
		maxi(0, highest_list_cost - spendable_at_collection),
	)
	first_clutch_reinvestment = {
		"version": FIRST_CLUTCH_REINVESTMENT_VERSION,
		"status": "offered",
		"trigger_day": day,
		"trigger_worker_id": worker_id,
		"trigger_worker_name": workers[worker_id].display_name,
		"trigger_claim_id": claim_id,
		"trigger_quality": String(normalized_quality),
		"created_value_cents": created_value_cents,
		"fund_at_collection_cents": revenue_cents,
		"protected_reserve_cents": protected_reserve,
		"spendable_at_collection_cents": spendable_at_collection,
		"procurement_match_available_cents": procurement_match,
		"offered_options": offered_options,
		"choice_id": "",
		"resolved_day": 0,
		"selected_level": 0,
		"selected_list_cost_cents": 0,
		"procurement_match_used_cents": 0,
		"net_cost_cents": 0,
		"fund_before_resolution_cents": 0,
		"spendable_before_resolution_cents": 0,
		"fund_after_cents": revenue_cents,
		"spendable_after_cents": spendable_at_collection,
	}
	announcement_posted.emit(
		"FIRST CLUTCH REINVESTMENT: Mabel created $%.2f; procurement will match up to $%.2f against one visible requisition."
		% [created_value_cents / 100.0, procurement_match / 100.0]
	)
	var result := first_clutch_reinvestment_status()
	result.merge({
		"accepted": true,
		"created": true,
		"idempotent": false,
		"reason": "Mabel's collected egg opened one exact-once reinvestment choice.",
	}, true)
	snapshot_changed.emit(snapshot())
	return result


func first_clutch_reinvestment_status() -> Dictionary:
	if first_clutch_reinvestment.is_empty():
		return {
			"status": &"unavailable",
			"visible": false,
			"offered": false,
			"resolved": false,
			"purchased": false,
			"banked": false,
			"can_bank": false,
			"trigger_day": 0,
			"trigger_worker_id": -1,
			"trigger_worker_name": "",
			"trigger_claim_id": -1,
			"trigger_quality": &"",
			"created_value_cents": 0,
			"fund_at_collection_cents": 0,
			"protected_reserve_cents": protected_reserve_cents(),
			"spendable_at_collection_cents": 0,
			"current_fund_cents": revenue_cents,
			"current_spendable_fund_cents": spendable_fund_cents(),
			"procurement_match_available_cents": 0,
			"offered_options": [] as Array[Dictionary],
			"choice_id": &"",
			"resolved_day": 0,
			"selected_level": 0,
			"selected_list_cost_cents": 0,
			"procurement_match_used_cents": 0,
			"net_cost_cents": 0,
			"fund_after_cents": revenue_cents,
			"spendable_after_cents": spendable_fund_cents(),
			"reason": "Mabel's first collected egg has not opened reinvestment.",
		}
	var result := first_clutch_reinvestment.duplicate(true)
	var status := StringName(String(result.get("status", "offered")))
	var options: Array[Dictionary] = []
	for captured_value in first_clutch_reinvestment.get("offered_options", []):
		var captured := captured_value as Dictionary
		options.append(first_clutch_reinvestment_preflight(
			StringName(String(captured.get("id", ""))),
		))
	result["status"] = status
	result["visible"] = status == &"offered"
	result["offered"] = status == &"offered"
	result["resolved"] = status in [&"purchased", &"banked"]
	result["purchased"] = status == &"purchased"
	result["banked"] = status == &"banked"
	result["can_bank"] = status == &"offered"
	result["trigger_quality"] = StringName(String(result.get("trigger_quality", "")))
	result["choice_id"] = StringName(String(result.get("choice_id", "")))
	result["current_fund_cents"] = revenue_cents
	result["current_spendable_fund_cents"] = spendable_fund_cents()
	result["offered_options"] = options
	result["reason"] = (
		"Choose one visible requisition or Bank the Fund. The procurement match cannot be banked."
		if status == &"offered" else
		("First Clutch proceeds were banked; the procurement match expired."
		if status == &"banked" else
		"First Clutch reinvestment is installed and closed.")
	)
	return result


func first_clutch_reinvestment_preflight(upgrade_id: StringName) -> Dictionary:
	var status := StringName(String(first_clutch_reinvestment.get("status", "")))
	var captured: Dictionary = {}
	for option_value in first_clutch_reinvestment.get("offered_options", []):
		var option := option_value as Dictionary
		if StringName(String(option.get("id", ""))) == upgrade_id:
			captured = option
			break
	var definition := UPGRADE_DEFINITIONS.get(upgrade_id, {}) as Dictionary
	var list_cost := int(captured.get("list_cost_cents", 0))
	var match_available := int(first_clutch_reinvestment.get(
		"procurement_match_available_cents",
		0,
	))
	var match_cents := mini(match_available, list_cost)
	var net_cost := maxi(0, list_cost - match_cents)
	var spendable := spendable_fund_cents()
	var projected_spendable := _projected_spendable_after_obligation_change_cents(
		net_cost,
		0,
	)
	var terms_unchanged := (
		not captured.is_empty()
		and upgrade_level(upgrade_id) == int(captured.get("level_before", -1))
		and upgrade_cost_cents(upgrade_id) == list_cost
	)
	var reason := ""
	if first_clutch_reinvestment.is_empty():
		reason = "First Clutch reinvestment has not opened."
	elif status != &"offered":
		reason = "First Clutch reinvestment is already resolved."
	elif captured.is_empty():
		reason = "This requisition was not included in Mabel's exact offer."
	elif not terms_unchanged:
		reason = "The captured requisition level no longer matches its offer."
	elif projected_spendable < 0:
		reason = "$%.2f more spendable Feed Fund is required after the procurement match." % (
			float(-projected_spendable) / 100.0
		)
	return {
		"id": upgrade_id,
		"name": String(definition.get("name", "UNKNOWN REQUISITION")),
		"short_name": String(definition.get("short_name", "UNKNOWN")),
		"description": String(definition.get("description", "")),
		"level_before": int(captured.get("level_before", 0)),
		"next_level": int(captured.get("next_level", 0)),
		"list_cost_cents": list_cost,
		"procurement_match_cents": match_cents,
		"net_cost_cents": net_cost,
		"required_spendable_cents": net_cost,
		"spendable_fund_cents": spendable,
		"protected_reserve_cents": protected_reserve_cents(),
		"projected_spendable_fund_cents": projected_spendable,
		"affordable": projected_spendable >= 0,
		"can_purchase": status == &"offered" and terms_unchanged and projected_spendable >= 0,
		"reason": reason,
	}


func resolve_first_clutch_reinvestment(choice_id: StringName) -> Dictionary:
	var status := StringName(String(first_clutch_reinvestment.get("status", "")))
	if status != &"offered":
		var closed := first_clutch_reinvestment_status()
		closed.merge({
			"accepted": false,
			"idempotent": status in [&"purchased", &"banked"],
			"action_id": &"resolve_first_clutch_reinvestment",
			"reason": (
				"This First Clutch reinvestment choice is already resolved."
				if status in [&"purchased", &"banked"] else
				"Mabel's First Clutch reinvestment offer is not open."
			),
		}, true)
		return closed
	if choice_id == FIRST_CLUTCH_BANK_CHOICE_ID:
		var fund_before := revenue_cents
		var spendable_before := spendable_fund_cents()
		first_clutch_reinvestment.merge({
			"status": "banked",
			"choice_id": String(FIRST_CLUTCH_BANK_CHOICE_ID),
			"resolved_day": day,
			"selected_level": 0,
			"selected_list_cost_cents": 0,
			"procurement_match_used_cents": 0,
			"net_cost_cents": 0,
			"fund_before_resolution_cents": fund_before,
			"spendable_before_resolution_cents": spendable_before,
			"fund_after_cents": fund_before,
			"spendable_after_cents": spendable_before,
		}, true)
		var banked := first_clutch_reinvestment_status()
		banked.merge({
			"accepted": true,
			"idempotent": false,
			"action_id": FIRST_CLUTCH_BANK_CHOICE_ID,
			"choice_id": FIRST_CLUTCH_BANK_CHOICE_ID,
			"outcome": "Mabel's egg proceeds stayed in the Feed Fund. The orientation procurement match expired unused.",
			"reason": "Feed Fund banked without spending or minting procurement cash.",
		}, true)
		announcement_posted.emit(String(banked["outcome"]))
		first_clutch_reinvestment_resolved.emit(banked.duplicate(true))
		snapshot_changed.emit(snapshot())
		return banked

	var preflight := first_clutch_reinvestment_preflight(choice_id)
	if not bool(preflight.get("can_purchase", false)):
		var rejection := first_clutch_reinvestment_status()
		rejection.merge(preflight, true)
		rejection.merge({
			"accepted": false,
			"idempotent": false,
			"action_id": &"purchase_requisition",
			"choice_id": choice_id,
		}, true)
		return rejection
	var fund_before := revenue_cents
	var spendable_before := spendable_fund_cents()
	var list_cost := int(preflight["list_cost_cents"])
	var match_used := int(preflight["procurement_match_cents"])
	var net_cost := int(preflight["net_cost_cents"])
	var level := _commit_upgrade_level(choice_id, net_cost, match_used)
	first_clutch_reinvestment.merge({
		"status": "purchased",
		"choice_id": String(choice_id),
		"resolved_day": day,
		"selected_level": level,
		"selected_list_cost_cents": list_cost,
		"procurement_match_used_cents": match_used,
		"net_cost_cents": net_cost,
		"fund_before_resolution_cents": fund_before,
		"spendable_before_resolution_cents": spendable_before,
		"fund_after_cents": revenue_cents,
		"spendable_after_cents": spendable_fund_cents(),
	}, true)
	var definition := UPGRADE_DEFINITIONS[choice_id] as Dictionary
	var purchased := first_clutch_reinvestment_status()
	purchased.merge({
		"accepted": true,
		"idempotent": false,
		"action_id": &"purchase_requisition",
		"choice_id": choice_id,
		"outcome": "%s installed at level %d: $%.2f list, $%.2f orientation match, $%.2f Feed Fund debit."
		% [
			String(definition["name"]), level,
			list_cost / 100.0, match_used / 100.0, net_cost / 100.0,
		],
		"reason": "First Clutch reinvestment purchased exactly once.",
	}, true)
	announcement_posted.emit(String(purchased["outcome"]))
	upgrade_purchased.emit(choice_id, level, net_cost)
	first_clutch_reinvestment_resolved.emit(purchased.duplicate(true))
	snapshot_changed.emit(snapshot())
	return purchased


func _rejected_first_clutch_reinvestment(reason: String) -> Dictionary:
	var result := first_clutch_reinvestment_status()
	result.merge({
		"accepted": false,
		"created": false,
		"idempotent": false,
		"reason": reason,
	}, true)
	return result


func _commit_upgrade_level(
	upgrade_id: StringName,
	net_cost_cents: int,
	procurement_match_cents: int = 0
) -> int:
	var level := upgrade_level(upgrade_id) + 1
	revenue_cents -= net_cost_cents
	upgrade_levels[upgrade_id] = level
	requisition_spend_today_cents += net_cost_cents
	requisition_spend_total_cents += net_cost_cents
	orientation_procurement_match_today_cents += procurement_match_cents
	orientation_procurement_match_total_cents += procurement_match_cents
	return level


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
	var level := upgrade_level(upgrade_id)
	return _upgrade_list_cost_for_level(upgrade_id, level)


func purchase_upgrade(upgrade_id: StringName) -> bool:
	if not UPGRADE_DEFINITIONS.has(upgrade_id):
		announcement_posted.emit("REQUISITION DENIED: initiative code not found.")
		return false
	if StringName(String(first_clutch_reinvestment.get("status", ""))) == &"offered":
		announcement_posted.emit(
			"REQUISITION HELD: resolve Mabel's First Clutch reinvestment offer or Bank the Fund first."
		)
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
	level = _commit_upgrade_level(upgrade_id, cost)
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


func _active_break_count() -> int:
	var count := 0
	for worker in workers:
		if worker.employed and worker.work_state == ChickenState.WorkState.BREAK:
			count += 1
	return count


func _next_flock_care_action(
	wellness_status: Dictionary,
	training_status: Dictionary,
) -> Dictionary:
	var wellness_level := int(wellness_status.get("level", 0))
	var training_level := int(training_status.get("level", 0))
	var selected := wellness_status
	if bool(wellness_status.get("maxed", false)):
		selected = training_status
	elif not bool(training_status.get("maxed", false)) and training_level < wellness_level:
		selected = training_status
	if bool(selected.get("maxed", false)):
		return {
			"complete": true,
			"facility_id": StringName(selected.get("id", &"")),
			"label": "FLOCK CARE PROGRAM FULLY COMMISSIONED",
			"can_purchase": false,
			"reason": "Both cumulative care facilities are fully commissioned.",
		}
	return {
		"complete": false,
		"facility_id": StringName(selected.get("id", &"")),
		"label": String(selected.get("purchase_label", "REVIEW CARE FACILITY")),
		"next_level": int(selected.get("next_level", 0)),
		"next_level_name": String(selected.get("next_level_name", "NEXT TIER")),
		"can_purchase": bool(selected.get("can_purchase", false)),
		"reason": String(selected.get("reason", "")),
		"cost_cents": int(selected.get("cost_cents", 0)),
		"maintenance_delta_cents": int(selected.get("maintenance_delta_cents", 0)),
		"unlock_day": int(selected.get("next_unlock_day", 1)),
	}


func flock_care_snapshot() -> Dictionary:
	var welfare := flock_welfare_score()
	var wellness_status := facility_status(WELLNESS_NEST_ID)
	var training_status := facility_status(TRAINING_ROOST_ID)
	var effects := facility_effects()
	var wellness_level := facility_level(WELLNESS_NEST_ID)
	var training_level := facility_level(TRAINING_ROOST_ID)
	var overnight_fatigue_total := (
		float(wellness_overnight_fatigue_recovery_millipoints()) / 1000.0
	)
	var overnight_stress_total := (
		float(wellness_overnight_stress_recovery_millipoints()) / 1000.0
	)
	var effective_sponsorship_cost := career_sponsorship_cost_cents()
	var effective_training_multiplier := pending_training_work_multiplier()
	var training_active: Array[Dictionary] = []
	for worker in workers:
		if not worker.employed or not worker.cross_training_pending():
			continue
		training_active.append({
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"primary_lane": worker.specialty,
			"target_lane": worker.cross_training_target,
			"target_lane_name": _lane_display_name(worker.cross_training_target),
			"worked_this_shift": worker.cross_training_worked_this_shift,
			"effective_work_multiplier": effective_training_multiplier,
		})
	var rested_flock_active := (
		StringName(active_market_contract.get("clause_id", &"")) == &"rested_flock_warranty"
	)
	return {
		"version": 1,
		"welfare": welfare,
		"welfare_score": welfare,
		"active_staff_count": active_worker_count(),
		"rested_flock_gate": RESTED_FLOCK_WELFARE_MINIMUM,
		"welfare_delta_to_gate": welfare - RESTED_FLOCK_WELFARE_MINIMUM,
		"rested_flock_gate_met": welfare >= RESTED_FLOCK_WELFARE_MINIMUM,
		"rested_flock": {
			"minimum": RESTED_FLOCK_WELFARE_MINIMUM,
			"margin": welfare - RESTED_FLOCK_WELFARE_MINIMUM,
			"met": welfare >= RESTED_FLOCK_WELFARE_MINIMUM,
			"active": rested_flock_active,
		},
		"wellness_level": wellness_level,
		"training_roost_level": training_level,
		"training_active": training_active,
		"training_active_count": training_active.size(),
		"breaks_active": _active_break_count(),
		"recovery_perch_count": wellness_level * 2,
		"recovery_effects": {
			"strain_multiplier": wellness_strain_gain_multiplier(),
			"break_recovery_multiplier": wellness_break_recovery_multiplier(),
			"break_morale_gain": float(wellness_break_morale_millipoints()) / 1000.0,
			"overnight_fatigue_recovery": overnight_fatigue_total,
			"overnight_stress_recovery": overnight_stress_total,
			"overnight_fatigue_recovery_bonus": overnight_fatigue_total - 24.0,
			"overnight_stress_recovery_bonus": overnight_stress_total - 10.0,
		},
		"training_terms": {
			"base_sponsorship_cost_cents": CAREER_SPONSORSHIP_COST_CENTS,
			"effective_sponsorship_cost_cents": effective_sponsorship_cost,
			"sponsorship_discount_cents": CAREER_SPONSORSHIP_COST_CENTS - effective_sponsorship_cost,
			"effective_work_multiplier": effective_training_multiplier,
			"work_basis_points": pending_training_work_basis_points(),
			"work_penalty_percent": roundi((1.0 - effective_training_multiplier) * 100.0),
			"coaching_xp_bonus": career_coaching_xp_bonus(),
			"wage_bonus_cents": ChickenState.CROSS_TRAINING_WAGE_BONUS_CENTS,
		},
		"wellness_nest": wellness_status,
		"training_roost": training_status,
		"effects": effects,
		"next_care_action": _next_flock_care_action(wellness_status, training_status),
	}


func _next_operations_action(
	rooster_status: Dictionary,
	it_status: Dictionary,
) -> Dictionary:
	var rooster_level := int(rooster_status.get("level", 0))
	var it_level := int(it_status.get("level", 0))
	var selected := rooster_status
	if bool(rooster_status.get("maxed", false)):
		selected = it_status
	elif not bool(it_status.get("maxed", false)) and it_level < rooster_level:
		selected = it_status
	if bool(selected.get("maxed", false)):
		return {
			"complete": true,
			"facility_id": StringName(selected.get("id", &"")),
			"label": "OPERATIONS CAMPUS FULLY COMMISSIONED",
			"can_purchase": false,
			"reason": "Both cumulative operations facilities are fully commissioned.",
		}
	return {
		"complete": false,
		"facility_id": StringName(selected.get("id", &"")),
		"label": String(selected.get("purchase_label", "REVIEW OPERATIONS FACILITY")),
		"next_level": int(selected.get("next_level", 0)),
		"next_level_name": String(selected.get("next_level_name", "NEXT TIER")),
		"can_purchase": bool(selected.get("can_purchase", false)),
		"reason": String(selected.get("reason", "")),
		"cost_cents": int(selected.get("cost_cents", 0)),
		"maintenance_delta_cents": int(selected.get("maintenance_delta_cents", 0)),
		"supervisor_payroll_delta_cents": int(
			selected.get("supervisor_payroll_delta_cents", 0)
		),
		"added_daily_operating_cents": int(
			selected.get("added_daily_operating_cents", 0)
		),
		"unlock_day": int(selected.get("next_unlock_day", 1)),
	}


func _manager_display_name(manager: Dictionary) -> String:
	var candidate_id := StringName(String(manager.get("candidate_id", manager.get("id", ""))))
	return String((MANAGER_CANDIDATE_DEFINITIONS.get(candidate_id, {}) as Dictionary).get("name", "Rooster Manager"))


func _manager_rank_for_influence(influence: int) -> int:
	var rank := 0
	for index in MANAGER_RANK_INFLUENCE.size():
		if influence >= MANAGER_RANK_INFLUENCE[index]:
			rank = index
	return rank


func _manager_public_record(manager: Dictionary) -> Dictionary:
	var candidate_id := StringName(String(manager.get("candidate_id", manager.get("id", ""))))
	var definition := MANAGER_CANDIDATE_DEFINITIONS.get(candidate_id, {}) as Dictionary
	var assignment_id := StringName(String(manager.get("assignment_id", "whole_flock")))
	var posture_id := StringName(String(manager.get("posture_id", "coach")))
	var slot_index := clampi(int(manager.get("slot_index", 0)), 0, MANAGER_SLOT_SALARIES_CENTS.size() - 1)
	var rank := clampi(int(manager.get("rank", 0)), 0, MANAGER_RANK_TITLES.size() - 1)
	return {
		"id": candidate_id,
		"name": String(definition.get("name", "Rooster Manager")),
		"archetype": String(definition.get("archetype", "MANAGEMENT")),
		"doctrine": String(definition.get("doctrine", "Alignment is progress.")),
		"color": String(definition.get("color", "343941")),
		"accessory": StringName(definition.get("accessory", &"BowTie")),
		"slot_index": slot_index,
		"hired_day": int(manager.get("hired_day", 1)),
		"assignment_id": assignment_id,
		"assignment_label": String((MANAGER_ASSIGNMENT_DEFINITIONS.get(assignment_id, {}) as Dictionary).get("label", "WHOLE FLOCK")),
		"posture_id": posture_id,
		"posture_label": String((MANAGER_POSTURE_DEFINITIONS.get(posture_id, {}) as Dictionary).get("label", "COACH THE FLOCK")),
		"posture_filed": bool(manager.get("posture_filed", false)),
		"influence": maxi(0, int(manager.get("influence", 0))),
		"rank": rank,
		"title": MANAGER_RANK_TITLES[rank],
		"salary_cents": MANAGER_SLOT_SALARIES_CENTS[slot_index] + rank * 100,
		"credit_claims": maxi(0, int(manager.get("credit_claims", 0))),
		"interventions": maxi(0, int(manager.get("interventions", 0))),
		"last_pip_worker_id": int(manager.get("last_pip_worker_id", -1)),
	}


func _manager_roster_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for manager in manager_roster:
		result.append(_manager_public_record(manager))
	return result


func _manager_candidate_snapshot() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var hired_ids: Dictionary[StringName, bool] = {}
	for manager in manager_roster:
		hired_ids[StringName(String(manager.get("candidate_id", "")))] = true
	var replacement_record := (
		manager_roster[manager_roster.size() - 1]
		if manager_roster.size() > 1 else
		{}
	) as Dictionary
	var replaced_name := _manager_display_name(replacement_record) if not replacement_record.is_empty() else ""
	var replaced_manager_id := StringName(String(replacement_record.get("candidate_id", "")))
	var replacement_slot_index := manager_roster.size() - 1
	var replaced_salary_cents := (
		MANAGER_SLOT_SALARIES_CENTS[replacement_slot_index]
		+ maxi(0, int(replacement_record.get("rank", 0))) * 100
		if replacement_slot_index >= 0 and replacement_slot_index < MANAGER_SLOT_SALARIES_CENTS.size() else
		0
	)
	var appointment_salary_cents := (
		MANAGER_SLOT_SALARIES_CENTS[replacement_slot_index]
		if replacement_slot_index >= 0 and replacement_slot_index < MANAGER_SLOT_SALARIES_CENTS.size() else
		0
	)
	var payroll_before_cents := supervisor_payroll_cents()
	var payroll_after_cents := maxi(
		0,
		payroll_before_cents - replaced_salary_cents + appointment_salary_cents,
	)
	for candidate_id in MANAGER_CANDIDATE_DEFINITIONS:
		var definition := MANAGER_CANDIDATE_DEFINITIONS[candidate_id] as Dictionary
		var hired := hired_ids.has(candidate_id)
		var cost := maxi(0, int(definition.get("signing_cost_cents", 0)))
		var can_recruit := not hired and manager_roster.size() > 1 and staffing_planning_open() and spendable_fund_cents() >= cost
		result.append({
			"id": candidate_id,
			"name": String(definition.get("name", "Rooster Candidate")),
			"archetype": String(definition.get("archetype", "MANAGEMENT")),
			"doctrine": String(definition.get("doctrine", "Alignment is progress.")),
			"default_posture": StringName(definition.get("default_posture", &"coach")),
			"signing_cost_cents": cost,
			"hired": hired,
			"can_recruit": can_recruit,
			"replaces_name": replaced_name,
			"replaces_manager_id": replaced_manager_id,
			"replaces_salary_cents": replaced_salary_cents,
			"appointment_salary_cents": appointment_salary_cents,
			"manager_count": manager_roster.size(),
			"supervisor_payroll_before_cents": payroll_before_cents,
			"supervisor_payroll_after_cents": payroll_after_cents,
			"supervisor_payroll_delta_cents": payroll_after_cents - payroll_before_cents,
			"reason": (
				"Already on payroll." if hired else
				"Commission Rooster Operations level 1 first." if manager_roster.size() < 2 else
				"Appointments are filed during review." if not staffing_planning_open() else
				"Needs $%.2f spendable Feed Fund." % (float(cost) / 100.0) if spendable_fund_cents() < cost else
				"Appoints to the newest post and strategically exits %s." % replaced_name
			),
		})
	result.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("name", "")) < String(right.get("name", ""))
	)
	return result


func _manager_catalog_snapshot(source: Dictionary, order: Array[StringName]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in order:
		var definition := source[item_id] as Dictionary
		var row := definition.duplicate(true)
		row["id"] = item_id
		result.append(row)
	return result


func management_density_snapshot() -> Dictionary:
	var active_staff := active_worker_count()
	var manager_count := manager_roster.size()
	var density := float(manager_count) / maxf(1.0, float(active_staff))
	var excess := maxi(0, manager_count * 2 - active_staff)
	var conflicts := 0
	for worker in workers:
		if worker.employed:
			conflicts += int(_manager_effect_for_worker(worker).get("conflicts", 0))
	return {
		"manager_count": manager_count,
		"authorized_seats": manager_capacity(),
		"active_hens": active_staff,
		"ratio": snappedf(density, 0.001),
		"label": "1 : %.1f" % (float(active_staff) / maxf(1.0, float(manager_count))),
		"excess_managers": excess,
		"meeting_minutes": manager_count * 10 + excess * 20,
		"conflicting_directives": conflicts,
		"risk_label": "OVERMANAGED" if excess > 0 else ("DENSE" if density >= 0.5 else "WORKABLE"),
	}


func operations_snapshot() -> Dictionary:
	var rooster_status := facility_status(ROOSTER_OPERATIONS_OFFICE_ID)
	var it_status := facility_status(IT_COOP_ID)
	var action_status := personnel_action_status()
	var actions := (action_status.get("actions", []) as Array).duplicate(true)
	var quota_pressure_actions := 0
	for action_value in actions:
		var action := action_value as Dictionary
		if StringName(action.get("action_id", &"")) == &"quota_pressure":
			quota_pressure_actions += 1
	var auto_enrolled_workers := 0
	var active_auto_claims := 0
	for worker in workers:
		if not worker.employed or worker.assigned_lane != AUTO_ASSIGNMENT:
			continue
		auto_enrolled_workers += 1
		if (
			worker.current_claim != null
			and worker.work_state in [
				ChickenState.WorkState.WORKING,
				ChickenState.WorkState.LAYING,
			]
		):
			active_auto_claims += 1
	var pressure_applied := (
		active_directive_id != &""
		and shift_phase in [ShiftPhase.RUNNING, ShiftPhase.AWAITING_INCIDENT]
	)
	return {
		"version": 2,
		"rooster_office_level": facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		"it_coop_level": facility_level(IT_COOP_ID),
		"flock_relations_office_level": facility_level(FLOCK_RELATIONS_OFFICE_ID),
		"supervision": {
			"action_limit": int(action_status.get("limit", personnel_action_limit())),
			"actions_used": int(action_status.get("used", 0)),
			"actions_remaining": int(action_status.get("remaining", 0)),
			"actions": actions,
			"supervisor_payroll_cents": current_daily_supervisor_payroll_cents(),
			"surveillance_grievance_millipoints": rooster_surveillance_grievance_millipoints(),
			"surveillance_stress_millipoints": rooster_surveillance_stress_millipoints(),
			"surveillance_solidarity_millipoints": rooster_surveillance_solidarity_millipoints(),
			"quota_pressure_actions_today": quota_pressure_actions,
			"shift_pressure_applied": pressure_applied,
		},
		"manager_roster": _manager_roster_snapshot(),
		"manager_candidates": _manager_candidate_snapshot(),
		"manager_capacity": manager_capacity(),
		"manager_assignments": _manager_catalog_snapshot(MANAGER_ASSIGNMENT_DEFINITIONS, MANAGER_ASSIGNMENT_ORDER),
		"manager_postures": _manager_catalog_snapshot(MANAGER_POSTURE_DEFINITIONS, MANAGER_POSTURE_ORDER),
		"management_density": management_density_snapshot(),
		"management_reports": {
			"today": management_reports_today,
			"total": management_reports_total,
			"visibility_today": management_visibility_today,
			"produces_eggs": false,
		},
		"last_manager_action": last_manager_action.duplicate(true),
		"automation": {
			"enabled": facility_level(IT_COOP_ID) > 0,
			"work_basis_points": automation_work_basis_points(),
			"work_multiplier": automation_work_multiplier(),
			"specialty_grace_minutes": automation_specialty_grace_minutes(),
			"recognizes_secondary_specialties": automation_recognizes_secondary_specialties(),
			"compliance_exposure_millipoints": automation_compliance_exposure_millipoints(),
			"ledger_patch_cost_cents": ledger_molt_patch_cost_cents(),
			"spreadsheet_compliance_loss_millipoints": ledger_molt_spreadsheet_compliance_loss_millipoints(),
			"spreadsheet_crack_basis_points": ledger_molt_spreadsheet_crack_basis_points(),
			"auto_enrolled_workers": auto_enrolled_workers,
			"active_auto_claims": active_auto_claims,
			"shift_exposure_applied": pressure_applied,
		},
		"daily_costs": {
			"supervisor_payroll_cents": current_daily_supervisor_payroll_cents(),
			"rooster_maintenance_cents": int(
				rooster_status.get("current_maintenance_cents", 0)
			),
			"it_maintenance_cents": int(it_status.get("current_maintenance_cents", 0)),
		},
		"rooster_operations_office": rooster_status,
		"it_coop": it_status,
		"next_operations_action": _next_operations_action(rooster_status, it_status),
	}


func relationship_rows(worker_id: int) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for partner in workers:
		if partner.id == worker_id:
			continue
		var row := flock_relationships.snapshot(worker_id, partner.id)
		row["partner_name"] = partner.display_name
		row["employed"] = partner.employed
		rows.append(row)
	return rows


func relationship_panel_snapshot(worker_id: int, partner_id: int) -> Dictionary:
	_ensure_active_playbook()
	var roster: Array[Dictionary] = []
	for worker in workers:
		roster.append({"id": worker.id, "name": worker.display_name, "employed": worker.employed})
	var valid := worker_id >= 0 and partner_id >= 0 and worker_id < workers.size() and partner_id < workers.size() and worker_id != partner_id
	var pair := flock_relationships.snapshot(worker_id, partner_id) if valid else {}
	var ready := valid and workers[worker_id].employed and workers[partner_id].employed and shift_phase == ShiftPhase.RUNNING and pending_decision.is_empty() and not bool(active_playbook.get("teamwork_used", false))
	var reason := "One shared moment per shift; uses today's Team Lift opportunity."
	if bool(active_playbook.get("teamwork_used", false)):
		reason = "Today's shared moment is used. Their story continues next shift."
	elif not ready:
		reason = "Choose two employed hens during a running shift."
	var contest_ready := ready and int(pair.get("affinity", 0)) < 0 and worker_id not in flock_relationships.clean_workers and partner_id not in flock_relationships.clean_workers
	if ready and int(pair.get("affinity", 0)) < 0 and not contest_ready:
		reason += " Contests must start before either hen delivers a clean egg."
	return {"roster": roster, "worker_id": worker_id, "partner_id": partner_id, "pair": pair, "rows": relationship_rows(worker_id) if worker_id >= 0 else [], "reason": reason, "break_available": ready and spendable_fund_cents() >= 100, "repair_available": ready and int(pair.get("affinity", 0)) < 0, "contest_available": contest_ready, "day": day}


func perform_relationship_action(worker_id: int, partner_id: int, action: String) -> Dictionary:
	if action not in ["shared_break", "clear_air", "friendly_contest"]:
		return {"accepted": false, "reason": "Choose a shared break, clear the air, or a friendly contest."}
	var panel := relationship_panel_snapshot(worker_id, partner_id)
	if not bool(panel.contest_available if action == "friendly_contest" else panel.break_available if action == "shared_break" else panel.repair_available):
		return {"accepted": false, "reason": "That shared moment is unavailable. " + String(panel.reason)}
	var before := flock_relationships.affinity(worker_id, partner_id)
	if not flock_relationships.record(worker_id, partner_id, action, day):
		return {"accepted": false, "reason": "This pair already remembers that moment today."}
	var cost := 100 if action == "shared_break" else 0
	revenue_cents -= cost
	active_playbook["teamwork_used"] = true
	for id in [worker_id, partner_id]:
		workers[id].stress = clampf(workers[id].stress + (3.0 if action == "friendly_contest" else -4.0 if action == "shared_break" else -2.0), 0.0, 100.0)
		if action != "friendly_contest":
			workers[id].morale = minf(100.0, workers[id].morale + 2.0)
	var after := flock_relationships.snapshot(worker_id, partner_id)
	_award_clean_pair(workers[worker_id], workers[partner_id])
	var feedback := "+3 stress each now. Deliver one clean egg each for +6 XP each and +6 warmth." if action == "friendly_contest" else "-%d stress / +2 morale each. %s" % [4 if action == "shared_break" else 2, "They are finding common ground again." if after.reconciled else "They will remember this next shift."]
	return _file_playbook_receipt({"accepted": true, "playbook_kind": "relationship", "choice_id": action, "worker_id": worker_id, "partner_id": partner_id, "label": "FRIENDLY CONTEST" if action == "friendly_contest" else "SHARED MOMENT", "day": day, "cost_cents": cost, "affinity_before": before, "affinity_after": after.affinity, "outcome": "%s + %s: %s (%+d warmth). %s" % [workers[worker_id].display_name, workers[partner_id].display_name, after.label, int(after.affinity) - before, feedback]})


func _award_clean_pair(worker: ChickenState, partner: ChickenState) -> void:
	var reward := flock_relationships.pair_reward(worker.id, partner.id)
	if not reward.eligible or reward.earned or int(reward.progress) != 2:
		return
	if not flock_relationships.record(worker.id, partner.id, "contest_reward" if reward.contest else "inseparable_reward" if int(reward.xp) == 4 else "friend_reward", day):
		return
	for hen in [worker, partner]:
		hen.add_career_xp(int(reward.xp))
		hen.stress = maxf(0.0, hen.stress - float(reward.relief))
	var label := "CONTEST COMPLETE" if reward.contest else "CLEAN PAIR"
	var outcome := "%s · %s + %s: +%d XP each%s." % [label, worker.display_name, partner.display_name, reward.xp, " / +6 warmth" if reward.contest else " / -%d stress each" % reward.relief]
	announcement_posted.emit(outcome)
	pair_reward_earned.emit({"worker_id": worker.id, "partner_id": partner.id, "day": day, "label": label, "xp": reward.xp, "relief": reward.relief, "contest": reward.contest, "outcome": outcome})


func _worker_flock_bond_snapshot(worker: ChickenState) -> Dictionary:
	## Current social temperature plus the pair's persistent shared history.
	if not worker.employed:
		return {
			"partner_id": -1,
			"partner_name": "",
			"score": 0,
			"label": "OFF THE FLOOR",
			"summary": "Applicant relationships resume after a perch is authorized.",
		}
	var partner: ChickenState
	var nearest_distance := 1_000_000
	for candidate in workers:
		if not candidate.employed or candidate.id == worker.id:
			continue
		var desk_distance := absi(candidate.desk_index - worker.desk_index)
		if (
			partner == null
			or desk_distance < nearest_distance
			or (desk_distance == nearest_distance and candidate.id < partner.id)
		):
			partner = candidate
			nearest_distance = desk_distance
	if partner == null:
		return {
			"partner_id": -1,
			"partner_name": "",
			"score": 50,
			"label": "SOLO PERCH",
			"summary": "No active perchmate is close enough to file a flock bond.",
		}
	var shared_strain := (worker.stress + partner.stress + worker.fatigue + partner.fatigue) * 0.0625
	var shared_history := flock_relationships.snapshot(worker.id, partner.id)
	var shared_grievance := (worker.grievance + partner.grievance) * 0.10
	var shared_morale := (worker.morale + partner.morale - 100.0) * 0.16
	var bond_score := clampi(roundi(
		50.0
		+ (solidarity - 50.0) * 0.34
		+ shared_morale
		+ shared_grievance
		- shared_strain
		+ float(shared_history.affinity) * 0.6
	), 0, 100)
	var bond_label := "WITHDRAWN"
	if bond_score >= 75:
		bond_label = "CLUTCHMATES"
	elif bond_score >= 60:
		bond_label = "GOOD PERCH"
	elif bond_score >= 45:
		bond_label = "PROFESSIONAL"
	elif bond_score >= 30:
		bond_label = "GUARDED"
	var summary := "%s with %s (%d/100)." % [bond_label, partner.display_name, bond_score]
	if shared_strain >= 10.0:
		summary += " Shared strain is crowding out perch-side trust."
	elif solidarity >= 60.0:
		summary += " Flock solidarity is strengthening the relationship."
	elif shared_grievance >= 8.0:
		summary += " Shared management memory is pulling the pair together."
	else:
		summary += " The relationship is steady but still mostly professional."
	if int(shared_history.affinity) != 0 or bool(shared_history.reconciled):
		summary += " %s: %+d warmth. %s" % [shared_history.label, int(shared_history.affinity), shared_history.benefit]
	return {
		"partner_id": partner.id,
		"partner_name": partner.display_name,
		"score": bond_score,
		"label": bond_label,
		"summary": summary,
		"history": shared_history,
	}


func _signed_temperament_percent(basis_points: int, metric: String) -> String:
	if basis_points == 0:
		return ""
	var magnitude := absf(float(basis_points) / 100.0)
	var amount := (
		"%d" % roundi(magnitude)
		if basis_points % 100 == 0 else
		"%.1f" % magnitude
	)
	return "%s%s%% %s" % ["+" if basis_points > 0 else "-", amount, metric]


func _worker_temperament_effect(
	worker: ChickenState,
	flock_bond: Dictionary = {},
) -> Dictionary:
	## A small, fully disclosed identity modifier. Static values live with the
	## temperament definition; the two social work styles react only to already
	## authoritative flock state, so this adds strategy without save authority.
	var temperament_id := ChickenState.default_temperament(worker.id)
	var definition := ChickenState.temperament_definition(worker.id)
	var pace_basis_points := int(definition.get("pace_basis_points", 0))
	var crack_basis_points := int(definition.get("crack_basis_points", 0))
	var strain_basis_points := int(definition.get("strain_basis_points", 10_000))
	var break_recovery_basis_points := int(
		definition.get("break_recovery_basis_points", 10_000)
	)
	var condition := ""
	match StringName(definition.get("dynamic_axis", &"")):
		&"flock_bond":
			var effective_bond := (
				flock_bond
				if not flock_bond.is_empty() else
				_worker_flock_bond_snapshot(worker)
			)
			var bond_score := int(effective_bond.get("score", 0))
			if bond_score >= 60:
				pace_basis_points += 400
				strain_basis_points -= 300
				condition = "bond score 60+"
			elif bond_score < 30:
				pace_basis_points -= 400
				condition = "bond score below 30"
			else:
				condition = "bond score 30-59"
		&"solidarity":
			if solidarity >= 60.0:
				pace_basis_points += 400
				strain_basis_points -= 500
				condition = "flock solidarity 60+"
			elif solidarity < 35.0:
				pace_basis_points -= 400
				condition = "flock solidarity below 35"
			else:
				condition = "flock solidarity 35-59"
	pace_basis_points = clampi(pace_basis_points, -800, 800)
	crack_basis_points = clampi(crack_basis_points, -400, 400)
	strain_basis_points = clampi(strain_basis_points, 8_500, 11_500)
	break_recovery_basis_points = clampi(
		break_recovery_basis_points,
		9_000,
		12_500,
	)
	var terms: Array[String] = []
	var pace_term := _signed_temperament_percent(pace_basis_points, "pace")
	var crack_term := _signed_temperament_percent(crack_basis_points, "shell risk")
	var strain_term := _signed_temperament_percent(
		strain_basis_points - 10_000,
		"strain",
	)
	var recovery_term := _signed_temperament_percent(
		break_recovery_basis_points - 10_000,
		"break recovery",
	)
	for term in [pace_term, crack_term, strain_term, recovery_term]:
		if not term.is_empty():
			terms.append(term)
	if terms.is_empty():
		terms.append("steady baseline")
	if not condition.is_empty():
		terms.append(condition)
	var potential_summary := " / ".join(terms)
	var engaged := (
		worker.employed
		and worker.manually_routed
		and worker.assigned_lane != AUTO_ASSIGNMENT
	)
	var summary := (
		"MANUAL / %s" % potential_summary
		if engaged else
		"%s / MANUAL PREVIEW: %s" % [
			"AUTO BASELINE" if worker.employed else "APPLICANT PREVIEW",
			potential_summary,
		]
	)
	var effective_pace_basis_points := pace_basis_points if engaged else 0
	var effective_crack_basis_points := crack_basis_points if engaged else 0
	var effective_strain_basis_points := strain_basis_points if engaged else 10_000
	var effective_break_recovery_basis_points := (
		break_recovery_basis_points if engaged else 10_000
	)
	return {
		"temperament_id": temperament_id,
		"label": String(definition.get("work_style_label", "STEADY RHYTHM")),
		"engaged": engaged,
		"pace_basis_points": effective_pace_basis_points,
		"work_multiplier": 1.0 + float(effective_pace_basis_points) / 10_000.0,
		"crack_basis_points": effective_crack_basis_points,
		"crack_modifier": float(effective_crack_basis_points) / 10_000.0,
		"strain_basis_points": effective_strain_basis_points,
		"strain_multiplier": float(effective_strain_basis_points) / 10_000.0,
		"break_recovery_basis_points": effective_break_recovery_basis_points,
		"break_recovery_multiplier": float(effective_break_recovery_basis_points) / 10_000.0,
		"potential_pace_basis_points": pace_basis_points,
		"potential_crack_basis_points": crack_basis_points,
		"potential_strain_basis_points": strain_basis_points,
		"potential_break_recovery_basis_points": break_recovery_basis_points,
		"potential_summary": potential_summary,
		"condition": condition,
		"summary": summary,
	}


func worker_temperament_effect(worker_id: int) -> Dictionary:
	if worker_id < 0 or worker_id >= workers.size():
		return {}
	return _worker_temperament_effect(workers[worker_id]).duplicate(true)


func _build_runtime_static_projection_bundle() -> Dictionary:
	var campus_expansion_projection := campus_expansion_snapshot()
	return {
		"campus_expansion": campus_expansion_projection,
		"campus_portfolio": campus_portfolio_snapshot(campus_expansion_projection),
		"staffing_catalog": staffing_catalog(),
		"facility_catalog": facility_catalog(),
	}


func _build_runtime_live_projection_bundle() -> Dictionary:
	var result := {}
	var started := cost_probe.begin()
	result["contract_board"] = market_contract_board_status()
	cost_probe.finish(&"bundle_contract", started)
	started = cost_probe.begin()
	result["farm_mutual_service_coop"] = farm_mutual_service_coop_status()
	cost_probe.finish(&"bundle_service", started)
	started = cost_probe.begin()
	result["farm_mutual_negotiation_room"] = farm_mutual_negotiation_room_status()
	cost_probe.finish(&"bundle_negotiation", started)
	started = cost_probe.begin()
	result["economic_briefing"] = economic_briefing_snapshot(result["contract_board"])
	cost_probe.finish(&"bundle_economy", started)
	started = cost_probe.begin()
	result["feed_procurement"] = feed_procurement_snapshot()
	cost_probe.finish(&"bundle_feed", started)
	started = cost_probe.begin()
	result["flock_care"] = flock_care_snapshot()
	cost_probe.finish(&"bundle_care", started)
	started = cost_probe.begin()
	result["operations"] = operations_snapshot()
	cost_probe.finish(&"bundle_operations", started)
	return result


func _snapshot_projection_bundle(
	use_runtime_cache: bool,
	trusted_read_only: bool = false,
) -> Dictionary:
	var now_msec := Time.get_ticks_msec()
	var static_cache_current := (
		not _runtime_static_projection_cache.is_empty()
		and _runtime_projection_cache_day == day
		and _runtime_projection_cache_phase == shift_phase
	)
	var live_cache_current := (
		not _runtime_live_projection_cache.is_empty()
		and static_cache_current
		and _runtime_projection_cache_msec >= 0
		and now_msec - _runtime_projection_cache_msec < RUNTIME_PROJECTION_REFRESH_MSEC
	)
	var rebuilt := false
	if not use_runtime_cache or not static_cache_current:
		_runtime_static_projection_cache = _build_runtime_static_projection_bundle()
		_runtime_static_projection_cache_builds += 1
		rebuilt = true
	if not use_runtime_cache or not live_cache_current:
		_runtime_live_projection_cache = _build_runtime_live_projection_bundle()
		_runtime_live_projection_cache_builds += 1
		_runtime_projection_cache_msec = now_msec
		rebuilt = true
	if rebuilt:
		_runtime_projection_cache = _runtime_static_projection_cache.duplicate()
		_runtime_projection_cache.merge(_runtime_live_projection_cache, true)
		_runtime_projection_cache_day = day
		_runtime_projection_cache_phase = shift_phase
		_runtime_projection_cache_builds += 1
		if use_runtime_cache:
			_runtime_projection_cache_refresh_builds += 1
		else:
			_runtime_projection_cache_exact_builds += 1
	else:
		_runtime_projection_cache_hits += 1
	if trusted_read_only:
		_runtime_projection_cache_read_only_hits += 1
		return _runtime_projection_cache
	# Consumers have historically been allowed to enrich presentation snapshots.
	# Preserve that defensive-copy contract so no UI mutation can poison the
	# cached authoritative projection used by a later clock frame.
	return _runtime_projection_cache.duplicate(true)


func runtime_projection_cache_diagnostics() -> Dictionary:
	return {
		"refresh_msec": RUNTIME_PROJECTION_REFRESH_MSEC,
		"builds": _runtime_projection_cache_builds,
		"hits": _runtime_projection_cache_hits,
		"exact_builds": _runtime_projection_cache_exact_builds,
		"runtime_refresh_builds": _runtime_projection_cache_refresh_builds,
		"read_only_hits": _runtime_projection_cache_read_only_hits,
		"static_builds": _runtime_static_projection_cache_builds,
		"live_builds": _runtime_live_projection_cache_builds,
		"tick_snapshot_hits": _runtime_tick_snapshot_cache_hits,
		"cached": not _runtime_projection_cache.is_empty(),
		"cached_day": _runtime_projection_cache_day,
		"cached_phase": _runtime_projection_cache_phase,
		"age_msec": (
			maxi(0, Time.get_ticks_msec() - _runtime_projection_cache_msec)
			if _runtime_projection_cache_msec >= 0 else
			-1
		),
	}


## Compact three-beat personal arc derived from the career authority that
## already changes wage, pace, shell risk, credentials, and world presentation.
## No separate mastery currency or save field is introduced.
func _worker_personal_mastery_snapshot(worker_snapshot: Dictionary) -> Dictionary:
	var level := int(worker_snapshot.get("career_level", 0))
	var secondary_ready := bool(worker_snapshot.get("has_secondary_specialty", false))
	var rows: Array[Dictionary] = [
		{
			"id": "trusted_layer",
			"label": "TRUSTED LAYER",
			"complete": level >= 1,
			"reward": "CAREER TITLE + DESK CREDENTIAL",
		},
		{
			"id": "second_lane",
			"label": "SECOND LANE",
			"complete": secondary_ready,
			"reward": "SECONDARY SPECIALTY + TORSO BADGE",
		},
		{
			"id": "lead_hen",
			"label": "LEAD HEN",
			"complete": level >= 3,
			"reward": "MASTER LAYER TITLE + OFFICE CREST",
		},
	]
	var completed := 0
	var next_id := ""
	var next_label := "MASTERED"
	var next_reward := String(worker_snapshot.get("career_title", "MASTER LAYER"))
	for row in rows:
		if bool(row.get("complete", false)):
			completed += 1
		elif next_id.is_empty():
			next_id = String(row.get("id", ""))
			next_label = String(row.get("label", "NEXT MASTERY"))
			next_reward = String(row.get("reward", "VISIBLE CAREER REWARD"))
	return {
		"worker_id": int(worker_snapshot.get("id", -1)),
		"worker_name": String(worker_snapshot.get("name", "HEN")),
		"completed": completed,
		"total": rows.size(),
		"complete": completed == rows.size(),
		"next_id": next_id,
		"next_label": next_label,
		"next_reward": next_reward,
		"rows": rows,
		"career_xp": int(worker_snapshot.get("career_xp", 0)),
		"career_next_threshold": int(worker_snapshot.get("career_next_threshold", -1)),
	}


## Projects the single most useful next read for a hen. This remains a
## presentation-only summary: actions still flow through their existing
## authoritative APIs, while every surface shares one stable priority order.
func _worker_hen_intent_snapshot(worker_snapshot: Dictionary) -> Dictionary:
	if not bool(worker_snapshot.get("employed", true)):
		return {}
	var worker_name := String(worker_snapshot.get("name", "This hen"))
	var state_label := String(worker_snapshot.get("state_label", "")).to_upper()
	var stress := roundi(float(worker_snapshot.get("stress", 0.0)))
	var fatigue := roundi(float(worker_snapshot.get("fatigue", 0.0)))
	var morale := roundi(float(worker_snapshot.get("morale", 100.0)))
	if state_label == "WELLNESS":
		return {
			"id": &"recovering",
			"icon": &"care",
			"action_id": &"support",
			"action_label": "CHECK IN",
			"detail": "%s is recovering at the Wellness Nest. Open Support to review care options." % worker_name,
			"urgency": 2,
			"actionable": true,
		}
	var assist := worker_snapshot.get("peck_assist", {}) as Dictionary
	if bool(assist.get("available", false)):
		return {
			"id": &"sync",
			"icon": &"sync",
			"action_id": &"peck",
			"action_label": "SYNC PECK",
			"detail": "%s's Priority Peck window is open. Activate it to stamp the live rhythm." % worker_name,
			"urgency": 3,
			"actionable": true,
		}
	var claim := worker_snapshot.get("current_claim", {}) as Dictionary
	# Claimant paths and deadline intervention retire once work has crossed into
	# laying. The claim remains attached to the hen until the egg is released, so
	# this phase guard must precede every generic live-claim intent below.
	if state_label == "LAYING" and not claim.is_empty():
		return {
			"id": &"delivery",
			"icon": &"delivery",
			"action_id": &"route",
			"action_label": "TRACK EGG",
			"detail": "%s's file is locked and the egg is laying. Track it through grading to farmer delivery; a clean assisted egg returns 1 Priority Peck charge." % worker_name,
			"urgency": 1,
			"actionable": true,
		}
	if not claim.is_empty():
		var minutes_left := int(claim.get("minutes_until_deadline", 9999))
		var overdue := bool(claim.get("overdue", false)) or minutes_left < 0
		if overdue or minutes_left <= 60:
			return {
				"id": &"deadline",
				"icon": &"urgent",
				"action_id": &"claim",
				"action_label": "OPEN FILE",
				"detail": (
					"%s's current file is overdue by %dm. Open the live file." % [worker_name, absi(minutes_left)]
					if overdue else
					"%s's current file is due in %dm. Open the live file." % [worker_name, maxi(0, minutes_left)]
				),
				"urgency": 3,
				"actionable": true,
			}
	if stress >= 60 or fatigue >= 65 or morale <= 40:
		return {
			"id": &"care",
			"icon": &"care",
			"action_id": &"support",
			"action_label": "CHECK IN",
			"detail": "%s needs attention: stress %d, fatigue %d, morale %d. Open Support to choose a check-in." % [worker_name, stress, fatigue, morale],
			"urgency": 2,
			"actionable": true,
		}
	if not claim.is_empty():
		var resolution := worker_snapshot.get("claim_resolution_status", {}) as Dictionary
		var progress := roundi(float(worker_snapshot.get("progress", 0.0)))
		var resolution_cutoff := roundi(float(resolution.get(
			"cutoff_progress",
			CLAIM_RESOLUTION_CUTOFF_PROGRESS,
		)))
		if (
			bool(resolution.get("available", false))
			and not bool(claim.get("resolution_locked", false))
			and progress < resolution_cutoff
		):
			return {
				"id": &"choice",
				"icon": &"choice",
				"action_id": &"claim",
				"action_label": "CHOOSE OUTCOME",
				"cutoff_progress": resolution_cutoff,
				"detail": "%s's claimant outcome is open before %d%% progress. Compare care, pace, risk, and cost." % [worker_name, resolution_cutoff],
				"urgency": 2,
				"actionable": true,
			}
		if bool(claim.get("specialty_match", false)):
			return {
				"id": &"match",
				"icon": &"match",
				"action_id": &"claim",
				"action_label": "GOOD MATCH",
				"detail": "%s is on specialty work: 18%% faster with 4%% less shell risk. Open the live file." % worker_name,
				"urgency": 1,
				"actionable": true,
			}
		return {
			"id": &"steady",
			"icon": &"steady",
			"action_id": &"claim",
			"action_label": "TRACK FILE",
			"detail": "%s is working steadily at %d%%. Track the live file or prepare Priority Peck." % [worker_name, progress],
			"urgency": 1,
			"actionable": true,
		}
	return {
		"id": &"ready",
		"icon": &"ready",
		"action_id": &"route",
		"action_label": "SET ROUTE",
		"detail": "%s is waiting for the next file. Review or change her tray route." % worker_name,
		"urgency": 1,
		"actionable": true,
	}


## Exact, small read model for a completed egg's bark and campaign cause receipt.
## These consumers need current counters and hen vitals, not purchase catalogs
## or the campus economy. No cache or authority is changed by this read.
func production_reaction_snapshot() -> Dictionary:
	var worker_rows: Array[Dictionary] = []
	var now := _current_operational_minute()
	for worker in workers:
		worker_rows.append(worker.snapshot(now))
	return {
		"workers": worker_rows,
		"eggs_today": eggs_today,
		"quota_target": quota_target,
		"cracked_today": cracked_today,
		"compliance": compliance,
		"executive_confidence": executive_confidence,
		"overdue_claims": _overdue_claim_count(true),
		"rework_total_created": _rework_total_created,
		"credited_today_cents": credited_today_cents,
		"wage_arrears_cents": wage_arrears_cents,
		"revenue_cents": revenue_cents,
	}


func snapshot(
	use_runtime_projection_cache: bool = false,
	trusted_runtime_projection_read_only: bool = false,
) -> Dictionary:
	var probe_started := cost_probe.begin()
	_sync_claims_waiting()
	var now := _current_operational_minute()
	var worker_snapshots: Array[Dictionary] = []
	var live_pecking_order := current_pecking_order()
	var staffing_action_available := staffing_planning_open() and not _staffing_action_used_today()
	var active_staff := active_worker_count()
	var vacant_desk := _lowest_vacant_desk()
	var spendable := spendable_fund_cents()
	var assist_delivery_status := peck_assist_delivery_status()
	# Hire projections share one feed delta and one obligation base per read.
	var hire_feed_delta_cents := _hire_feed_obligation_delta_cents()
	var obligation_base_cents: Variant = _projected_spendable_base_cents()
	var stage_started := cost_probe.begin()
	for worker in workers:
		var worker_snapshot := worker.snapshot(now)
		var flock_bond := _worker_flock_bond_snapshot(worker)
		worker_snapshot["flock_bond"] = flock_bond
		worker_snapshot["relationships"] = relationship_rows(worker.id)
		worker_snapshot["temperament_effect"] = _worker_temperament_effect(
			worker,
			flock_bond,
		)
		var shift_stats := _worker_shift_stat(worker.id)
		worker_snapshot["shift_eggs"] = int(shift_stats.get("eggs", 0))
		worker_snapshot["shift_sound"] = int(shift_stats.get("sound", 0))
		worker_snapshot["shift_cracked"] = int(shift_stats.get("cracked", 0))
		worker_snapshot["shift_golden"] = int(shift_stats.get("golden", 0))
		worker_snapshot["shift_credit_cents"] = int(shift_stats.get("credit_cents", 0))
		worker_snapshot["at_workstation"] = is_worker_at_workstation(worker.id)
		worker_snapshot["welfare_score"] = _worker_welfare_score(worker) if worker.employed else 0
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
		worker_snapshot["cross_training_base_work_multiplier"] = (
			ChickenState.CROSS_TRAINING_WORK_MULTIPLIER if worker.cross_training_pending() else 1.0
		)
		worker_snapshot["cross_training_work_basis_points"] = (
			pending_training_work_basis_points() if worker.cross_training_pending() else 10_000
		)
		worker_snapshot["cross_training_work_multiplier"] = (
			_effective_cross_training_work_multiplier(worker)
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
		worker_snapshot["automation_policy_id"] = String(worker.automation_policy_id)
		worker_snapshot["automation_policy_unlocked"] = worker.automation_policy_unlocked
		worker_snapshot["automation_policy"] = (
			(PLAYBOOK_DELEGATION_POLICY_DEFINITIONS.get(worker.automation_policy_id, {}) as Dictionary).duplicate(true)
			if worker.automation_policy_unlocked else
			{}
		)
		var hire_added_daily_operating_cents := (
			hire_feed_delta_cents + worker.daily_wage_cents()
		)
		var hire_projected_spendable_cents := _projected_spendable_from_base_cents(
			obligation_base_cents,
			worker.hire_cost_cents(),
			hire_added_daily_operating_cents,
		)
		worker_snapshot["hire_added_daily_operating_cents"] = hire_added_daily_operating_cents
		worker_snapshot["hire_required_spendable_cents"] = _required_spendable_for_obligation_change_cents(
			worker.hire_cost_cents(),
			hire_added_daily_operating_cents,
		)
		worker_snapshot["hire_projected_spendable_fund_cents"] = hire_projected_spendable_cents
		worker_snapshot["can_hire"] = (
			staffing_action_available
			and not worker.employed
			and worker.available_for_hire_day <= day
			and active_staff < office_capacity
			and vacant_desk >= 0
			and hire_projected_spendable_cents >= 0
		)
		worker_snapshot["can_release"] = (
			staffing_action_available
			and worker.employed
			and active_staff > MINIMUM_STAFF_COUNT
			and (
				int(active_market_contract.get("required_active_staff", 0)) <= 0
				or active_staff - 1 >= int(active_market_contract.get("required_active_staff", 0))
			)
			and worker.work_state == ChickenState.WorkState.IDLE
			and worker.current_claim == null
			and spendable >= worker.release_cost_cents()
		)
		var current_claim_snapshot := worker_snapshot.get("current_claim", {}) as Dictionary
		if not current_claim_snapshot.is_empty():
			_apply_market_contract_claim_snapshot(current_claim_snapshot)
			current_claim_snapshot["routing_golden_target"] = (
				worker.current_claim.id == routing_momentum_golden_target_claim_id
				and worker.id == routing_momentum_golden_target_worker_id
			)
			current_claim_snapshot["specialty_match"] = worker.has_specialty(worker.current_claim.lane)
			current_claim_snapshot["affinity_speed_multiplier"] = _claim_speed_factor(worker)
			current_claim_snapshot["affinity_crack_modifier"] = _claim_affinity_crack_modifier(worker)
			current_claim_snapshot["facility_speed_multiplier"] = _facility_claim_speed_multiplier(worker)
			current_claim_snapshot["automation_work_multiplier"] = automation_work_multiplier(worker)
			current_claim_snapshot["automation_enrolled"] = worker.assigned_lane == AUTO_ASSIGNMENT
		var resolution_status := _claim_resolution_status(worker.id)
		worker_snapshot["claim_resolution_status"] = resolution_status
		worker_snapshot["personal_mastery"] = _worker_personal_mastery_snapshot(
			worker_snapshot
		)
		worker_snapshot["hen_intent"] = _worker_hen_intent_snapshot(worker_snapshot)
		worker_snapshots.append(worker_snapshot)
	cost_probe.finish(&"snapshot_workers", stage_started)
	stage_started = cost_probe.begin()
	var queue_snapshot := _queue_snapshot()
	var pending_rework_items: Array[Dictionary] = []
	for claim in _pending_rework:
		pending_rework_items.append(claim.snapshot(now))

	cost_probe.finish(&"snapshot_queue", stage_started)
	stage_started = cost_probe.begin()
	var runtime_projections := _snapshot_projection_bundle(
		use_runtime_projection_cache,
		trusted_runtime_projection_read_only,
	)
	if (
		trusted_runtime_projection_read_only
		and not _runtime_tick_snapshot_cache.is_empty()
		and _runtime_tick_snapshot_cache_day == day
		and _runtime_tick_snapshot_cache_phase == shift_phase
	):
		cost_probe.finish(&"snapshot_projections", stage_started)
		_runtime_tick_snapshot_cache_hits += 1
		var refreshed := _refresh_runtime_tick_snapshot(
			_runtime_tick_snapshot_cache,
			worker_snapshots,
			queue_snapshot,
			pending_rework_items,
			runtime_projections,
		)
		cost_probe.finish(&"snapshot_cached", probe_started)
		return refreshed
	var personnel_status := personnel_action_status()
	var campus_expansion_projection := (
		runtime_projections.get("campus_expansion", {}) as Dictionary
	)
	var campus_portfolio_projection := (
		runtime_projections.get("campus_portfolio", {}) as Dictionary
	)
	var current_facility_effects := facility_effects()
	var result := {
		# Consumers can use this monotonic tick revision to recognize accelerated
		# simulation updates without parsing the full presentation payload. It is
		# deliberately distinct from action/event revisions, which may change
		# authoritative state between ticks.
		"authoritative_tick_revision": _tick_count,
		"case_docket": case_docket_snapshot(),
		"incident_pivot_mastery": incident_pivot_mastery_snapshot(),
		"day": day,
		"minute_of_day": minute_of_day,
		"time_label": _format_time(minute_of_day),
		"claims_waiting": claims_waiting,
		"claims_outstanding": _outstanding_claim_count(),
		"claim_capacity": current_claim_capacity(),
		"claim_resolution_catalog": claim_resolution_catalog(),
		"intake_rejections_today": intake_rejections_today,
		"intake_rejections_total": intake_rejections_total,
		"intake_missed_value_today_cents": intake_missed_value_today_cents,
		"intake_missed_value_total_cents": intake_missed_value_total_cents,
		"contract_board": (
			runtime_projections.get("contract_board", {}) as Dictionary
		),
		"market_contract_breach_reserve_cents": current_market_contract_reserve_cents(),
		"market_contract_premium_today_cents": market_contract_premium_today_cents,
		"market_contract_premium_total_cents": market_contract_premium_total_cents,
		"market_contract_breach_today_cents": market_contract_breach_today_cents,
		"market_contract_breach_total_cents": market_contract_breach_total_cents,
		"market_contracts_signed_total": market_contracts_signed_total,
		"market_contracts_succeeded_total": market_contracts_succeeded_total,
		"market_contracts_breached_total": market_contracts_breached_total,
		"market_contract_standing": farm_mutual_standing(),
		"market_contract_standing_rank": farm_mutual_standing_rank(),
		"market_clean_contract_streak": market_clean_contract_streak,
		"best_market_clean_contract_streak": best_market_clean_contract_streak,
		"farm_mutual_standing": farm_mutual_standing_status(),
		"farm_mutual_service_coop": (
			runtime_projections.get("farm_mutual_service_coop", {}) as Dictionary
		),
		"farm_mutual_negotiation_room": (
			runtime_projections.get("farm_mutual_negotiation_room", {}) as Dictionary
		),
		"claims_processed": claims_processed,
		"eggs_today": eggs_today,
		"eggs_total": eggs_total,
		"cracked_eggs": cracked_eggs,
		"cracked_today": cracked_today,
		"golden_eggs": golden_eggs,
		"golden_today": golden_today,
		"revenue_cents": revenue_cents,
		"credited_today_cents": credited_today_cents,
		"farm_treasury": farm_treasury_snapshot(),
		"economic_briefing": (
			runtime_projections.get("economic_briefing", {}) as Dictionary
		),
		"daily_feed_cost_cents": current_daily_feed_cost_cents(),
		"feed_procurement": (
			runtime_projections.get("feed_procurement", {}) as Dictionary
		),
		"farmer_relations_gallery": farmer_relations_gallery_snapshot(),
		"farmgate_dispatch": farmgate_dispatch_snapshot(),
		"campus_expansion": campus_expansion_projection,
		"campus_portfolio": campus_portfolio_projection,
		"active_staff_count": active_staff,
		"office_capacity": office_capacity,
		"maximum_staff_capacity": MAXIMUM_STAFF_CAPACITY,
		"daily_hen_payroll_cents": current_daily_hen_payroll_cents(),
		"daily_supervisor_payroll_cents": current_daily_supervisor_payroll_cents(),
		"daily_fellow_payroll_cents": current_daily_fellow_payroll_cents(),
		"daily_payroll_cents": current_daily_payroll_cents(),
		"daily_facility_expansion_cost_cents": daily_facility_expansion_cost_cents(),
		"daily_facility_maintenance_cents": current_daily_facility_maintenance_cents(),
		"daily_facility_cost_cents": current_daily_facility_cost_cents(),
		"daily_operating_cost_cents": current_daily_operating_cost_cents(),
		"wage_arrears_cents": wage_arrears_cents,
		"protected_reserve_cents": protected_reserve_cents(),
		"spendable_fund_cents": spendable,
		"career_sponsorship_cost_cents": career_sponsorship_cost_cents(),
		"career_sponsorship_planning_open": shift_phase == ShiftPhase.REVIEW,
		"staffing_planning_open": staffing_planning_open(),
		"capacity_upgrade": capacity_upgrade_status(),
		"staffing_catalog": runtime_projections.get("staffing_catalog", []),
		"internship_program": internship_program_snapshot(),
		"owned_facilities": owned_facilities.duplicate(),
		"facility_catalog": runtime_projections.get("facility_catalog", []),
		"facility_effects": current_facility_effects,
		"pinned_capital_plan_id": pinned_capital_plan_id,
		"capital_plan": capital_plan_snapshot(),
		"last_facility_purchase_receipt": last_facility_purchase_receipt.duplicate(true),
		"facility_commissioning_history": facility_commissioning_history.duplicate(true),
		"flock_care": (
			runtime_projections.get("flock_care", {}) as Dictionary
		),
		"operations": (
			runtime_projections.get("operations", {}) as Dictionary
		),
		"flock_relations": flock_relations_snapshot(),
		"packing_contract": packing_contract_status(),
		"packing_carton_progress": packing_carton_progress,
		"packing_cartons_today": packing_cartons_today,
		"packing_cartons_total": packing_cartons_total,
		"packing_value_bonus_today_cents": packing_value_bonus_today_cents,
		"packing_carton_bonus_today_cents": packing_carton_bonus_today_cents,
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
		"peck_assist_limit": _peck_assist_charge_limit(),
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
		"routing_momentum": routing_momentum_snapshot(),
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
		"incident_responses_today": incident_responses_for_day(day),
		"decision_modifiers": {
			"work_multiplier": _directive_work_multiplier * _incident_work_multiplier * _work_to_rule_work_multiplier() * _playbook_work_multiplier(),
			"fatigue_multiplier": _directive_fatigue_multiplier * _incident_strain_multiplier * float(_feed_procurement.active_strain_basis_points) / 10_000.0 * _playbook_strain_multiplier(),
			"stress_multiplier": _directive_stress_multiplier * _incident_strain_multiplier * float(_feed_procurement.active_strain_basis_points) / 10_000.0 * _playbook_strain_multiplier(),
			"feed_strain_basis_points": _feed_procurement.active_strain_basis_points,
			"morale_drain_multiplier": _directive_morale_drain_multiplier,
			"crack_modifier": (
				_directive_crack_modifier
				+ _incident_crack_modifier
				+ _work_to_rule_crack_modifier()
				+ float(current_facility_effects.get("crack_modifier", 0.0))
				+ _playbook_crack_modifier()
			),
			"playbook_work_multiplier": _playbook_work_multiplier(),
			"playbook_crack_modifier": _playbook_crack_modifier(),
			"playbook_strain_multiplier": _playbook_strain_multiplier(),
			"facility_crack_modifier": float(current_facility_effects.get("crack_modifier", 0.0)),
			"facility_rework_speed_multiplier": float(current_facility_effects.get("rework_speed_multiplier", 1.0)),
			"work_to_rule_work_multiplier": _work_to_rule_work_multiplier(),
			"work_to_rule_crack_modifier": _work_to_rule_crack_modifier(),
			"golden_modifier": _incident_golden_modifier,
			"daily_feed_adjustment_cents": _daily_feed_adjustment_cents,
			"quota_adjustment": _pending_quota_adjustment,
		},
		"upgrade_levels": upgrade_levels.duplicate(),
		"upgrade_catalog": upgrade_catalog(),
		"first_clutch_reinvestment": first_clutch_reinvestment_status(),
		"active_playbook": playbook_snapshot(),
		"requisition_spend_today_cents": requisition_spend_today_cents,
		"requisition_spend_total_cents": requisition_spend_total_cents,
		"orientation_procurement_match_today_cents": orientation_procurement_match_today_cents,
		"orientation_procurement_match_total_cents": orientation_procurement_match_total_cents,
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
	if trusted_runtime_projection_read_only:
		# The clock's Office consumer treats this read model as immutable, so it
		# may become the next tick base without another whole-graph allocation.
		_runtime_tick_snapshot_cache = result
		_runtime_tick_snapshot_cache_day = day
		_runtime_tick_snapshot_cache_phase = shift_phase
	else:
		# Public/direct snapshot callers retain the historical right to enrich
		# their returned dictionaries. Never let their object graph alias the
		# trusted clock cache; rebuild that cache once on the next clock publish.
		# Release our cache reference without erasing a read model that signal
		# listeners may still be presenting during this nested snapshot request.
		_runtime_tick_snapshot_cache = {}
		_runtime_tick_snapshot_cache_day = -1
		_runtime_tick_snapshot_cache_phase = -1
	cost_probe.finish(&"snapshot_runtime" if use_runtime_projection_cache else &"snapshot_exact", probe_started)
	return result


func _refresh_runtime_tick_snapshot(
	base_snapshot: Dictionary,
	worker_snapshots: Array[Dictionary],
	queue_snapshot: Dictionary,
	pending_rework_items: Array[Dictionary],
	runtime_projections: Dictionary,
) -> Dictionary:
	# Ordinary clock ticks cannot buy facilities, hire staff, change policy, or
	# rewrite historical ledgers. Start from the last complete read model and
	# refresh every field that can change through production, arrivals, incidents,
	# contracts, or the clock itself. The shallow copy keeps cached nested
	# projections immutable while avoiding a second full economic graph build.
	var result := base_snapshot.duplicate()
	var current_facility_effects := facility_effects()
	var active_staff := active_worker_count()
	var spendable := spendable_fund_cents()
	var assist_delivery_status := peck_assist_delivery_status()
	result["authoritative_tick_revision"] = _tick_count
	result["case_docket"] = case_docket_snapshot()
	result["day"] = day
	result["minute_of_day"] = minute_of_day
	result["time_label"] = _format_time(minute_of_day)
	result["claims_waiting"] = claims_waiting
	result["claims_outstanding"] = _outstanding_claim_count()
	result["claim_capacity"] = current_claim_capacity()
	result["intake_rejections_today"] = intake_rejections_today
	result["intake_rejections_total"] = intake_rejections_total
	result["intake_missed_value_today_cents"] = intake_missed_value_today_cents
	result["intake_missed_value_total_cents"] = intake_missed_value_total_cents
	result["contract_board"] = runtime_projections.get("contract_board", {})
	result["market_contract_breach_reserve_cents"] = current_market_contract_reserve_cents()
	result["market_contract_premium_today_cents"] = market_contract_premium_today_cents
	result["market_contract_premium_total_cents"] = market_contract_premium_total_cents
	result["market_contract_breach_today_cents"] = market_contract_breach_today_cents
	result["market_contract_breach_total_cents"] = market_contract_breach_total_cents
	result["market_contracts_signed_total"] = market_contracts_signed_total
	result["market_contracts_succeeded_total"] = market_contracts_succeeded_total
	result["market_contracts_breached_total"] = market_contracts_breached_total
	result["market_contract_standing"] = farm_mutual_standing()
	result["market_contract_standing_rank"] = farm_mutual_standing_rank()
	result["market_clean_contract_streak"] = market_clean_contract_streak
	result["best_market_clean_contract_streak"] = best_market_clean_contract_streak
	result["farm_mutual_standing"] = farm_mutual_standing_status()
	result["farm_mutual_service_coop"] = runtime_projections.get("farm_mutual_service_coop", {})
	result["farm_mutual_negotiation_room"] = runtime_projections.get("farm_mutual_negotiation_room", {})
	result["claims_processed"] = claims_processed
	result["eggs_today"] = eggs_today
	result["eggs_total"] = eggs_total
	result["cracked_eggs"] = cracked_eggs
	result["cracked_today"] = cracked_today
	result["golden_eggs"] = golden_eggs
	result["golden_today"] = golden_today
	result["revenue_cents"] = revenue_cents
	result["credited_today_cents"] = credited_today_cents
	result["farm_treasury"] = farm_treasury_snapshot()
	result["economic_briefing"] = runtime_projections.get("economic_briefing", {})
	result["daily_feed_cost_cents"] = current_daily_feed_cost_cents()
	result["feed_procurement"] = runtime_projections.get("feed_procurement", {})
	result["flock_care"] = runtime_projections.get("flock_care", {})
	result["operations"] = runtime_projections.get("operations", {})
	result["flock_relations"] = flock_relations_snapshot()
	result["active_staff_count"] = active_staff
	result["daily_hen_payroll_cents"] = current_daily_hen_payroll_cents()
	result["daily_supervisor_payroll_cents"] = current_daily_supervisor_payroll_cents()
	result["daily_fellow_payroll_cents"] = current_daily_fellow_payroll_cents()
	result["daily_payroll_cents"] = current_daily_payroll_cents()
	result["daily_facility_expansion_cost_cents"] = daily_facility_expansion_cost_cents()
	result["daily_facility_maintenance_cents"] = current_daily_facility_maintenance_cents()
	result["daily_facility_cost_cents"] = current_daily_facility_cost_cents()
	result["daily_operating_cost_cents"] = current_daily_operating_cost_cents()
	result["wage_arrears_cents"] = wage_arrears_cents
	result["protected_reserve_cents"] = protected_reserve_cents()
	result["spendable_fund_cents"] = spendable
	result["packing_contract"] = packing_contract_status()
	result["packing_carton_progress"] = packing_carton_progress
	result["packing_cartons_today"] = packing_cartons_today
	result["packing_cartons_total"] = packing_cartons_total
	result["packing_value_bonus_today_cents"] = packing_value_bonus_today_cents
	result["packing_carton_bonus_today_cents"] = packing_carton_bonus_today_cents
	result["pecking_order"] = current_pecking_order()
	result["peck_assists_used_today"] = peck_assists_used_today
	result["peck_assists_remaining"] = _peck_assist_charges_available()
	result["peck_assist_charges"] = _peck_assist_charges_available()
	result["peck_assist_interventions_today"] = peck_assist_interventions_today
	result["peck_assist_gross_interventions"] = peck_assist_interventions_today
	result["peck_assist_refunds_today"] = peck_assist_refunds_today
	result["peck_assist_pending_delivery"] = (
		assist_delivery_status.get("pending_delivery", {}) as Dictionary
	).duplicate(true)
	result["peck_assist_pending_delivery_count"] = int(
		assist_delivery_status.get("pending_delivery_count", 0)
	)
	result["peck_assist_pending_deliveries"] = (
		assist_delivery_status.get("pending_deliveries", []) as Array
	).duplicate(true)
	result["peck_assist_delivery_reason"] = String(assist_delivery_status.get("reason", ""))
	result["peck_assist_streak"] = peck_assist_streak
	result["best_peck_assist_streak"] = best_peck_assist_streak
	result["last_peck_assist"] = last_peck_assist.duplicate(true)
	result["last_peck_assist_delivery"] = last_peck_assist_delivery.duplicate(true)
	result["priority_credit_today_cents"] = priority_credit_today_cents
	result["priority_credit_total_cents"] = priority_credit_total_cents
	result["routing_momentum"] = routing_momentum_snapshot()
	result["quota_target"] = quota_target
	result["executive_confidence"] = executive_confidence
	result["compliance"] = compliance
	result["solidarity"] = solidarity
	result["overtime_enabled"] = overtime_enabled
	result["feed_party_used_today"] = feed_party_used_today
	result["quality_streak"] = quality_streak
	result["best_quality_streak"] = best_quality_streak
	result["last_streak_bonus_cents"] = last_streak_bonus_cents
	result["shift_phase"] = shift_phase
	result["shift_phase_label"] = phase_label()
	result["pending_decision"] = pending_decision_snapshot()
	result["credit_memo_pending"] = (
		StringName(pending_decision.get("kind", &""))
		in [&"credit_allocation", &"major_event"]
	)
	result["credit_memo_id"] = StringName(pending_decision.get("id", &""))
	result["incidents_resolved_today"] = incidents_resolved_today
	result["incident_responses_today"] = incident_responses_for_day(day)
	result["decision_modifiers"] = {
		"work_multiplier": (
			_directive_work_multiplier
			* _incident_work_multiplier
			* _work_to_rule_work_multiplier()
			* _playbook_work_multiplier()
		),
		"fatigue_multiplier": (
			_directive_fatigue_multiplier
			* _incident_strain_multiplier
			* float(_feed_procurement.active_strain_basis_points)
			/ 10_000.0
			* _playbook_strain_multiplier()
		),
		"stress_multiplier": (
			_directive_stress_multiplier
			* _incident_strain_multiplier
			* float(_feed_procurement.active_strain_basis_points)
			/ 10_000.0
			* _playbook_strain_multiplier()
		),
		"feed_strain_basis_points": _feed_procurement.active_strain_basis_points,
		"morale_drain_multiplier": _directive_morale_drain_multiplier,
		"crack_modifier": (
			_directive_crack_modifier
			+ _incident_crack_modifier
			+ _work_to_rule_crack_modifier()
			+ float(current_facility_effects.get("crack_modifier", 0.0))
			+ _playbook_crack_modifier()
		),
		"playbook_work_multiplier": _playbook_work_multiplier(),
		"playbook_crack_modifier": _playbook_crack_modifier(),
		"playbook_strain_multiplier": _playbook_strain_multiplier(),
		"facility_crack_modifier": float(
			current_facility_effects.get("crack_modifier", 0.0)
		),
		"facility_rework_speed_multiplier": float(
			current_facility_effects.get("rework_speed_multiplier", 1.0)
		),
		"work_to_rule_work_multiplier": _work_to_rule_work_multiplier(),
		"work_to_rule_crack_modifier": _work_to_rule_crack_modifier(),
		"golden_modifier": _incident_golden_modifier,
		"daily_feed_adjustment_cents": _daily_feed_adjustment_cents,
		"quota_adjustment": _pending_quota_adjustment,
	}
	result["first_clutch_reinvestment"] = first_clutch_reinvestment_status()
	result["active_playbook"] = playbook_snapshot()
	result["requisition_spend_today_cents"] = requisition_spend_today_cents
	result["requisition_spend_total_cents"] = requisition_spend_total_cents
	result["orientation_procurement_match_today_cents"] = orientation_procurement_match_today_cents
	result["orientation_procurement_match_total_cents"] = orientation_procurement_match_total_cents
	result["claim_queue_counts"] = (queue_snapshot["counts"] as Dictionary).duplicate()
	result["claim_queue_items"] = (queue_snapshot["items"] as Dictionary).duplicate(true)
	result["claim_queue_overdue_counts"] = (
		queue_snapshot["overdue_counts"] as Dictionary
	).duplicate()
	result["queued_overdue_claims"] = _overdue_claim_count(false)
	result["overdue_claims"] = _overdue_claim_count(true)
	result["rework_waiting"] = _queued_rework_count()
	result["rework_in_progress"] = _active_rework_count()
	result["rework_due_next_shift"] = _pending_rework.size()
	result["rework_pending_items"] = pending_rework_items
	result["rework_total_created"] = _rework_total_created
	result["lane_processed_today"] = lane_processed_today.duplicate()
	result["lane_processed_totals"] = lane_processed_totals.duplicate()
	result["workers"] = worker_snapshots
	_runtime_tick_snapshot_cache = result
	return result


func _personnel_actions_for_day(target_day: int) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for worker in workers:
		if not worker.employed:
			continue
		if worker.last_personnel_action_day != target_day or worker.last_personnel_action == &"":
			continue
		var definition := PERSONNEL_ACTION_DEFINITIONS.get(worker.last_personnel_action, {}) as Dictionary
		if definition.is_empty():
			continue
		actions.append({
			"day": target_day,
			"action_serial": worker.last_personnel_action_serial,
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"action_id": worker.last_personnel_action,
			"action_name": String(definition.get("name", "PERSONNEL ACTION")),
			"cost_cents": int(definition.get("cost_cents", 0)),
			"preferred": _preferred_personnel_action(worker) == worker.last_personnel_action,
			"outcome": _personnel_action_outcome(worker, worker.last_personnel_action),
		})
	actions.sort_custom(func(left: Dictionary, right: Dictionary) -> bool:
		var left_serial := int(left.get("action_serial", 0))
		var right_serial := int(right.get("action_serial", 0))
		if left_serial == right_serial:
			return int(left.get("worker_id", 0)) < int(right.get("worker_id", 0))
		return left_serial < right_serial
	)
	return actions


func personnel_actions_for_day(target_day: int = -1) -> Array[Dictionary]:
	var effective_day := day if target_day < 0 else target_day
	return _personnel_actions_for_day(effective_day).duplicate(true)


func _personnel_action_for_day(target_day: int) -> Dictionary:
	var actions := _personnel_actions_for_day(target_day)
	return (
		(actions[actions.size() - 1] as Dictionary).duplicate(true)
		if not actions.is_empty() else
		{}
	)


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
	return relationship_multiplier * _effective_cross_training_work_multiplier(worker)


func _effective_cross_training_work_multiplier(worker: ChickenState) -> float:
	return pending_training_work_multiplier() if worker.cross_training_pending() else 1.0


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
					_bind_routing_golden_target()
		ChickenState.WorkState.WORKING:
			if not is_worker_at_workstation(worker.id):
				return
			var temperament_effect := _worker_temperament_effect(worker)
			var morale_factor := remap(clampf(worker.morale, 20.0, 100.0), 20.0, 100.0, 0.62, 1.1)
			var overtime_factor := 1.22 if overtime_enabled else 1.0
			var tool_factor := 1.0 + 0.08 * upgrade_level(&"peckwork_tools")
			var comfort_factor := maxf(0.50, 1.0 - 0.10 * upgrade_level(&"nest_cushion"))
			var decision_work_factor := (
				_directive_work_multiplier
				* _incident_work_multiplier
				* _work_to_rule_work_multiplier()
				* _playbook_work_multiplier()
			)
			var total_work_factor := clampf(overtime_factor * tool_factor * decision_work_factor, 0.55, 1.70)
			var decision_strain_factor := (
				_incident_strain_multiplier * _playbook_strain_multiplier()
			)
			var campaign_fatigue_factor := 0.90 if has_campaign_unlock(&"welfare_breaks") else 1.0
			var campaign_stress_factor := 0.88 if has_campaign_unlock(&"welfare_breaks") else 1.0
			var career_work_factor := _career_relationship_work_multiplier(worker)
			var routing_pace_factor := (
				ROUTING_MOMENTUM_PACE_MULTIPLIER
				if routing_momentum_chain >= ROUTING_MOMENTUM_PACE_MILESTONE
				and worker.manually_routed
				and worker.current_claim != null
				and worker.has_specialty(worker.current_claim.lane) else
				1.0
			)
			# The opening file is a comprehension beat: it reaches a visible payoff
			# quickly enough for a first-session player to connect route -> work -> egg.
			# This disappears permanently after the first career delivery.
			var first_payoff_factor := 1.35 if _guided_first_payoff_active() else 1.0
			var career_strain_factor := _career_strain_multiplier(worker)
			var wellness_strain_factor := wellness_strain_gain_multiplier()
			var feed_strain_factor := (
				float(_feed_procurement.active_strain_basis_points) / 10_000.0
			)
			var progress_before_tick := worker.work_progress
			worker.work_progress += (
				BASE_WORK_PROGRESS
				* worker.skill
				* morale_factor
				* total_work_factor
				* _claim_speed_factor(worker)
				* _claim_resolution_work_multiplier(worker.current_claim)
				* _facility_claim_speed_multiplier(worker)
				* automation_work_multiplier(worker)
				* career_work_factor
				* routing_pace_factor
				* first_payoff_factor
				* float(temperament_effect.get("work_multiplier", 1.0))
				* float(_manager_effect_for_worker(worker).get("work_multiplier", 1.0))
				* _internship_program.work_multiplier()
			)
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
				_break_routing_momentum(
					"The Priority Peck window was missed.",
					&"peck_missed",
					worker.id,
					missed_claim_id,
				)
				peck_assist_missed.emit(worker.id, missed_claim_id)
			var temperament_strain_factor := float(
				temperament_effect.get("strain_multiplier", 1.0)
			)
			var claim_lane_stress_factor := _claim_lane_stress_multiplier(
				worker.current_claim,
			)
			worker.fatigue = minf(100.0, worker.fatigue + (0.65 if overtime_enabled else 0.36) * comfort_factor * _directive_fatigue_multiplier * decision_strain_factor * campaign_fatigue_factor * wellness_strain_factor * feed_strain_factor * temperament_strain_factor)
			worker.stress = minf(100.0, worker.stress + (0.40 if overtime_enabled else 0.2) * comfort_factor * _directive_stress_multiplier * decision_strain_factor * campaign_stress_factor * career_strain_factor * wellness_strain_factor * feed_strain_factor * temperament_strain_factor * claim_lane_stress_factor)
			worker.morale = maxf(
				0.0,
				worker.morale
					- (0.18 if overtime_enabled else 0.07)
					* _directive_morale_drain_multiplier
					* _internship_program.morale_drain_multiplier(),
			)
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
			var break_recovery_factor := (
				wellness_break_recovery_multiplier()
				* float(_worker_temperament_effect(worker).get(
					"break_recovery_multiplier",
					1.0,
				))
			)
			worker.fatigue = maxf(0.0, worker.fatigue - 2.0 * break_recovery_factor)
			worker.stress = maxf(0.0, worker.stress - 1.4 * break_recovery_factor)
			worker.morale = minf(
				100.0,
				worker.morale + float(wellness_break_morale_millipoints()) / 1000.0,
			)
			if worker.state_ticks_remaining <= 0:
				worker.work_state = ChickenState.WorkState.IDLE

	if worker.fatigue >= 78.0 and worker.work_state == ChickenState.WorkState.IDLE:
		worker.work_state = ChickenState.WorkState.BREAK
		worker.state_ticks_remaining = 10


func _error_risk_for(worker: ChickenState) -> float:
	if career_workshop.daily_day == day and worker.current_claim != null and worker.current_claim.id in career_workshop.protected_claims:
		return 0.0
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
	error_risk += float(facility_effects().get("crack_modifier", 0.0))
	error_risk += _directive_crack_modifier + _incident_crack_modifier + _work_to_rule_crack_modifier()
	error_risk += _playbook_crack_modifier()
	error_risk += _career_relationship_crack_modifier(worker)
	error_risk += _personnel_shift_crack_modifier(worker)
	error_risk += float(_worker_temperament_effect(worker).get("crack_modifier", 0.0))
	error_risk += float(_manager_effect_for_worker(worker).get("crack_modifier", 0.0))
	error_risk += _internship_program.crack_modifier()
	if worker.current_claim != null:
		error_risk += worker.current_claim.base_crack_risk
		error_risk += _claim_affinity_crack_modifier(worker)
		error_risk += _claim_resolution_crack_modifier(worker.current_claim)
		error_risk += float(_assist_quality_modifiers.get(worker.current_claim.id, 0.0))
	return clampf(error_risk, 0.02, 0.92)


func _guided_first_payoff_active() -> bool:
	## The assist belongs to the explicit first-session plan, not every new
	## simulation. Keeping unplanned/headless campaigns on the authored economy
	## preserves seeded balance outcomes and makes filing a plan meaningful.
	return (
		eggs_total == 0
		and (
			not String(active_playbook.get("strategy_preset_id", "")).is_empty()
			or not String(active_playbook.get("loadout_id", "")).is_empty()
		)
	)


func _apply_claim_lane_outcome(
	claim: ClaimState,
	worker: ChickenState,
	quality: StringName,
) -> void:
	if claim == null or not claim.resolution_locked:
		return
	var definition := CLAIM_LANE_DEFINITIONS.get(claim.lane, {}) as Dictionary
	if quality == &"cracked":
		compliance = clampf(
			compliance + float(definition.get(
				"cracked_compliance_millipoints",
				0,
			)) / 1000.0,
			0.0,
			100.0,
		)
		return
	worker.morale = clampf(
		worker.morale + float(definition.get(
			"sound_morale_millipoints",
			0,
		)) / 1000.0,
		0.0,
		100.0,
	)
	compliance = clampf(
		compliance + float(definition.get(
			"sound_compliance_millipoints",
			0,
		)) / 1000.0,
		0.0,
		100.0,
	)


func _apply_claim_resolution_outcome(
	claim: ClaimState,
	worker: ChickenState,
	quality: StringName,
) -> void:
	if claim == null or not claim.resolution_locked:
		return
	match claim.resolution_path:
		&"settle":
			if quality != &"cracked":
				compliance = minf(100.0, compliance + 0.6)
				worker.manager_trust = minf(100.0, worker.manager_trust + 0.6)
				worker.morale = minf(100.0, worker.morale + 0.4)
		&"exception":
			if quality != &"cracked":
				compliance = minf(100.0, compliance + 1.0)
				worker.manager_trust = minf(100.0, worker.manager_trust + 0.4)
		&"deny":
			compliance = maxf(0.0, compliance - 1.0)
			executive_confidence = minf(100.0, executive_confidence + 0.5)
			worker.stress = minf(100.0, worker.stress + 0.7)
			worker.grievance = minf(100.0, worker.grievance + 0.6)
			if quality != &"cracked":
				_schedule_claimant_appeal(claim)
				announcement_posted.emit(
					"DENIAL CONSEQUENCE: %s returns tomorrow as an appeal; the hen carries the pressure while the bureau counts today's closure." % String(
						claim.claimant_profile().get("name", "THE CLAIMANT"),
					)
				)


func _apply_workshop_peck(worker: ChickenState, claim_id: int, rating: StringName = &"strong") -> String:
	var effect := ""
	var precision := career_workshop.tuning == "precision"
	var protection_limit := 3 if precision else 2
	if career_workshop.equipped == "relay_bell" and career_workshop.tuning == "sprint" and career_workshop.uses < 3:
		worker.work_progress = minf(99.0, worker.work_progress + 10.0)
		worker.stress = minf(100.0, worker.stress + 3.0)
		career_workshop.uses += 1
		effect = "SPRINT: +10 WORK / +3 STRESS · %d LEFT" % (3 - career_workshop.uses)
	elif career_workshop.equipped == "relay_bell" and career_workshop.tuning == "handoff":
		var previous_id := career_workshop.previous_peck_worker
		if previous_id >= 0 and previous_id != worker.id and career_workshop.uses < 3:
			var previous := workers[previous_id]
			if previous.employed and previous.current_claim != null and previous.work_state == ChickenState.WorkState.WORKING:
				previous.work_progress = minf(99.0, previous.work_progress + 18.0)
				career_workshop.uses += 1
				effect = "HANDOFF: %s +18 WORK · %d LEFT" % [previous.display_name.to_upper(), 3 - career_workshop.uses]
		career_workshop.previous_peck_worker = worker.id
	elif career_workshop.equipped == "shell_guard" and career_workshop.tuning == "triage":
		var minutes_left := worker.current_claim.deadline_operational_minute - _current_operational_minute()
		if career_workshop.uses < 2 and minutes_left >= 0 and minutes_left <= 60:
			career_workshop.protected_claims.append(claim_id)
			career_workshop.uses += 1
			worker.work_progress = minf(99.0, worker.work_progress + 15.0)
			effect = "TRIAGE: +15 WORK / EGG PROTECTED · %d LEFT" % (2 - career_workshop.uses)
		elif career_workshop.uses < 2:
			effect = "TRIAGE: FINAL-HOUR FILE NEEDED · CHARGE KEPT"
	elif career_workshop.equipped == "shell_guard" and career_workshop.uses < protection_limit and (not precision or rating == &"perfect"):
		career_workshop.protected_claims.append(claim_id)
		career_workshop.uses += 1
		effect = "LENS: EGG PROTECTED · %d LEFT" % (protection_limit - career_workshop.uses)
	elif career_workshop.equipped == "shell_guard" and precision and rating != &"perfect" and career_workshop.uses < protection_limit:
		effect = "PRECISION LENS: PERFECT NEEDED · CHARGE KEPT"
	elif career_workshop.equipped == "team_kettle":
		var previous_id := career_workshop.previous_peck_worker
		if previous_id >= 0 and previous_id != worker.id and career_workshop.uses < 3 and workers[previous_id].employed:
			var previous := workers[previous_id]
			if career_workshop.tuning == "mentor":
				previous.add_career_xp(6)
			else:
				for teammate in [previous, worker]:
					teammate.stress = maxf(0.0, teammate.stress - (8.0 if career_workshop.tuning == "encourage" else 4.0))
					teammate.fatigue = maxf(0.0, teammate.fatigue - (8.0 if career_workshop.tuning == "encourage" else 4.0))
				if career_workshop.tuning != "encourage" and previous.current_claim != null and previous.work_state == ChickenState.WorkState.WORKING:
					previous.work_progress = minf(99.0, previous.work_progress + 10.0)
			career_workshop.uses += 1
			for teammate_id in [previous_id, worker.id]:
				if teammate_id not in career_workshop.relief_workers:
					career_workshop.relief_workers.append(teammate_id)
			flock_relationships.record(previous_id, worker.id, "relay_care", day)
			_award_clean_pair(worker, previous)
			effect = "MENTOR: %s +6 XP · RELAY %d/3" % [previous.display_name.to_upper(), career_workshop.uses] if career_workshop.tuning == "mentor" else "KETTLE: TEAM RECOVERY · RELAY %d/3" % career_workshop.uses
			if career_workshop.tuning == "encourage":
				effect = "ENCOURAGE: BOTH HENS -8 STRESS / FATIGUE · RELAY %d/3" % career_workshop.uses
		career_workshop.previous_peck_worker = worker.id
	return effect


func _complete_egg(worker: ChickenState) -> void:
	var completed_claim := worker.current_claim
	var error_risk := _error_risk_for(worker)
	if completed_claim != null and completed_claim.id in career_workshop.protected_claims:
		error_risk = 0.0
		career_workshop.protected_claims.erase(completed_claim.id)
	# Never turn the first career payoff into a punishment. Later files use the
	# full authored economy, including visible quality risk and rework.
	if _guided_first_payoff_active():
		error_risk = 0.0
	var assisted_claim_id := completed_claim.id if completed_claim != null else -1
	var was_assisted := assisted_claim_id > 0 and _assisted_claim_ids.has(assisted_claim_id)
	var assist_chain := int(_assist_chain_by_claim_id.get(assisted_claim_id, 0))
	var routing_golden_targeted := (
		assisted_claim_id >= 0
		and assisted_claim_id == routing_momentum_golden_target_claim_id
		and worker.id == routing_momentum_golden_target_worker_id
	)

	var roll := _rng.randf()
	var quality: StringName = &"sound"
	var routing_golden_applied := false
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
		if routing_golden_targeted:
			# A crack is not an eligible clean delivery. Keep the earned charge and
			# release the seal so another live file can receive it authoritatively.
			_release_routing_golden_target()
	else:
		if routing_golden_targeted and routing_momentum_golden_charges > 0:
			routing_momentum_golden_charges -= 1
			routing_golden_applied = true
			quality = &"golden"
			value_cents = base_value_cents * 4
			golden_eggs += 1
			golden_today += 1
			executive_confidence = minf(100.0, executive_confidence + 1.5)
			announcement_posted.emit(
				"GOLDEN FILE: sealed file #%04d reached grading clean for %s." % [
					assisted_claim_id,
					worker.display_name,
				]
			)
			_release_routing_golden_target()
		else:
			var golden_chance := clampf(0.025 + maxf(0.0, worker.morale - 70.0) * 0.0005 + _incident_golden_modifier, 0.025, 0.08)
			if _rng.randf() < golden_chance:
				quality = &"golden"
				value_cents = base_value_cents * 4
				golden_eggs += 1
				golden_today += 1
				executive_confidence = minf(100.0, executive_confidence + 1.5)
	if completed_claim != null:
		_apply_claim_lane_outcome(completed_claim, worker, quality)
		_apply_claim_resolution_outcome(completed_claim, worker, quality)
		_record_market_contract_completion(completed_claim, quality)
	var packing_receipt := _apply_packing_contract_value(quality, value_cents)
	value_cents = int(packing_receipt.get("value_cents", value_cents))
	if has_campaign_unlock(&"farmer_credit_bonus"):
		value_cents += 25
	if quality in [&"sound", &"golden"]:
		value_cents += _campus_portfolio.good_egg_bonus_cents(_campus_portfolio_context())
	if (
		quality in [&"sound", &"golden"]
		and StringName(active_playbook.get("push_luck_id", &"")) == &"chase_premium"
		and eggs_today >= int(active_playbook.get("push_luck_start_eggs", eggs_today + 1))
	):
		value_cents = roundi(float(value_cents) * 1.15)
	if (
		quality in [&"sound", &"golden"]
		and StringName(active_playbook.get("challenge_modifier_id", &"")) == &"glass_carton"
	):
		value_cents = roundi(float(value_cents) * 1.20)
	var priority_credit_cents := 0
	if quality != &"cracked" and assist_chain > 0:
		priority_credit_cents = 20 * mini(assist_chain, 5)
		value_cents += priority_credit_cents
		priority_credit_today_cents += priority_credit_cents
		priority_credit_total_cents += priority_credit_cents
		announcement_posted.emit(
			"PRIORITY CREDIT: management added $%.2f to %s's finished file." % [
				float(priority_credit_cents) / 100.0, worker.display_name,
			]
		)
	if was_assisted:
		if quality == &"cracked":
			# A cracked shell consumes the intervention permanently. It never mints
			# a delivery token, and it breaks the live chain even when other claims
			# are still moving through the office.
			peck_assist_streak = 0
			_break_routing_momentum(
				"An assisted file cracked at grading.",
				&"assisted_crack",
				worker.id,
				assisted_claim_id,
			)
			announcement_posted.emit(
				"PRIORITY PECK CHAIN BROKEN: file #%04d cracked and cannot restore attention." % assisted_claim_id
			)
		elif (
			quality in [&"sound", &"golden"]
			and not _routing_momentum_free_assist_claim_ids.has(assisted_claim_id)
		):
			# Claim ids are monotonic, so this token is both the presentation handoff
			# and the durable exact-once idempotency key.
			_pending_peck_assist_deliveries[assisted_claim_id] = {
				"day": day,
				"claim_id": assisted_claim_id,
				"worker_id": worker.id,
				"quality": String(quality),
			}

	last_streak_bonus_cents = 0
	career_workshop.record_egg(day, worker.id, quality != &"cracked", was_assisted, String(completed_claim.lane) if completed_claim != null else "", completed_claim.id if completed_claim != null else -1, completed_claim != null and not completed_claim.is_overdue(_current_operational_minute()))
	if quality != &"cracked":
		# Symmetric neighbours: either hen may finish first, including the
		# middle perch with a coworker on each side. Each pair earns once/day.
		flock_relationships.record_clean(worker.id, -1, day)
		for coworker in workers:
			if coworker.employed and coworker.id != worker.id:
				if absi(coworker.desk_index - worker.desk_index) == 1:
					flock_relationships.record_clean(worker.id, coworker.id, day)
				_award_clean_pair(worker, coworker)
	_record_playbook_contract_completion()
	if quality == &"cracked":
		quality_streak = 0
	else:
		quality_streak += 1
		_record_playbook_contract_completion()
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
		_routing_momentum_free_assist_claim_ids.erase(completed_claim.id)
	worker.current_claim = null
	worker.work_progress = 0.0
	worker.work_state = ChickenState.WorkState.IDLE
	_bind_routing_golden_target()
	claims_processed += 1
	eggs_today += 1
	eggs_total += 1
	var deferred_to_farmgate := (
		facility_level(FARMGATE_DISPATCH_DEPOT_ID) > 0
		and quality in [&"sound", &"golden"]
	)
	if deferred_to_farmgate:
		var lot_receipt := _store_farmgate_lot_with_campus_capacity(
			assisted_claim_id,
			day,
			worker.id,
			worker.display_name,
			quality,
			value_cents,
			facility_level(FARMGATE_DISPATCH_DEPOT_ID),
			_farmgate_shelf_life_shifts(),
		)
		if bool(lot_receipt.get("accepted", false)):
			var overflow_cash := int(lot_receipt.get("cash_delta_cents", 0))
			if overflow_cash > 0:
				revenue_cents += overflow_cash
				credited_today_cents += overflow_cash
		else:
			# A malformed ledger write must never destroy earned value in a live shift.
			push_error("Completed egg could not enter the Farmgate ledger; falling back to immediate farmer pickup.")
			revenue_cents += value_cents
			credited_today_cents += value_cents
	else:
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
	if routing_golden_applied:
		last_routing_dispatch["golden_claim_id"] = assisted_claim_id


func _worker_welfare_score(worker: ChickenState) -> int:
	var morale := roundi(worker.morale)
	var stress := roundi(worker.stress)
	var fatigue := roundi(worker.fatigue)
	return clampi(
		morale + 20 - roundi(float(stress) / 3.0) - roundi(float(fatigue) / 5.0),
		0,
		100,
	)


func flock_welfare_score() -> int:
	var active_count := active_worker_count()
	if active_count == 0:
		return 0
	var total := 0
	for worker in workers:
		if not worker.employed:
			continue
		total += _worker_welfare_score(worker)
	return roundi(float(total) / float(active_count))


func _flock_welfare_score() -> int:
	return flock_welfare_score()


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


func _settle_manager_careers(completed_day: int, met_quota: bool) -> Array[Dictionary]:
	var receipts: Array[Dictionary] = []
	if facility_level(ROOSTER_OPERATIONS_OFFICE_ID) <= 0:
		return receipts
	for manager in manager_roster:
		var influence_before := maxi(0, int(manager.get("influence", 0)))
		var rank_before := clampi(int(manager.get("rank", 0)), 0, MANAGER_RANK_TITLES.size() - 1)
		var assigned_sound := 0
		var assigned_eggs := 0
		var lowest_worker_id := -1
		var lowest_eggs := 1_000_000
		for worker in workers:
			if not _manager_targets_worker(manager, worker):
				continue
			var stats := _worker_shift_stat(worker.id)
			var worker_eggs := int(stats.get("eggs", 0))
			assigned_eggs += worker_eggs
			assigned_sound += int(stats.get("sound", 0)) + int(stats.get("golden", 0))
			if worker_eggs < lowest_eggs:
				lowest_eggs = worker_eggs
				lowest_worker_id = worker.id
		var posture_id := StringName(String(manager.get("posture_id", "coach")))
		var claimed_credit := assigned_sound + (2 if posture_id == &"visibility" else 0)
		var influence_gain := maxi(1, assigned_sound / 2) + (2 if met_quota else 0)
		manager["credit_claims"] = maxi(0, int(manager.get("credit_claims", 0))) + claimed_credit
		manager["influence"] = influence_before + influence_gain
		manager["rank"] = _manager_rank_for_influence(int(manager["influence"]))
		var pip_worker_id := -1
		if (
			not met_quota
			and lowest_worker_id >= 0
			and bool(manager.get("posture_filed", false))
			and posture_id in [&"chase_quota", &"audit", &"visibility"]
		):
			pip_worker_id = lowest_worker_id
			manager["last_pip_worker_id"] = pip_worker_id
			var scapegoat := workers[pip_worker_id]
			scapegoat.manager_trust = maxf(0.0, scapegoat.manager_trust - 2.0)
			scapegoat.grievance = minf(100.0, scapegoat.grievance + 3.0)
		receipts.append({
			"day": completed_day,
			"manager_id": StringName(String(manager.get("id", ""))),
			"manager_name": _manager_display_name(manager),
			"assigned_eggs": assigned_eggs,
			"credit_claimed": claimed_credit,
			"influence_before": influence_before,
			"influence_after": int(manager["influence"]),
			"rank_before": rank_before,
			"rank_after": int(manager["rank"]),
			"promoted": int(manager["rank"]) > rank_before,
			"pip_worker_id": pip_worker_id,
		})
	return receipts


func _complete_workday() -> void:
	# Normal play consumes at directive resolution. This idempotent close call also
	# protects test/admin fast-forwards and reconciles any late demand adjustment.
	_consume_feed_for_shift()
	var completed_day := day
	var completed_eggs := eggs_today
	var completed_quota := quota_target
	var completed_cracked := cracked_today
	var completed_golden := golden_today
	var completed_priority_credit_cents := priority_credit_today_cents
	var completed_directive := active_directive_snapshot()
	var completed_incidents := incidents_resolved_today
	var completed_incident_responses := incident_responses_for_day(completed_day)
	var completed_feed_cost := current_daily_feed_cost_cents()
	var completed_feed_procurement := feed_procurement_snapshot()
	var completed_feed_procurement_spend: int = int(
		_feed_procurement.procurement_spend_today_cents
	)
	var completed_feed_total_cash_spend: int = (
		completed_feed_procurement_spend + completed_feed_cost
	)
	var completed_facility_expansion_cost := daily_facility_expansion_cost_cents()
	var completed_facility_maintenance_cost := current_daily_facility_maintenance_cents()
	var completed_campus_services_cost := current_daily_campus_cost_cents()
	var completed_portfolio_operations_cost := current_daily_portfolio_cost_cents()
	var completed_facility_cost := current_daily_facility_cost_cents()
	var completed_owned_facilities := owned_facilities.duplicate()
	var completed_facility_effects := facility_effects()
	var completed_packing_contract := packing_contract_status()
	var completed_campus_portfolio := campus_portfolio_snapshot()
	var completed_intake_rejections := intake_rejections_today
	var completed_intake_rejections_total := intake_rejections_total
	var completed_intake_missed_value_cents := intake_missed_value_today_cents
	var completed_intake_missed_value_total_cents := intake_missed_value_total_cents
	var completed_first_clutch_reinvestment := first_clutch_reinvestment_status()
	var completed_active_playbook := playbook_snapshot()
	var completed_requisition_spend_cents := requisition_spend_today_cents
	var completed_orientation_match_cents := orientation_procurement_match_today_cents
	var completed_new_facility_unlocks: Array[Dictionary] = []
	for facility_id in FACILITY_ORDER:
		var facility_definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
		var facility_level_before_close := facility_level(facility_id)
		var facility_max_level := int(facility_definition.get("max_level", 1))
		var facility_next_level := mini(facility_max_level, facility_level_before_close + 1)
		if (
			facility_level_before_close < facility_max_level
			and _facility_unlock_day_for_level(
				facility_definition,
				facility_next_level,
			) == completed_day + 1
		):
			completed_new_facility_unlocks.append({
				"id": facility_id,
				"name": String(facility_definition.get("name", "CAPITAL FACILITY")),
				"short_name": String(facility_definition.get("short_name", "FACILITY")),
				"description": String(facility_definition.get("description", "")),
				"level": facility_next_level,
				"level_name": _facility_level_name(facility_definition, facility_next_level),
			})
	var completed_hen_payroll := current_daily_hen_payroll_cents()
	var completed_supervisor_payroll := current_daily_supervisor_payroll_cents()
	var completed_fellow_payroll := current_daily_fellow_payroll_cents()
	var completed_payroll := (
		completed_hen_payroll
		+ completed_supervisor_payroll
		+ completed_fellow_payroll
	)
	var completed_operations := operations_snapshot()
	var completed_career_sponsorships := _complete_career_sponsorships(completed_day)
	var opening_wage_arrears := wage_arrears_cents
	var completed_operating_cost := (
		completed_feed_cost + completed_facility_cost + completed_payroll
	)
	var completed_active_staff := active_worker_count()
	var completed_office_capacity := office_capacity
	var completed_quota_adjustment := _pending_quota_adjustment
	var completed_lane_processed: Dictionary = lane_processed_today.duplicate()
	var completed_personnel_actions := _personnel_actions_for_day(completed_day)
	var completed_personnel_action := (
		(completed_personnel_actions[completed_personnel_actions.size() - 1] as Dictionary).duplicate(true)
		if not completed_personnel_actions.is_empty() else
		{}
	)
	var completed_staffing_actions := _staffing_actions_for_day(completed_day)
	var completed_flock_petition: Dictionary = {}
	if int(last_flock_petition.get("day", 0)) == completed_day:
		completed_flock_petition = last_flock_petition.duplicate(true)
	var completed_pecking_order := current_pecking_order()
	last_pecking_order = completed_pecking_order.duplicate(true)
	last_pecking_order_day = completed_day
	var completed_overdue_claims := _overdue_claim_count(true)
	var completed_outstanding_claims := _outstanding_claim_count()
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

	var completed_market_contract := _settle_market_contract(completed_day)
	var completed_manager_careers := _settle_manager_careers(completed_day, met_quota)
	var completed_internship_transitions := _internship_program.complete_shift(completed_day)
	var completed_internship_program := internship_program_snapshot()
	var completed_farm_mutual_standing := farm_mutual_standing_status()
	var completed_farmgate_settlement: Dictionary = {}
	var completed_farmgate_shortfall_cents := 0
	if facility_level(FARMGATE_DISPATCH_DEPOT_ID) > 0:
		completed_farmgate_settlement = _farmgate_dispatch.settle(
			completed_day,
			facility_level(FARMGATE_DISPATCH_DEPOT_ID),
			_farmgate_dispatch_capacity_eggs(),
			int(_harvest_credit.public_standing),
		)
		if bool(completed_farmgate_settlement.get("accepted", false)):
			var farmgate_fund_before := revenue_cents
			var farmgate_cash_delta := int(
				completed_farmgate_settlement.get("settlement_cash_delta_cents", 0)
			)
			if farmgate_cash_delta < 0:
				completed_farmgate_shortfall_cents = maxi(
					0,
					-farmgate_cash_delta - farmgate_fund_before,
				)
			revenue_cents = maxi(
				0,
				farmgate_fund_before + farmgate_cash_delta,
			)
			credited_today_cents += maxi(
				0,
				int(completed_farmgate_settlement.get("payout_cents", 0)),
			)
			announcement_posted.emit(String(completed_farmgate_settlement.get("outcome", "Farmgate settlement closed.")))
	var completed_farmgate_dispatch := farmgate_dispatch_snapshot()
	var completed_credited_cents := credited_today_cents
	# Compact settlement can move cash and must therefore be inside the same exact
	# close journal rather than becoming an unfiled post-close mutation.
	var completed_flock_compact_receipt := _resolve_due_flock_compact(completed_day)
	if not _prepare_farm_treasury_close_day(completed_day):
		push_error("Farm Treasury chronology could not be prepared for day %d." % completed_day)
		return
	var treasury_breakdowns := _farm_treasury_close_breakdowns(
		revenue_cents,
		completed_credited_cents,
		completed_feed_cost,
		completed_facility_expansion_cost,
		completed_facility_maintenance_cost,
		completed_campus_services_cost,
		completed_portfolio_operations_cost,
		completed_farmgate_shortfall_cents,
	)
	var payroll_due_cents := opening_wage_arrears + completed_payroll
	var completed_farm_treasury_receipt: Dictionary = _farm_treasury.close_shift(
		completed_day,
		maxi(0, farm_mutual_standing()),
		treasury_breakdowns.get("income", {}) as Dictionary,
		treasury_breakdowns.get("vendors", {}) as Dictionary,
		payroll_due_cents,
	)
	if not bool(completed_farm_treasury_receipt.get("accepted", false)):
		push_error(
			"Farm Treasury rejected day %d close: %s"
			% [completed_day, String(completed_farm_treasury_receipt.get("reason", "unknown ledger error"))]
		)
		return
	revenue_cents = int(completed_farm_treasury_receipt.get("closing_cash_cents", 0))
	var payroll_paid_cents := int(completed_farm_treasury_receipt.get("labor_paid_cents", 0))
	wage_arrears_cents = int(completed_farm_treasury_receipt.get("labor_unpaid_cents", 0))
	var completed_farm_treasury := farm_treasury_snapshot()
	_announce_farm_treasury_close(completed_farm_treasury_receipt)
	if wage_arrears_cents > 0:
		_apply_wage_arrears_consequences()
		announcement_posted.emit(
			"PAYROLL EXCEPTION: $%.2f in flock and supervisor wages has been moved to a future promise." % (
				float(wage_arrears_cents) / 100.0
			)
		)
	var completed_work_to_rule := _finish_work_to_rule_day(completed_day)
	var completed_flock_relations_carry_effects := _apply_flock_relations_carry_penalties(
		completed_day
	)
	var completed_flock_relations_filings := _file_flock_relations_case_after_shift(completed_day)
	var completed_flock_relations := flock_relations_snapshot()
	var completed_welfare := _flock_welfare_score()
	var completed_flock_care := flock_care_snapshot()
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
	if routing_momentum_golden_target_claim_id >= 0:
		_release_routing_golden_target()
	day += 1
	_feed_procurement.begin_day(day)
	_farmgate_dispatch.begin_day(day)
	var portfolio_progress := _campus_portfolio.begin_day(day, _campus_portfolio_context())
	for completed_project_value: Variant in portfolio_progress.get("completed", []) as Array:
		if not completed_project_value is Dictionary:
			continue
		var completed_project := completed_project_value as Dictionary
		announcement_posted.emit(
			"CAMPUS BUILD COMPLETE: %s is ready for one named hen's operating assignment."
			% String(completed_project.get("module_id", "MODULE")).replace("_", " ").to_upper()
		)
	market_contract_decline_receipt.clear()
	for unlock in completed_new_facility_unlocks:
		announcement_posted.emit(
			"CAPITAL FILE UNLOCKED: %s. Resolve closing credit, then open Capital Expansions." % String(
				unlock.get("name", "NEW FACILITY")
			)
		)
	minute_of_day = SHIFT_START_MINUTE
	quota_target = next_quota
	eggs_today = 0
	cracked_today = 0
	golden_today = 0
	credited_today_cents = 0
	packing_cartons_today = 0
	packing_value_bonus_today_cents = 0
	packing_carton_bonus_today_cents = 0
	intake_rejections_today = 0
	intake_missed_value_today_cents = 0
	market_contract_premium_today_cents = 0
	market_contract_breach_today_cents = 0
	requisition_spend_today_cents = 0
	orientation_procurement_match_today_cents = 0
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
		if _offer_new_claim(_choose_arrival_lane()):
			new_intake_claims += 1
	shift_phase = ShiftPhase.REVIEW
	_prepare_credit_allocation_decision(
		completed_day,
		completed_pecking_order,
		completed_golden,
	)
	var harvest_top: Dictionary = (
		(completed_pecking_order[0] as Dictionary)
		if not completed_pecking_order.is_empty() else
		{}
	)
	var harvest_evidence := {
		"day": completed_day,
		"eggs": completed_eggs,
		"quota": completed_quota,
		"sound": maxi(0, completed_eggs - completed_cracked),
		"cracked": completed_cracked,
		"golden": completed_golden,
		"met_quota": met_quota,
		"top_worker_id": int(harvest_top.get("worker_id", -1)),
		"top_worker_name": String(harvest_top.get("worker_name", "")),
		"hen_highlight": completed_hen_highlight.duplicate(true),
	}
	var completed_gallery_level := int(
		completed_owned_facilities.get(
			FARMER_RELATIONS_GALLERY_ID,
			completed_owned_facilities.get(String(FARMER_RELATIONS_GALLERY_ID), 0),
		)
	)
	if not _harvest_credit.stage_review(
		harvest_evidence,
		completed_gallery_level,
		not pending_decision.is_empty(),
	):
		push_error("Completed-shift evidence could not open the Harvest Credit review.")
	shift_phase_changed.emit(shift_phase)
	for worker in workers:
		if not worker.employed:
			continue
		_apply_overnight_recovery(worker)
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
		"feed_procurement": completed_feed_procurement,
		"feed_procurement_spend_cents": completed_feed_procurement_spend,
		"feed_spot_spend_cents": completed_feed_cost,
		"feed_total_cash_spend_cents": completed_feed_total_cash_spend,
		"feed_consumed_value_cents": int(
			completed_feed_procurement.get("consumed_value_today_cents", 0)
		),
		"feed_spoiled_scoops": int(
			completed_feed_procurement.get("spoiled_today_scoops", 0)
		),
		"facility_expansion_cost_cents": completed_facility_expansion_cost,
		"facility_maintenance_cents": completed_facility_maintenance_cost,
		"campus_services_cost_cents": completed_campus_services_cost,
		"portfolio_operations_cost_cents": completed_portfolio_operations_cost,
		"facility_cost_cents": completed_facility_cost,
		"owned_facilities": completed_owned_facilities,
		"facility_effects": completed_facility_effects,
		"flock_care": completed_flock_care,
		"operations": completed_operations,
		"manager_careers": completed_manager_careers,
		"internship_program": completed_internship_program,
		"internship_transitions": completed_internship_transitions,
		"flock_relations": completed_flock_relations,
		"farmer_relations_gallery": farmer_relations_gallery_snapshot(),
		"farmgate_dispatch": completed_farmgate_dispatch,
		"farmgate_settlement": completed_farmgate_settlement.duplicate(true),
		"farmgate_settlement_shortfall_cents": completed_farmgate_shortfall_cents,
		"farm_treasury": completed_farm_treasury,
		"farm_treasury_receipt": completed_farm_treasury_receipt.duplicate(true),
		"campus_portfolio": completed_campus_portfolio,
		"campus_portfolio_progress": portfolio_progress.duplicate(true),
		"rooster_operations_office_level": int(
			completed_facility_effects.get("rooster_operations_office_level", 0)
		),
		"it_coop_level": int(completed_facility_effects.get("it_coop_level", 0)),
		"flock_relations_office_level": int(
			completed_facility_effects.get("flock_relations_office_level", 0)
		),
		"wellness_nest_level": int(completed_facility_effects.get("wellness_nest_level", 0)),
		"training_roost_level": int(completed_facility_effects.get("training_roost_level", 0)),
		"career_sponsorship_cost_cents": int(
			completed_facility_effects.get("career_sponsorship_cost_cents", CAREER_SPONSORSHIP_COST_CENTS)
		),
		"career_coaching_xp_bonus": int(
			completed_facility_effects.get("career_coaching_xp_bonus", 0)
		),
		"packing_contract": completed_packing_contract,
		"packing_carton_progress": int(completed_packing_contract.get("carton_progress", 0)),
		"packing_cartons_today": int(completed_packing_contract.get("cartons_today", 0)),
		"packing_cartons_total": int(completed_packing_contract.get("cartons_total", 0)),
		"packing_value_bonus_cents": int(completed_packing_contract.get("value_bonus_today_cents", 0)),
		"packing_carton_bonus_cents": int(completed_packing_contract.get("carton_bonus_today_cents", 0)),
		"packing_contract_credit_cents": int(completed_packing_contract.get("contract_credit_today_cents", 0)),
			"claim_capacity": _claim_capacity_for_facilities_and_campus(
				completed_owned_facilities,
				campus_expansion_state,
				int((completed_campus_portfolio.get("bonuses", {}) as Dictionary).get(
					"claim_capacity",
					0,
				)),
			),
		"intake_rejections": completed_intake_rejections,
		"intake_rejections_today": completed_intake_rejections,
		"intake_rejections_total": completed_intake_rejections_total,
		"intake_missed_value_cents": completed_intake_missed_value_cents,
		"intake_missed_value_today_cents": completed_intake_missed_value_cents,
		"intake_missed_value_total_cents": completed_intake_missed_value_total_cents,
		"market_contract": completed_market_contract.duplicate(true),
		"market_contract_base_premium_cents": int(
			completed_market_contract.get("base_premium_cents", 0)
		),
		"market_contract_authored_base_premium_cents": int(
			completed_market_contract.get("authored_base_premium_cents", 0)
		),
		"market_contract_season_premium_delta_cents": int(
			completed_market_contract.get("season_premium_delta_cents", 0)
		),
		"market_contract_clause_premium_delta_cents": int(
			completed_market_contract.get("clause_premium_delta_cents", 0)
		),
		"market_contract_market_premium_cents": int(
			completed_market_contract.get("market_premium_cents", 0)
		),
		"market_contract_service_coop_bonus_cents": int(
			completed_market_contract.get("service_coop_bonus_cents", 0)
		),
		"market_contract_contracted_service_coop_bonus_cents": int(
			completed_market_contract.get("contracted_service_coop_bonus_cents", 0)
		),
		"market_contract_service_coop_level": int(
			completed_market_contract.get("service_coop_level_at_signing", 0)
		),
		"market_contract_negotiation_room_level": int(
			completed_market_contract.get("negotiation_room_level_at_signing", 0)
		),
		"market_contract_season_id": completed_market_contract.get(
			"season_id", &"baseline_neutral"
		),
		"market_contract_clause_id": completed_market_contract.get(
			"clause_id", &"standard_terms"
		),
		"market_contract_contracted_premium_cents": int(
			completed_market_contract.get("contracted_premium_cents", 0)
		),
		"market_contract_premium_cents": int(completed_market_contract.get("premium_cents", 0)),
		"market_contract_authored_breach_cents": int(
			completed_market_contract.get("authored_breach_cents", 0)
		),
		"market_contract_season_breach_delta_cents": int(
			completed_market_contract.get("season_breach_delta_cents", 0)
		),
		"market_contract_clause_breach_delta_cents": int(
			completed_market_contract.get("clause_breach_delta_cents", 0)
		),
		"market_contract_contracted_breach_cents": int(
			completed_market_contract.get("contracted_breach_cents", 0)
		),
		"market_contract_breach_cents": int(completed_market_contract.get("breach_cents", 0)),
		"market_contract_closing_welfare": int(
			completed_market_contract.get("closing_welfare", 0)
		),
		"market_contract_welfare_gate_minimum": int(
			completed_market_contract.get("welfare_gate_minimum", 0)
		),
		"market_contract_welfare_gate_met": bool(
			completed_market_contract.get("welfare_gate_met", true)
		),
		"market_contract_net_cents": int(completed_market_contract.get("net_contract_cents", 0)),
		"market_contract_premium_total_cents": market_contract_premium_total_cents,
		"market_contract_breach_total_cents": market_contract_breach_total_cents,
		"market_contracts_signed_total": market_contracts_signed_total,
		"market_contracts_succeeded_total": market_contracts_succeeded_total,
		"market_contracts_breached_total": market_contracts_breached_total,
		"market_contract_standing": farm_mutual_standing(),
		"market_contract_standing_rank": farm_mutual_standing_rank(),
		"market_clean_contract_streak": market_clean_contract_streak,
		"best_market_clean_contract_streak": best_market_clean_contract_streak,
		"farm_mutual_standing": completed_farm_mutual_standing,
		"first_clutch_reinvestment": completed_first_clutch_reinvestment,
		"active_playbook": completed_active_playbook,
		"requisition_spend_cents": completed_requisition_spend_cents,
		"requisition_spend_total_cents": requisition_spend_total_cents,
		"orientation_procurement_match_cents": completed_orientation_match_cents,
		"orientation_procurement_match_total_cents": orientation_procurement_match_total_cents,
		"new_facility_unlocks": completed_new_facility_unlocks.duplicate(true),
		"hen_payroll_cents": completed_hen_payroll,
		"supervisor_payroll_cents": completed_supervisor_payroll,
		"fellow_payroll_cents": completed_fellow_payroll,
		"payroll_cents": completed_payroll,
		"opening_wage_arrears_cents": opening_wage_arrears,
		"payroll_due_cents": payroll_due_cents,
		"payroll_paid_cents": payroll_paid_cents,
		"wage_arrears_cents": wage_arrears_cents,
		"treasury_credit_draw_cents": int(completed_farm_treasury_receipt.get("credit_draw_cents", 0)),
		"treasury_principal_repaid_cents": int(completed_farm_treasury_receipt.get("principal_repaid_cents", 0)),
		"treasury_interest_charged_cents": int(completed_farm_treasury_receipt.get("interest_charged_cents", 0)),
		"treasury_vendor_paid_cents": int(completed_farm_treasury_receipt.get("vendor_paid_cents", 0)),
		"treasury_vendor_arrears_cents": int(completed_farm_treasury_receipt.get("closing_vendor_arrears_cents", 0)),
		"treasury_interest_arrears_cents": int(completed_farm_treasury_receipt.get("closing_interest_arrears_cents", 0)),
		"operating_cost_cents": completed_operating_cost,
		"active_staff_count": completed_active_staff,
		"office_capacity": completed_office_capacity,
		"welfare": completed_welfare,
		"compliance": completed_compliance,
		"farmer_favor": completed_farmer_favor,
		# The live chain and persistent best are closing evidence, just like shell
		# quality and welfare. Filing the same bounded snapshot in the workday report
		# lets review and resume surfaces describe routing mastery without rebuilding
		# it from presentation state.
		"routing_momentum": routing_momentum_snapshot(),
		"directive": completed_directive,
		"incidents_resolved": completed_incidents,
		"incident_responses": completed_incident_responses,
		"quota_adjustment": completed_quota_adjustment,
		"returned_claims": returned_claims,
		"new_intake_claims": new_intake_claims,
		"lane_processed": completed_lane_processed,
		"personnel_action": completed_personnel_action,
		"personnel_actions": completed_personnel_actions.duplicate(true),
		"staffing_actions": completed_staffing_actions,
		"career_sponsorships_completed": completed_career_sponsorships,
		"flock_petition": completed_flock_petition,
		"flock_compact_receipt": completed_flock_compact_receipt,
		"work_to_rule": completed_work_to_rule,
		"flock_relations_filings": completed_flock_relations_filings,
		"flock_relations_carry_effects": completed_flock_relations_carry_effects,
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
		"claims_outstanding": completed_outstanding_claims,
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
		"career_arc": {
			"chapter": "FLOCK VETERAN" if worker.career_xp >= 40 else ("TRUSTED HAND" if worker.manager_trust >= 65.0 else "NEW PERCH"),
			"beat": "Day %d · %s · trust %d" % [completed_day, worker.career_title(), roundi(worker.manager_trust)],
			"continues_next_shift": true,
		},
		"highlight_replay": {
			"duration_seconds": 3.0,
			"skippable": true,
			"beats": [
				{"at": 0.0, "icon": "flock", "label": worker.display_name.to_upper()},
				{"at": 1.0, "icon": "egg", "label": "%d EGGS" % eggs},
				{"at": 2.0, "icon": "cash", "label": "$%.2f CREDIT" % (float(credit_cents) / 100.0)},
			],
		},
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
