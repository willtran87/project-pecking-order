class_name DepartmentSimulation
extends RefCounted

const FeedProcurementStateScript := preload("res://core/simulation/feed_procurement_state.gd")
const HarvestCreditStateScript := preload("res://core/simulation/harvest_credit_state.gd")
const FarmgateDispatchStateScript := preload("res://core/simulation/farmgate_dispatch_state.gd")
const CampusPortfolioStateScript := preload("res://core/simulation/campus_portfolio_state.gd")
const FarmTreasuryStateScript := preload("res://core/simulation/farm_treasury_state.gd")

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
signal manager_action_resolved(result: Dictionary)
signal peck_assist_resolved(result: Dictionary)
signal peck_assist_missed(worker_id: int, claim_id: int)
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
const SAVE_STATE_VERSION := 25
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
const MARKET_CONTRACT_MAX_CLAIMS := 6
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
		"summary": "Convert every folder to this binder's authored dominant claim lane.",
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
		"description": "A lit shell-inspection bench and dedicated return lane for cracked claims.",
		"cost_cents": 4000,
		"daily_maintenance_cents": 300,
		"max_level": 1,
		"unlock_id": &"shell_quality_checks",
		"unlock_requirement": "Complete the Shell Quality Checks milestone before commissioning this facility.",
		"crack_modifier": -0.015,
		"rework_speed_multiplier": 1.20,
		"benefits": [
			"-1.5% crack risk across the office",
			"+20% processing speed for rework claims",
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
			"Retains claim demand that would otherwise leave the farm",
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
			"AUTOMATED CLAIMS SORTER",
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
const INCIDENT_DOCKET_SEED_OFFSET := 32_452_843
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
var first_clutch_reinvestment: Dictionary = {}
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
var manager_roster: Array[Dictionary] = []
var last_manager_action: Dictionary = {}
var management_reports_today: int = 0
var management_reports_total: int = 0
var management_visibility_today: int = 0

var _tick_count: int = 0
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
var _feed_procurement = FeedProcurementStateScript.new()
var _harvest_credit = HarvestCreditStateScript.new()
var _farmgate_dispatch = FarmgateDispatchStateScript.new()
var _campus_portfolio = CampusPortfolioStateScript.new()
var _farm_treasury = FarmTreasuryStateScript.new(5000, 0)


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


func _ensure_manager_posts_for_office_level() -> void:
	var authorized_count := clampi(facility_level(ROOSTER_OPERATIONS_OFFICE_ID) + 1, 1, 4)
	while manager_roster.size() < authorized_count:
		var slot_index := manager_roster.size()
		manager_roster.append(_new_manager_record(
			MANAGER_DEFAULT_HIRE_ORDER[slot_index], slot_index, day
		))


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


func facility_level(facility_id: StringName) -> int:
	if not FACILITY_DEFINITIONS.has(facility_id):
		return -1
	return int(owned_facilities.get(facility_id, 0))


func has_facility(facility_id: StringName) -> bool:
	return facility_level(facility_id) > 0


func current_claim_capacity() -> int:
	return (
		_claim_capacity_for_facilities(owned_facilities)
		+ _campus_claim_capacity_bonus_for_state(campus_expansion_state)
		+ _campus_portfolio.claim_capacity_bonus(_campus_portfolio_context())
	)


func _claim_capacity_for_facilities(facilities: Dictionary) -> int:
	var records_level := clampi(
		int(facilities.get(RECORDS_ANNEX_ID, facilities.get(String(RECORDS_ANNEX_ID), 0))),
		0,
		int((FACILITY_DEFINITIONS[RECORDS_ANNEX_ID] as Dictionary).get("max_level", 3)),
	)
	return BASE_CLAIM_CAPACITY + CLAIM_CAPACITY_PER_RECORDS_LEVEL * records_level


func _claim_capacity_for_facilities_and_campus(
	facilities: Dictionary,
	campus_state: Dictionary,
	portfolio_bonus: int = 0,
) -> int:
	return (
		_claim_capacity_for_facilities(facilities)
		+ _campus_claim_capacity_bonus_for_state(campus_state)
		+ maxi(0, portfolio_bonus)
	)


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


func _service_coop_requirement(schedule: Array[int], target_level: int) -> int:
	if target_level <= 0 or target_level > schedule.size():
		return 0
	return int(schedule[target_level - 1])


func _service_coop_premium_bonus_cents(base_premium_cents: int, level: int) -> int:
	## The bonus is additive against the authored base, never compounded from a
	## prior tier. Adding half a basis-point denominator before integer division
	## gives deterministic half-up rounding without passing money through floats.
	var numerator := (
		maxi(0, base_premium_cents)
		* maxi(0, level)
		* SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		+ 5_000
	)
	@warning_ignore("integer_division")
	return numerator / 10_000


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


func _basis_point_delta_cents(authored_cents: int, basis_points: int) -> int:
	return _signed_half_up_ratio(maxi(0, authored_cents) * basis_points, 10_000)


func _neutral_market_season_for_day(target_day: int) -> Dictionary:
	return {
		"id": &"baseline_neutral",
		"label": "BASELINE NEUTRAL BOOK",
		"short_label": "BASELINE BOOK",
		"summary": "Farm Mutual holds authored probation pricing steady before its seasonal book opens.",
		"target_day": target_day,
		"season_index": -1,
		"quarter": 0,
		"year": 0,
		"start_day": CONTRACT_BOARD_UNLOCK_DAY,
		"end_day": MARKET_SEASON_FIRST_DAY - 1,
		"days_remaining": maxi(0, MARKET_SEASON_FIRST_DAY - target_day),
		"lane_demand_basis_points": {
			"nest_damage": 0,
			"predator_loss": 0,
			"appeals": 0,
		},
	}


func market_season_for_day(target_day: int) -> Dictionary:
	if target_day < MARKET_SEASON_FIRST_DAY:
		return _neutral_market_season_for_day(target_day)
	var day_offset := target_day - MARKET_SEASON_FIRST_DAY
	@warning_ignore("integer_division")
	var season_serial: int = day_offset / MARKET_SEASON_LENGTH_DAYS
	var season_index := season_serial % MARKET_SEASONS_PER_YEAR
	@warning_ignore("integer_division")
	var market_year: int = season_serial / MARKET_SEASONS_PER_YEAR + 1
	var definition := MARKET_SEASON_DEFINITIONS[season_index] as Dictionary
	var season_start := (
		MARKET_SEASON_FIRST_DAY + season_serial * MARKET_SEASON_LENGTH_DAYS
	)
	return {
		"id": StringName(definition.get("id", &"baseline_neutral")),
		"label": String(definition.get("label", "BASELINE NEUTRAL BOOK")),
		"short_label": String(definition.get("short_label", "BASELINE BOOK")),
		"summary": String(definition.get("summary", "")),
		"target_day": target_day,
		"season_index": season_index,
		"quarter": season_index + 1,
		"year": market_year,
		"start_day": season_start,
		"end_day": season_start + MARKET_SEASON_LENGTH_DAYS - 1,
		"days_remaining": season_start + MARKET_SEASON_LENGTH_DAYS - target_day,
		"lane_demand_basis_points": (
			definition.get("lane_demand_basis_points", {}) as Dictionary
		).duplicate(true),
	}


func market_contract_clause_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	var room_owned := has_facility(FARM_MUTUAL_NEGOTIATION_ROOM_ID)
	for clause_id in MARKET_CONTRACT_CLAUSE_ORDER:
		var definition := MARKET_CONTRACT_CLAUSE_DEFINITIONS[clause_id] as Dictionary
		var requires_room := bool(definition.get("requires_negotiation_room", false))
		catalog.append({
			"clause_id": clause_id,
			"label": String(definition.get("label", "STANDARD TERMS")),
			"summary": String(definition.get("summary", "")),
			"category": StringName(definition.get("category", &"standard")),
			"requires_negotiation_room": requires_room,
			"clause_available": not requires_room or room_owned,
			"premium_basis_points": int(definition.get("premium_basis_points", 0)),
			"breach_basis_points": int(definition.get("breach_basis_points", 0)),
		})
	return catalog


func _facility_level_schedule_value(schedule: Array, level: int, fallback: int) -> int:
	if schedule.is_empty():
		return fallback
	var index := clampi(level, 0, schedule.size() - 1)
	return int(schedule[index])


func _facility_tier_requirement(schedule: Array, target_level: int) -> int:
	if target_level <= 0 or schedule.is_empty():
		return 0
	var index := clampi(target_level - 1, 0, schedule.size() - 1)
	return int(schedule[index])


func _facility_unlock_day_for_level(definition: Dictionary, target_level: int) -> int:
	var unlock_days_value: Variant = definition.get("unlock_days", null)
	if unlock_days_value is Array and target_level > 0:
		var unlock_days := unlock_days_value as Array
		var index := target_level - 1
		if index >= 0 and index < unlock_days.size():
			return maxi(1, int(unlock_days[index]))
	return maxi(1, int(definition.get("unlock_day", 1)))


func _qualified_active_worker_count(minimum_career_level: int) -> int:
	var count := 0
	for worker in workers:
		if worker.employed and worker.career_level() >= minimum_career_level:
			count += 1
	return count


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


func flock_relations_case_capacity() -> int:
	return _facility_level_schedule_value(
		FLOCK_RELATIONS_CASE_CAPACITY,
		facility_level(FLOCK_RELATIONS_OFFICE_ID),
		0,
	)


func flock_relations_resolution_limit() -> int:
	return _facility_level_schedule_value(
		FLOCK_RELATIONS_RESOLUTION_LIMITS,
		facility_level(FLOCK_RELATIONS_OFFICE_ID),
		0,
	)


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


func _farmgate_storage_capacity_for_level_and_campus(
	farmgate_level: int,
	campus_state: Dictionary,
	portfolio_bonus_eggs: int = 0,
) -> int:
	var base_capacity := _facility_level_schedule_value(
		FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS,
		farmgate_level,
		0,
	)
	if base_capacity <= 0:
		return 0
	return mini(
		CAMPUS_FARMGATE_MAX_STORAGE_EGGS + maxi(0, portfolio_bonus_eggs),
		base_capacity
		+ _campus_farmgate_capacity_bonus_for_state(campus_state, farmgate_level)
		+ maxi(0, portfolio_bonus_eggs),
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


func facility_effects() -> Dictionary:
	var crack_modifier := 0.0
	var rework_speed_multiplier := 1.0
	for facility_id in FACILITY_ORDER:
		var level := facility_level(facility_id)
		if level <= 0:
			continue
		var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
		crack_modifier += float(definition.get("crack_modifier", 0.0)) * level
		rework_speed_multiplier *= pow(
			float(definition.get("rework_speed_multiplier", 1.0)),
			level,
		)
	var packing_level := maxi(0, facility_level(PACKING_ANNEX_ID))
	var packing_value_bonus := PACKING_VALUE_BONUS_PER_LEVEL * packing_level
	var records_level := maxi(0, facility_level(RECORDS_ANNEX_ID))
	var records_claim_capacity_bonus := CLAIM_CAPACITY_PER_RECORDS_LEVEL * records_level
	var campus_claim_capacity_bonus := _campus_claim_capacity_bonus_for_state(campus_expansion_state)
	var claim_capacity_bonus := records_claim_capacity_bonus + campus_claim_capacity_bonus
	var service_coop_level := maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID))
	var negotiation_room_level := maxi(0, facility_level(FARM_MUTUAL_NEGOTIATION_ROOM_ID))
	var wellness_level := maxi(0, facility_level(WELLNESS_NEST_ID))
	var training_level := maxi(0, facility_level(TRAINING_ROOST_ID))
	var rooster_operations_level := maxi(0, facility_level(ROOSTER_OPERATIONS_OFFICE_ID))
	var it_coop_level := maxi(0, facility_level(IT_COOP_ID))
	var flock_relations_level := maxi(0, facility_level(FLOCK_RELATIONS_OFFICE_ID))
	var feed_procurement_level := maxi(0, facility_level(FEED_PROCUREMENT_COOP_ID))
	var farmer_relations_gallery_level := maxi(0, facility_level(FARMER_RELATIONS_GALLERY_ID))
	var farmgate_dispatch_level := maxi(0, facility_level(FARMGATE_DISPATCH_DEPOT_ID))
	var strain_basis_points := wellness_strain_gain_basis_points()
	var break_recovery_basis_points := wellness_break_recovery_basis_points()
	var overnight_fatigue_millipoints := wellness_overnight_fatigue_recovery_millipoints()
	var overnight_stress_millipoints := wellness_overnight_stress_recovery_millipoints()
	var sponsorship_cost := career_sponsorship_cost_cents()
	var training_work_basis_points := pending_training_work_basis_points()
	return {
		"crack_modifier": crack_modifier,
		"crack_risk_modifier": crack_modifier,
		"crack_risk_basis_points": roundi(crack_modifier * 10_000.0),
		"rework_speed_multiplier": rework_speed_multiplier,
		"rework_processing_speed_multiplier": rework_speed_multiplier,
		"packing_annex_level": packing_level,
		"packing_value_bonus": packing_value_bonus,
		"packing_value_bonus_percent": roundi(packing_value_bonus * 100.0),
		"packing_value_multiplier": 1.0 + packing_value_bonus,
		"packing_carton_size": PACKING_CARTON_SIZE,
		"packing_carton_bonus_cents": PACKING_CARTON_BONUS_PER_LEVEL_CENTS * packing_level,
		"records_annex_level": records_level,
		"claim_capacity_base": BASE_CLAIM_CAPACITY,
		"claim_capacity_bonus": claim_capacity_bonus,
		"records_claim_capacity_bonus": records_claim_capacity_bonus,
		"campus_claim_capacity_bonus": campus_claim_capacity_bonus,
		"claim_capacity": BASE_CLAIM_CAPACITY + claim_capacity_bonus,
		"farm_mutual_service_coop_level": service_coop_level,
		"farm_mutual_negotiation_room_level": negotiation_room_level,
		"farm_mutual_negotiation_room_owned": negotiation_room_level > 0,
		"farm_mutual_premium_bonus_basis_points": (
			service_coop_level * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"farm_mutual_standing": farm_mutual_standing(),
		"farm_mutual_standing_rank": farm_mutual_standing_rank(),
		"wellness_nest_level": wellness_level,
		"wellness_strain_gain_basis_points": strain_basis_points,
		"wellness_strain_gain_multiplier": float(strain_basis_points) / 10_000.0,
		"wellness_break_recovery_basis_points": break_recovery_basis_points,
		"wellness_break_recovery_multiplier": float(break_recovery_basis_points) / 10_000.0,
		"wellness_break_morale_millipoints": wellness_break_morale_millipoints(),
		"wellness_overnight_fatigue_recovery_millipoints": overnight_fatigue_millipoints,
		"wellness_overnight_stress_recovery_millipoints": overnight_stress_millipoints,
		"training_roost_level": training_level,
		"career_sponsorship_base_cost_cents": CAREER_SPONSORSHIP_COST_CENTS,
		"career_sponsorship_cost_cents": sponsorship_cost,
		"career_sponsorship_discount_cents": CAREER_SPONSORSHIP_COST_CENTS - sponsorship_cost,
		"cross_training_work_basis_points": training_work_basis_points,
		"cross_training_work_multiplier": float(training_work_basis_points) / 10_000.0,
		"career_coaching_xp_bonus": career_coaching_xp_bonus(),
		"rooster_operations_office_level": rooster_operations_level,
		"personnel_action_limit": personnel_action_limit(),
		"supervisor_payroll_cents": supervisor_payroll_cents(),
		"surveillance_grievance_millipoints": rooster_surveillance_grievance_millipoints(),
		"surveillance_stress_millipoints": rooster_surveillance_stress_millipoints(),
		"surveillance_solidarity_millipoints": rooster_surveillance_solidarity_millipoints(),
		"it_coop_level": it_coop_level,
		"automation_work_basis_points": automation_work_basis_points(),
		"automation_work_multiplier": automation_work_multiplier(),
		"automation_specialty_grace_minutes": automation_specialty_grace_minutes(),
		"automation_recognizes_secondary_specialties": automation_recognizes_secondary_specialties(),
		"automation_compliance_exposure_millipoints": automation_compliance_exposure_millipoints(),
		"ledger_molt_patch_cost_cents": ledger_molt_patch_cost_cents(),
		"ledger_molt_spreadsheet_compliance_loss_millipoints": ledger_molt_spreadsheet_compliance_loss_millipoints(),
		"ledger_molt_spreadsheet_crack_basis_points": ledger_molt_spreadsheet_crack_basis_points(),
		"flock_relations_office_level": flock_relations_level,
		"flock_relations_case_capacity": flock_relations_case_capacity(),
		"flock_relations_resolution_limit": flock_relations_resolution_limit(),
		"feed_procurement_coop_level": feed_procurement_level,
		"feed_procurement_capacity_scoops": _feed_procurement_capacity_scoops(),
		"farmer_relations_gallery_level": farmer_relations_gallery_level,
		"farmgate_dispatch_depot_level": farmgate_dispatch_level,
		"farmgate_storage_capacity_eggs": _farmgate_storage_capacity_eggs(),
		"campus_farmgate_storage_bonus_eggs": _campus_farmgate_capacity_bonus_for_state(
			campus_expansion_state,
			farmgate_dispatch_level,
		),
		"farmgate_dispatch_capacity_eggs": _farmgate_dispatch_capacity_eggs(),
		"farmgate_shelf_life_shifts": _farmgate_shelf_life_shifts(),
	}


func facility_catalog() -> Array[Dictionary]:
	var catalog: Array[Dictionary] = []
	for facility_id in FACILITY_ORDER:
		catalog.append(facility_status(facility_id))
	return catalog


func facility_status(facility_id: StringName) -> Dictionary:
	if not FACILITY_DEFINITIONS.has(facility_id):
		return {
			"known": false,
			"id": facility_id,
			"name": "UNKNOWN FACILITY",
			"short_name": "UNKNOWN",
			"description": "This facility code is not on the capital schedule.",
			"cost_cents": 0,
			"daily_maintenance_cents": 0,
			"current_maintenance_cents": 0,
			"next_maintenance_cents": 0,
			"maintenance_delta_cents": 0,
			"benefits": [] as Array[String],
			"tradeoffs": [] as Array[String],
			"owned": false,
			"installed": false,
			"maxed": false,
			"level": 0,
			"next_level": 0,
			"max_level": 0,
			"unlocked": false,
			"planning_open": staffing_planning_open(),
			"affordable": false,
			"can_purchase": false,
			"reason": "Facility code is not on the authorized capital schedule.",
			"action_reason": "Facility code is not on the authorized capital schedule.",
			"purchase_label": "UNLISTED FACILITY",
			"projected_spendable_fund_cents": spendable_fund_cents(),
		}

	var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
	var level := facility_level(facility_id)
	var max_level := int(definition.get("max_level", 1))
	var installed := level > 0
	var maxed := level >= max_level
	var next_level := mini(max_level, level + 1)
	var unlock_id := StringName(definition.get("unlock_id", &""))
	var unlock_day := _facility_unlock_day_for_level(definition, next_level)
	var base_unlocked := (
		(unlock_id == &"" or has_campaign_unlock(unlock_id))
		and day >= unlock_day
	)
	var market_standing := farm_mutual_standing()
	var required_market_standing := 0
	var required_claim_capacity := 0
	var required_active_staff := 0
	var required_office_capacity := 0
	var required_service_coop_level := 0
	var required_wellness_nest_level := 0
	var required_packing_annex_level := 0
	var required_records_annex_level := 0
	var required_rooster_operations_level := 0
	var required_farmer_relations_gallery_level := 0
	var required_harvest_credit_standing := 0
	var required_career_level := 0
	var qualified_staff_count := 0
	var harvest_credit_standing := int(_harvest_credit.public_standing)
	if facility_id == FARM_MUTUAL_SERVICE_COOP_ID:
		required_market_standing = _service_coop_requirement(
			SERVICE_COOP_LEVEL_STANDING_REQUIREMENTS,
			next_level,
		)
		required_claim_capacity = _service_coop_requirement(
			SERVICE_COOP_LEVEL_CLAIM_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _service_coop_requirement(
			SERVICE_COOP_LEVEL_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == FARM_MUTUAL_NEGOTIATION_ROOM_ID:
		required_market_standing = NEGOTIATION_ROOM_REQUIRED_STANDING
		required_service_coop_level = NEGOTIATION_ROOM_REQUIRED_SERVICE_COOP_LEVEL
	elif facility_id == WELLNESS_NEST_ID:
		required_office_capacity = _facility_tier_requirement(
			WELLNESS_NEST_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			WELLNESS_NEST_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == TRAINING_ROOST_ID:
		required_office_capacity = _facility_tier_requirement(
			TRAINING_ROOST_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			TRAINING_ROOST_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_wellness_nest_level = next_level
		required_career_level = _facility_tier_requirement(
			TRAINING_ROOST_CAREER_LEVEL_REQUIREMENTS,
			next_level,
		)
		qualified_staff_count = _qualified_active_worker_count(required_career_level)
	elif facility_id == ROOSTER_OPERATIONS_OFFICE_ID:
		required_office_capacity = _facility_tier_requirement(
			ROOSTER_OPERATIONS_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			ROOSTER_OPERATIONS_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == IT_COOP_ID:
		required_office_capacity = _facility_tier_requirement(
			IT_COOP_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			IT_COOP_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_records_annex_level = next_level
		required_rooster_operations_level = next_level
	elif facility_id == FLOCK_RELATIONS_OFFICE_ID:
		required_office_capacity = _facility_tier_requirement(
			FLOCK_RELATIONS_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			FLOCK_RELATIONS_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_rooster_operations_level = next_level
		required_wellness_nest_level = next_level
	elif facility_id == FEED_PROCUREMENT_COOP_ID:
		required_office_capacity = _facility_tier_requirement(
			FEED_PROCUREMENT_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			FEED_PROCUREMENT_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
	elif facility_id == FARMER_RELATIONS_GALLERY_ID:
		required_office_capacity = _facility_tier_requirement(
			FARMER_RELATIONS_GALLERY_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			FARMER_RELATIONS_GALLERY_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_packing_annex_level = next_level
	elif facility_id == FARMGATE_DISPATCH_DEPOT_ID:
		required_office_capacity = _facility_tier_requirement(
			FARMGATE_DISPATCH_OFFICE_CAPACITY_REQUIREMENTS,
			next_level,
		)
		required_active_staff = _facility_tier_requirement(
			FARMGATE_DISPATCH_ACTIVE_STAFF_REQUIREMENTS,
			next_level,
		)
		required_packing_annex_level = _facility_tier_requirement(
			FARMGATE_DISPATCH_PACKING_LEVEL_REQUIREMENTS,
			next_level,
		)
		required_farmer_relations_gallery_level = _facility_tier_requirement(
			FARMGATE_DISPATCH_GALLERY_LEVEL_REQUIREMENTS,
			next_level,
		)
		required_harvest_credit_standing = _facility_tier_requirement(
			FARMGATE_DISPATCH_STANDING_REQUIREMENTS,
			next_level,
		)
	var authored_gate_met := true
	if not maxed and facility_id == FARM_MUTUAL_SERVICE_COOP_ID:
		authored_gate_met = (
			market_standing >= required_market_standing
			and current_claim_capacity() >= required_claim_capacity
			and active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == FARM_MUTUAL_NEGOTIATION_ROOM_ID:
		authored_gate_met = (
			market_standing >= required_market_standing
			and facility_level(FARM_MUTUAL_SERVICE_COOP_ID) >= required_service_coop_level
		)
	elif not maxed and facility_id == WELLNESS_NEST_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == TRAINING_ROOST_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
			and facility_level(WELLNESS_NEST_ID) >= required_wellness_nest_level
			and qualified_staff_count > 0
		)
	elif not maxed and facility_id == ROOSTER_OPERATIONS_OFFICE_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == IT_COOP_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
			and facility_level(RECORDS_ANNEX_ID) >= required_records_annex_level
			and facility_level(ROOSTER_OPERATIONS_OFFICE_ID)
			>= required_rooster_operations_level
		)
	elif not maxed and facility_id == FLOCK_RELATIONS_OFFICE_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
			and facility_level(ROOSTER_OPERATIONS_OFFICE_ID)
			>= required_rooster_operations_level
			and facility_level(WELLNESS_NEST_ID) >= required_wellness_nest_level
		)
	elif not maxed and facility_id == FEED_PROCUREMENT_COOP_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
		)
	elif not maxed and facility_id == FARMER_RELATIONS_GALLERY_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
			and facility_level(PACKING_ANNEX_ID) >= required_packing_annex_level
		)
	elif not maxed and facility_id == FARMGATE_DISPATCH_DEPOT_ID:
		authored_gate_met = (
			office_capacity >= required_office_capacity
			and active_worker_count() >= required_active_staff
			and facility_level(PACKING_ANNEX_ID) >= required_packing_annex_level
			and facility_level(FARMER_RELATIONS_GALLERY_ID)
			>= required_farmer_relations_gallery_level
			and harvest_credit_standing >= required_harvest_credit_standing
		)
	var unlocked := base_unlocked and authored_gate_met
	var planning_open := staffing_planning_open()
	var cost_cents := 0 if maxed else _facility_cost_for_level(definition, next_level)
	var current_maintenance_cents := _facility_maintenance_for_level(definition, level)
	var next_maintenance_cents := (
		current_maintenance_cents
		if maxed else
		_facility_maintenance_for_level(definition, next_level)
	)
	var maintenance_delta_cents := maxi(
		0,
		next_maintenance_cents - current_maintenance_cents,
	)
	var current_rooster_operations_level := facility_level(ROOSTER_OPERATIONS_OFFICE_ID)
	var preview_rooster_operations_level := (
		next_level
		if facility_id == ROOSTER_OPERATIONS_OFFICE_ID and not maxed else
		current_rooster_operations_level
	)
	var current_supervisor_payroll_cents := _facility_level_schedule_value(
		ROOSTER_SUPERVISOR_PAYROLL_CENTS,
		current_rooster_operations_level,
		0,
	)
	var next_supervisor_payroll_cents := _facility_level_schedule_value(
		ROOSTER_SUPERVISOR_PAYROLL_CENTS,
		preview_rooster_operations_level,
		0,
	)
	var supervisor_payroll_delta_cents := maxi(
		0,
		next_supervisor_payroll_cents - current_supervisor_payroll_cents,
	)
	var added_daily_operating_cents := (
		maintenance_delta_cents + supervisor_payroll_delta_cents
	)
	var required_spendable_cents := _required_spendable_for_obligation_change_cents(
		cost_cents,
		added_daily_operating_cents,
	)
	var spendable := spendable_fund_cents()
	var affordable := not maxed and _projected_spendable_after_obligation_change_cents(
		cost_cents,
		added_daily_operating_cents,
	) >= 0
	var projected_spendable := spendable
	if not maxed:
		projected_spendable = _projected_spendable_after_obligation_change_cents(
			cost_cents,
			added_daily_operating_cents,
		)
	var reason := ""
	if maxed:
		reason = "%s is already fully commissioned." % String(definition["short_name"])
	elif facility_id in [
		WELLNESS_NEST_ID,
		TRAINING_ROOST_ID,
		ROOSTER_OPERATIONS_OFFICE_ID,
		IT_COOP_ID,
		FLOCK_RELATIONS_OFFICE_ID,
		FEED_PROCUREMENT_COOP_ID,
		FARMER_RELATIONS_GALLERY_ID,
		FARMGATE_DISPATCH_DEPOT_ID,
	] and day < unlock_day:
		reason = "%s level %d files on Day %d; the bureau is on Day %d." % [
			String(definition["short_name"]),
			next_level,
			unlock_day,
			day,
		]
	elif not base_unlocked:
		reason = String(definition.get(
			"unlock_requirement",
			"Complete the required milestone before commissioning this facility.",
		))
	elif facility_id == FARM_MUTUAL_SERVICE_COOP_ID and market_standing < required_market_standing:
		reason = "Service Coop level %d requires %d Farm Mutual standing; the bureau has %d." % [
			next_level,
			required_market_standing,
			market_standing,
		]
	elif facility_id == FARM_MUTUAL_SERVICE_COOP_ID and current_claim_capacity() < required_claim_capacity:
		reason = "Service Coop level %d requires %d live-file roosts; the bureau has %d." % [
			next_level,
			required_claim_capacity,
			current_claim_capacity(),
		]
	elif facility_id == FARM_MUTUAL_SERVICE_COOP_ID and active_worker_count() < required_active_staff:
		reason = "Service Coop level %d requires %d active hens; the roster has %d." % [
			next_level,
			required_active_staff,
			active_worker_count(),
		]
	elif facility_id == FARM_MUTUAL_NEGOTIATION_ROOM_ID and market_standing < required_market_standing:
		reason = "The Negotiation Room requires Gold standing (%d points); the bureau has %d." % [
			required_market_standing,
			market_standing,
		]
	elif (
		facility_id == FARM_MUTUAL_NEGOTIATION_ROOM_ID
		and facility_level(FARM_MUTUAL_SERVICE_COOP_ID) < required_service_coop_level
	):
		reason = "The Negotiation Room requires Service Coop level %d; the bureau has level %d." % [
			required_service_coop_level,
			maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID)),
		]
	elif (
		facility_id in [
			WELLNESS_NEST_ID,
			TRAINING_ROOST_ID,
			ROOSTER_OPERATIONS_OFFICE_ID,
			IT_COOP_ID,
			FLOCK_RELATIONS_OFFICE_ID,
			FEED_PROCUREMENT_COOP_ID,
			FARMER_RELATIONS_GALLERY_ID,
			FARMGATE_DISPATCH_DEPOT_ID,
		]
		and office_capacity < required_office_capacity
	):
		reason = "%s level %d requires office capacity %d; the bureau authorizes %d desks." % [
			String(definition["short_name"]),
			next_level,
			required_office_capacity,
			office_capacity,
		]
	elif (
		facility_id in [
			WELLNESS_NEST_ID,
			TRAINING_ROOST_ID,
			ROOSTER_OPERATIONS_OFFICE_ID,
			IT_COOP_ID,
			FLOCK_RELATIONS_OFFICE_ID,
			FEED_PROCUREMENT_COOP_ID,
			FARMER_RELATIONS_GALLERY_ID,
			FARMGATE_DISPATCH_DEPOT_ID,
		]
		and active_worker_count() < required_active_staff
	):
		reason = "%s level %d requires %d active hens; the roster has %d." % [
			String(definition["short_name"]),
			next_level,
			required_active_staff,
			active_worker_count(),
		]
	elif (
		facility_id == TRAINING_ROOST_ID
		and facility_level(WELLNESS_NEST_ID) < required_wellness_nest_level
	):
		reason = "Training Roost level %d requires Wellness Nest level %d; the Nest is level %d." % [
			next_level,
			required_wellness_nest_level,
			facility_level(WELLNESS_NEST_ID),
		]
	elif facility_id == TRAINING_ROOST_ID and qualified_staff_count <= 0:
		reason = "Training Roost level %d requires an employed career-level %d hen." % [
			next_level,
			required_career_level,
		]
	elif (
		facility_id == IT_COOP_ID
		and facility_level(RECORDS_ANNEX_ID) < required_records_annex_level
	):
		reason = "IT Coop level %d requires Records Annex level %d; the Annex is level %d." % [
			next_level,
			required_records_annex_level,
			facility_level(RECORDS_ANNEX_ID),
		]
	elif (
		facility_id == IT_COOP_ID
		and facility_level(ROOSTER_OPERATIONS_OFFICE_ID)
		< required_rooster_operations_level
	):
		reason = "IT Coop level %d requires Rooster Office level %d; the Office is level %d." % [
			next_level,
			required_rooster_operations_level,
			facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		]
	elif (
		facility_id == FLOCK_RELATIONS_OFFICE_ID
		and facility_level(ROOSTER_OPERATIONS_OFFICE_ID)
		< required_rooster_operations_level
	):
		reason = "Flock Relations level %d requires Rooster Office level %d; the Office is level %d." % [
			next_level,
			required_rooster_operations_level,
			facility_level(ROOSTER_OPERATIONS_OFFICE_ID),
		]
	elif (
		facility_id == FLOCK_RELATIONS_OFFICE_ID
		and facility_level(WELLNESS_NEST_ID) < required_wellness_nest_level
	):
		reason = "Flock Relations level %d requires Wellness Nest level %d; the Nest is level %d." % [
			next_level,
			required_wellness_nest_level,
			facility_level(WELLNESS_NEST_ID),
		]
	elif (
		facility_id == FARMER_RELATIONS_GALLERY_ID
		and facility_level(PACKING_ANNEX_ID) < required_packing_annex_level
	):
		reason = "Credit Gallery level %d requires Packing Annex level %d; the Annex is level %d." % [
			next_level,
			required_packing_annex_level,
			facility_level(PACKING_ANNEX_ID),
		]
	elif (
		facility_id == FARMGATE_DISPATCH_DEPOT_ID
		and facility_level(PACKING_ANNEX_ID) < required_packing_annex_level
	):
		reason = "Farmgate Depot level %d requires Packing Annex level %d; the Annex is level %d." % [
			next_level,
			required_packing_annex_level,
			facility_level(PACKING_ANNEX_ID),
		]
	elif (
		facility_id == FARMGATE_DISPATCH_DEPOT_ID
		and facility_level(FARMER_RELATIONS_GALLERY_ID)
		< required_farmer_relations_gallery_level
	):
		reason = "Farmgate Depot level %d requires Harvest Credit Gallery level %d; the Gallery is level %d." % [
			next_level,
			required_farmer_relations_gallery_level,
			facility_level(FARMER_RELATIONS_GALLERY_ID),
		]
	elif (
		facility_id == FARMGATE_DISPATCH_DEPOT_ID
		and harvest_credit_standing < required_harvest_credit_standing
	):
		reason = "Farmgate Depot level %d requires %d Harvest Credit standing; the bureau has %d." % [
			next_level,
			required_harvest_credit_standing,
			harvest_credit_standing,
		]
	elif shift_phase != ShiftPhase.REVIEW:
		reason = "Capital facilities may only be commissioned during shift review."
	elif not pending_decision.is_empty():
		reason = "Resolve the closing credit memo before commissioning capital facilities."
	elif not affordable:
		reason = "Facility denied: $%.2f more spendable Feed Fund required." % (
			float(-projected_spendable) / 100.0
		)
	var level_name := _facility_level_name(definition, level)
	var next_level_name := _facility_level_name(definition, next_level)
	var current_capacity := current_claim_capacity()
	var next_claim_capacity := current_capacity
	if facility_id == RECORDS_ANNEX_ID and not maxed:
		next_claim_capacity += CLAIM_CAPACITY_PER_RECORDS_LEVEL
	var purchase_label := "FULLY COMMISSIONED"
	if not maxed:
		purchase_label = "%s LEVEL %d  ·  $%.2f" % [
			"BUILD" if level == 0 else "UPGRADE",
			next_level,
			float(cost_cents) / 100.0,
		]
	var current_wellness_level := facility_level(WELLNESS_NEST_ID)
	var current_training_level := facility_level(TRAINING_ROOST_ID)
	var preview_wellness_level := (
		next_level if facility_id == WELLNESS_NEST_ID else current_wellness_level
	)
	var preview_training_level := (
		next_level if facility_id == TRAINING_ROOST_ID else current_training_level
	)
	var current_it_coop_level := facility_level(IT_COOP_ID)
	var preview_it_coop_level := (
		next_level if facility_id == IT_COOP_ID else current_it_coop_level
	)
	var current_flock_relations_level := facility_level(FLOCK_RELATIONS_OFFICE_ID)
	var preview_flock_relations_level := (
		next_level
		if facility_id == FLOCK_RELATIONS_OFFICE_ID and not maxed else
		current_flock_relations_level
	)
	var current_flock_relations_case_capacity := _facility_level_schedule_value(
		FLOCK_RELATIONS_CASE_CAPACITY,
		current_flock_relations_level,
		0,
	)
	var next_flock_relations_case_capacity := _facility_level_schedule_value(
		FLOCK_RELATIONS_CASE_CAPACITY,
		preview_flock_relations_level,
		0,
	)
	var current_flock_relations_resolution_limit := _facility_level_schedule_value(
		FLOCK_RELATIONS_RESOLUTION_LIMITS,
		current_flock_relations_level,
		0,
	)
	var next_flock_relations_resolution_limit := _facility_level_schedule_value(
		FLOCK_RELATIONS_RESOLUTION_LIMITS,
		preview_flock_relations_level,
		0,
	)
	var current_feed_procurement_level := facility_level(FEED_PROCUREMENT_COOP_ID)
	var preview_feed_procurement_level := (
		next_level
		if facility_id == FEED_PROCUREMENT_COOP_ID and not maxed else
		current_feed_procurement_level
	)
	var current_feed_capacity_scoops := _facility_level_schedule_value(
		FEED_PROCUREMENT_CAPACITY_SCOOPS,
		current_feed_procurement_level,
		0,
	)
	var next_feed_capacity_scoops := _facility_level_schedule_value(
		FEED_PROCUREMENT_CAPACITY_SCOOPS,
		preview_feed_procurement_level,
		0,
	)
	var current_farmgate_level := facility_level(FARMGATE_DISPATCH_DEPOT_ID)
	var preview_farmgate_level := (
		next_level
		if facility_id == FARMGATE_DISPATCH_DEPOT_ID and not maxed else
		current_farmgate_level
	)
	var current_farmgate_storage := _facility_level_schedule_value(
		FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS,
		current_farmgate_level,
		0,
	)
	var next_farmgate_storage := _facility_level_schedule_value(
		FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS,
		preview_farmgate_level,
		0,
	)
	var current_farmgate_dispatch := _facility_level_schedule_value(
		FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS,
		current_farmgate_level,
		0,
	)
	var next_farmgate_dispatch := _facility_level_schedule_value(
		FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS,
		preview_farmgate_level,
		0,
	)
	return {
		"known": true,
		"id": facility_id,
		"name": String(definition["name"]),
		"short_name": String(definition["short_name"]),
		"description": String(definition["description"]),
		"cost_cents": cost_cents,
		"capital_cost_cents": cost_cents,
		"next_level_cost_cents": cost_cents,
		"daily_maintenance_cents": next_maintenance_cents,
		"current_maintenance_cents": current_maintenance_cents,
		"next_maintenance_cents": next_maintenance_cents,
		"maintenance_delta_cents": maintenance_delta_cents,
		"current_supervisor_payroll_cents": current_supervisor_payroll_cents,
		"next_supervisor_payroll_cents": next_supervisor_payroll_cents,
		"supervisor_payroll_delta_cents": supervisor_payroll_delta_cents,
		"added_daily_operating_cents": added_daily_operating_cents,
		"required_spendable_cents": required_spendable_cents,
		"spendable_fund_cents": spendable,
		"benefits": (definition.get("benefits", []) as Array).duplicate(),
		"tradeoffs": (definition.get("tradeoffs", []) as Array).duplicate(),
		"owned": installed,
		"installed": installed,
		"maxed": maxed,
		"level": level,
		"level_name": level_name,
		"next_level": next_level,
		"next_level_name": next_level_name,
		"max_level": max_level,
		"unlock_id": unlock_id,
		"unlock_day": unlock_day,
		"next_unlock_day": unlock_day,
		"unlocked": unlocked,
		"planning_open": planning_open,
		"affordable": affordable,
		"can_purchase": not maxed and unlocked and planning_open and affordable,
		"reason": reason,
		"action_reason": reason,
		"purchase_label": purchase_label,
		"projected_spendable_fund_cents": projected_spendable,
		"protected_reserve_before_cents": protected_reserve_cents(),
		"projected_protected_reserve_cents": (
			protected_reserve_cents() + added_daily_operating_cents
			if not maxed else protected_reserve_cents()
		),
		"protected_reserve_after_cents": (
			protected_reserve_cents() + added_daily_operating_cents
			if not maxed else protected_reserve_cents()
		),
		"current_claim_capacity": current_capacity,
		"next_claim_capacity": next_claim_capacity,
		"claim_capacity_delta": next_claim_capacity - current_capacity,
		"market_standing": market_standing,
		"market_standing_rank": farm_mutual_standing_rank(),
		"market_standing_rank_label": farm_mutual_standing_rank_label(),
		"required_market_standing": required_market_standing,
		"market_standing_shortfall": maxi(0, required_market_standing - market_standing),
		"required_claim_capacity": required_claim_capacity,
		"claim_capacity_shortfall": maxi(0, required_claim_capacity - current_claim_capacity()),
		"required_active_staff": required_active_staff,
		"active_staff_count": active_worker_count(),
		"active_staff_shortfall": maxi(0, required_active_staff - active_worker_count()),
		"required_office_capacity": required_office_capacity,
		"office_capacity": office_capacity,
		"office_capacity_shortfall": maxi(0, required_office_capacity - office_capacity),
		"required_service_coop_level": required_service_coop_level,
		"service_coop_level": maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID)),
		"service_coop_level_shortfall": maxi(
			0,
			required_service_coop_level - maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID)),
		),
		"required_packing_annex_level": required_packing_annex_level,
		"packing_annex_level": maxi(0, facility_level(PACKING_ANNEX_ID)),
		"packing_annex_level_shortfall": maxi(
			0,
			required_packing_annex_level - maxi(0, facility_level(PACKING_ANNEX_ID)),
		),
		"required_farmer_relations_gallery_level": required_farmer_relations_gallery_level,
		"farmer_relations_gallery_level": maxi(0, facility_level(FARMER_RELATIONS_GALLERY_ID)),
		"farmer_relations_gallery_level_shortfall": maxi(
			0,
			required_farmer_relations_gallery_level
			- maxi(0, facility_level(FARMER_RELATIONS_GALLERY_ID)),
		),
		"required_harvest_credit_standing": required_harvest_credit_standing,
		"harvest_credit_standing": harvest_credit_standing,
		"harvest_credit_standing_shortfall": maxi(
			0,
			required_harvest_credit_standing - harvest_credit_standing,
		),
		"required_records_annex_level": required_records_annex_level,
		"records_annex_level": maxi(0, facility_level(RECORDS_ANNEX_ID)),
		"records_annex_level_shortfall": maxi(
			0,
			required_records_annex_level - maxi(0, facility_level(RECORDS_ANNEX_ID)),
		),
		"required_rooster_operations_office_level": required_rooster_operations_level,
		"rooster_operations_office_level": maxi(
			0,
			current_rooster_operations_level,
		),
		"rooster_operations_office_level_shortfall": maxi(
			0,
			required_rooster_operations_level - maxi(0, current_rooster_operations_level),
		),
		"premium_bonus_basis_points": (
			level * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
			if facility_id == FARM_MUTUAL_SERVICE_COOP_ID else 0
		),
		"next_premium_bonus_basis_points": (
			next_level * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
			if facility_id == FARM_MUTUAL_SERVICE_COOP_ID else 0
		),
		"required_wellness_nest_level": required_wellness_nest_level,
		"wellness_nest_level": current_wellness_level,
		"wellness_nest_level_shortfall": maxi(
			0,
			required_wellness_nest_level - current_wellness_level,
		),
		"required_career_level": required_career_level,
		"qualified_staff_count": qualified_staff_count,
		"qualification_shortfall": (
			1 if required_career_level > 0 and qualified_staff_count <= 0 else 0
		),
		"current_strain_gain_basis_points": _facility_level_schedule_value(
			WELLNESS_STRAIN_GAIN_BASIS_POINTS,
			current_wellness_level,
			10_000,
		),
		"next_strain_gain_basis_points": _facility_level_schedule_value(
			WELLNESS_STRAIN_GAIN_BASIS_POINTS,
			preview_wellness_level,
			10_000,
		),
		"current_break_recovery_basis_points": _facility_level_schedule_value(
			WELLNESS_BREAK_RECOVERY_BASIS_POINTS,
			current_wellness_level,
			10_000,
		),
		"next_break_recovery_basis_points": _facility_level_schedule_value(
			WELLNESS_BREAK_RECOVERY_BASIS_POINTS,
			preview_wellness_level,
			10_000,
		),
		"current_career_sponsorship_cost_cents": _facility_level_schedule_value(
			TRAINING_SPONSORSHIP_COSTS_CENTS,
			current_training_level,
			CAREER_SPONSORSHIP_COST_CENTS,
		),
		"next_career_sponsorship_cost_cents": _facility_level_schedule_value(
			TRAINING_SPONSORSHIP_COSTS_CENTS,
			preview_training_level,
			CAREER_SPONSORSHIP_COST_CENTS,
		),
		"current_training_work_basis_points": _facility_level_schedule_value(
			TRAINING_WORK_BASIS_POINTS,
			current_training_level,
			8500,
		),
		"next_training_work_basis_points": _facility_level_schedule_value(
			TRAINING_WORK_BASIS_POINTS,
			preview_training_level,
			8500,
		),
		"current_career_coaching_xp_bonus": _facility_level_schedule_value(
			TRAINING_COACHING_XP_BONUS,
			current_training_level,
			0,
		),
		"next_career_coaching_xp_bonus": _facility_level_schedule_value(
			TRAINING_COACHING_XP_BONUS,
			preview_training_level,
			0,
		),
		"current_personnel_action_limit": _facility_level_schedule_value(
			ROOSTER_PERSONNEL_ACTION_LIMITS,
			current_rooster_operations_level,
			1,
		),
		"next_personnel_action_limit": _facility_level_schedule_value(
			ROOSTER_PERSONNEL_ACTION_LIMITS,
			preview_rooster_operations_level,
			1,
		),
		"current_surveillance_grievance_millipoints": _facility_level_schedule_value(
			ROOSTER_SURVEILLANCE_GRIEVANCE_MILLIPOINTS,
			current_rooster_operations_level,
			0,
		),
		"next_surveillance_grievance_millipoints": _facility_level_schedule_value(
			ROOSTER_SURVEILLANCE_GRIEVANCE_MILLIPOINTS,
			preview_rooster_operations_level,
			0,
		),
		"current_surveillance_stress_millipoints": _facility_level_schedule_value(
			ROOSTER_SURVEILLANCE_STRESS_MILLIPOINTS,
			current_rooster_operations_level,
			0,
		),
		"next_surveillance_stress_millipoints": _facility_level_schedule_value(
			ROOSTER_SURVEILLANCE_STRESS_MILLIPOINTS,
			preview_rooster_operations_level,
			0,
		),
		"current_surveillance_solidarity_millipoints": _facility_level_schedule_value(
			ROOSTER_SURVEILLANCE_SOLIDARITY_MILLIPOINTS,
			current_rooster_operations_level,
			0,
		),
		"next_surveillance_solidarity_millipoints": _facility_level_schedule_value(
			ROOSTER_SURVEILLANCE_SOLIDARITY_MILLIPOINTS,
			preview_rooster_operations_level,
			0,
		),
		"current_automation_work_basis_points": _facility_level_schedule_value(
			IT_AUTO_WORK_BASIS_POINTS,
			current_it_coop_level,
			10_000,
		),
		"next_automation_work_basis_points": _facility_level_schedule_value(
			IT_AUTO_WORK_BASIS_POINTS,
			preview_it_coop_level,
			10_000,
		),
		"current_automation_specialty_grace_minutes": _facility_level_schedule_value(
			IT_AUTO_SPECIALTY_GRACE_MINUTES,
			current_it_coop_level,
			AUTO_SPECIALTY_GRACE_MINUTES,
		),
		"next_automation_specialty_grace_minutes": _facility_level_schedule_value(
			IT_AUTO_SPECIALTY_GRACE_MINUTES,
			preview_it_coop_level,
			AUTO_SPECIALTY_GRACE_MINUTES,
		),
		"current_automation_compliance_exposure_millipoints": _facility_level_schedule_value(
			IT_COMPLIANCE_EXPOSURE_MILLIPOINTS,
			current_it_coop_level,
			0,
		),
		"next_automation_compliance_exposure_millipoints": _facility_level_schedule_value(
			IT_COMPLIANCE_EXPOSURE_MILLIPOINTS,
			preview_it_coop_level,
			0,
		),
		"current_ledger_molt_patch_cost_cents": _facility_level_schedule_value(
			IT_LEDGER_PATCH_COSTS_CENTS,
			current_it_coop_level,
			1800,
		),
		"next_ledger_molt_patch_cost_cents": _facility_level_schedule_value(
			IT_LEDGER_PATCH_COSTS_CENTS,
			preview_it_coop_level,
			1800,
		),
		"current_flock_relations_case_capacity": current_flock_relations_case_capacity,
		"next_flock_relations_case_capacity": next_flock_relations_case_capacity,
		"flock_relations_case_capacity_delta": (
			next_flock_relations_case_capacity - current_flock_relations_case_capacity
		),
		"current_flock_relations_resolution_limit": current_flock_relations_resolution_limit,
		"next_flock_relations_resolution_limit": next_flock_relations_resolution_limit,
		"flock_relations_resolution_limit_delta": (
			next_flock_relations_resolution_limit - current_flock_relations_resolution_limit
		),
		"current_feed_capacity_scoops": current_feed_capacity_scoops,
		"next_feed_capacity_scoops": next_feed_capacity_scoops,
		"feed_capacity_delta_scoops": next_feed_capacity_scoops - current_feed_capacity_scoops,
		"current_farmgate_storage_capacity_eggs": current_farmgate_storage,
		"next_farmgate_storage_capacity_eggs": next_farmgate_storage,
		"farmgate_storage_capacity_delta_eggs": next_farmgate_storage - current_farmgate_storage,
		"current_farmgate_dispatch_capacity_eggs": current_farmgate_dispatch,
		"next_farmgate_dispatch_capacity_eggs": next_farmgate_dispatch,
		"farmgate_dispatch_capacity_delta_eggs": next_farmgate_dispatch - current_farmgate_dispatch,
	}


func _facility_cost_for_level(definition: Dictionary, target_level: int) -> int:
	if target_level <= 0:
		return 0
	var scheduled_costs: Variant = definition.get("level_costs_cents", null)
	if scheduled_costs is Array:
		var costs := scheduled_costs as Array
		var index := target_level - 1
		if index >= 0 and index < costs.size():
			return maxi(0, int(costs[index]))
	return maxi(0, int(definition.get("cost_cents", 0)))


func _facility_maintenance_for_level(definition: Dictionary, target_level: int) -> int:
	if target_level <= 0:
		return 0
	var schedule_value: Variant = definition.get("maintenance_by_level_cents", null)
	if schedule_value is Array:
		var schedule := schedule_value as Array
		if target_level >= 0 and target_level < schedule.size():
			return maxi(0, int(schedule[target_level]))
	return maxi(0, target_level) * maxi(
		0,
		int(definition.get("daily_maintenance_cents", 0)),
	)


func _facility_level_name(definition: Dictionary, target_level: int) -> String:
	if target_level <= 0:
		return "LEASE OPTION"
	var names_value: Variant = definition.get("level_names", null)
	if names_value is Array:
		var names := names_value as Array
		var index := target_level - 1
		if index >= 0 and index < names.size():
			return String(names[index])
	return "LEVEL %d" % target_level


func _neutral_campus_expansion_state() -> Dictionary:
	return {
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


func _campus_services_for_state(state: Dictionary) -> Dictionary:
	var value: Variant = state.get("services", {})
	return value as Dictionary if value is Dictionary else {}


func _campus_service_owned_for_state(state: Dictionary, service_id: StringName) -> bool:
	var services := _campus_services_for_state(state)
	return bool(services.get(String(service_id), services.get(service_id, false)))


func _campus_socket_is_valid(socket_id: StringName) -> bool:
	return (
		CAMPUS_SOCKET_DEFINITIONS.has(socket_id)
		and not bool((CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary).get("route_blocked", false))
	)


func _campus_pod_operational_for_state(state: Dictionary) -> bool:
	var socket_id := StringName(String(state.get("pod_socket_id", "")))
	return (
		bool(state.get("parcel_owned", false))
		and bool(state.get("pod_owned", false))
		and _campus_socket_is_valid(socket_id)
		and _campus_service_owned_for_state(state, &"circulation")
		and _campus_service_owned_for_state(state, &"power")
	)


func _campus_cold_chain_active_for_state(state: Dictionary) -> bool:
	return (
		_campus_pod_operational_for_state(state)
		and _campus_service_owned_for_state(state, &"cold_chain")
	)


func _campus_claim_capacity_bonus_for_state(state: Dictionary) -> int:
	return CAMPUS_CLAIM_CAPACITY_BONUS if _campus_pod_operational_for_state(state) else 0


func _campus_farmgate_capacity_bonus_for_state(
	state: Dictionary,
	farmgate_level: int,
) -> int:
	return (
		CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if farmgate_level > 0 and _campus_cold_chain_active_for_state(state) else
		0
	)


func _campus_daily_cost_for_state(state: Dictionary) -> int:
	var total := 0
	if bool(state.get("parcel_owned", false)):
		total += int((CAMPUS_PARCEL_DEFINITIONS[CAMPUS_PARCEL_ID] as Dictionary)["daily_cost_cents"])
	for service_id in CAMPUS_SERVICE_ORDER:
		if _campus_service_owned_for_state(state, service_id):
			total += int((CAMPUS_SERVICE_DEFINITIONS[service_id] as Dictionary)["daily_cost_cents"])
	if bool(state.get("pod_owned", false)):
		total += int((CAMPUS_MODULE_DEFINITIONS[CAMPUS_MODULE_ID] as Dictionary)["daily_cost_cents"])
	return total


func current_daily_campus_cost_cents() -> int:
	return _campus_daily_cost_for_state(campus_expansion_state)


func _campus_access_gate_met() -> bool:
	return (
		facility_level(FARMGATE_DISPATCH_DEPOT_ID) >= 1
		or farm_mutual_standing() >= CAMPUS_EXPANSION_STANDING_REQUIREMENT
	)


func _campus_access_gate_reason() -> String:
	if _campus_access_gate_met():
		return ""
	return (
		"Commission Farmgate Dispatch Depot level 1 or earn Bronze Farm Mutual standing "
		+ "(%d points) before purchasing North Meadow." % CAMPUS_EXPANSION_STANDING_REQUIREMENT
	)


func _campus_action_terms(action_id: StringName, item_id: StringName) -> Dictionary:
	match action_id:
		&"purchase_parcel":
			if item_id != CAMPUS_PARCEL_ID:
				return {}
			var parcel := CAMPUS_PARCEL_DEFINITIONS[CAMPUS_PARCEL_ID] as Dictionary
			return {
				"name": String(parcel["name"]),
				"cost_cents": int(parcel["capital_cost_cents"]),
				"added_daily_cost_cents": int(parcel["daily_cost_cents"]),
			}
		&"commission_service":
			if not CAMPUS_SERVICE_DEFINITIONS.has(item_id):
				return {}
			var service := CAMPUS_SERVICE_DEFINITIONS[item_id] as Dictionary
			return {
				"name": String(service["name"]),
				"cost_cents": int(service["capital_cost_cents"]),
				"added_daily_cost_cents": int(service["daily_cost_cents"]),
			}
		&"place_module":
			if item_id != CAMPUS_MODULE_ID:
				return {}
			var module := CAMPUS_MODULE_DEFINITIONS[CAMPUS_MODULE_ID] as Dictionary
			return {
				"name": String(module["name"]),
				"cost_cents": int(module["capital_cost_cents"]),
				"added_daily_cost_cents": int(module["daily_cost_cents"]),
			}
		&"relocate_module":
			if item_id != CAMPUS_MODULE_ID:
				return {}
			var module := CAMPUS_MODULE_DEFINITIONS[CAMPUS_MODULE_ID] as Dictionary
			return {
				"name": String(module["name"]),
				"cost_cents": int(module["relocation_cost_cents"]),
				"added_daily_cost_cents": 0,
			}
	return {}


func _campus_state_action_reason(
	state: Dictionary,
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName,
) -> String:
	if _campus_action_terms(action_id, item_id).is_empty():
		return "This campus action is not on the authorized North Meadow schedule."
	match action_id:
		&"purchase_parcel":
			if bool(state.get("parcel_owned", false)):
				return "North Meadow is already owned."
		&"commission_service":
			if not bool(state.get("parcel_owned", false)):
				return "Purchase North Meadow before commissioning its services."
			if _campus_service_owned_for_state(state, item_id):
				return "%s is already commissioned." % String(
					(CAMPUS_SERVICE_DEFINITIONS[item_id] as Dictionary)["name"]
				)
		&"place_module":
			if not bool(state.get("parcel_owned", false)):
				return "Purchase North Meadow before placing the Egg Routing Pod."
			if bool(state.get("pod_owned", false)):
				return "The Egg Routing Pod is already placed; file a relocation instead."
			if not CAMPUS_SOCKET_DEFINITIONS.has(socket_id):
				return "Select a listed North Meadow placement socket."
			var socket := CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary
			if bool(socket.get("route_blocked", false)):
				return String(socket.get("blocked_reason", "This socket blocks a protected route."))
		&"relocate_module":
			if not bool(state.get("parcel_owned", false)) or not bool(state.get("pod_owned", false)):
				return "Place the Egg Routing Pod before filing a relocation."
			if not CAMPUS_SOCKET_DEFINITIONS.has(socket_id):
				return "Select a listed North Meadow placement socket."
			var socket := CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary
			if bool(socket.get("route_blocked", false)):
				return String(socket.get("blocked_reason", "This socket blocks a protected route."))
			if StringName(String(state.get("pod_socket_id", ""))) == socket_id:
				return "The Egg Routing Pod already occupies this socket."
	return ""


func _apply_campus_action_to_state(
	state: Dictionary,
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName,
) -> void:
	match action_id:
		&"purchase_parcel":
			state["parcel_owned"] = true
		&"commission_service":
			var services := _campus_services_for_state(state).duplicate(true)
			services[String(item_id)] = true
			state["services"] = services
		&"place_module":
			state["pod_owned"] = true
			state["pod_socket_id"] = String(socket_id)
		&"relocate_module":
			state["pod_socket_id"] = String(socket_id)


func _campus_action_outcome(
	action_id: StringName,
	item_id: StringName,
	from_socket_id: StringName,
	socket_id: StringName,
) -> String:
	match action_id:
		&"purchase_parcel":
			return "North Meadow was added to the bureau's taxable definition of open space."
		&"commission_service":
			return "%s commissioned with its recurring obligation attached." % String(
				(CAMPUS_SERVICE_DEFINITIONS[item_id] as Dictionary)["name"]
			)
		&"place_module":
			return "Egg Routing Pod placed at %s; benefits wait for circulation and power." % String(
				(CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary)["name"]
			)
		&"relocate_module":
			return "Egg Routing Pod relocated from %s to %s without changing daily upkeep." % [
				String((CAMPUS_SOCKET_DEFINITIONS[from_socket_id] as Dictionary)["name"]),
				String((CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary)["name"]),
			]
	return "North Meadow filing completed."


func campus_expansion_action_quote(
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName = &"",
) -> Dictionary:
	var terms := _campus_action_terms(action_id, item_id)
	var state_reason := _campus_state_action_reason(
		campus_expansion_state,
		action_id,
		item_id,
		socket_id,
	)
	var preview_state := campus_expansion_state.duplicate(true)
	if state_reason.is_empty():
		_apply_campus_action_to_state(preview_state, action_id, item_id, socket_id)
	var cost_cents := int(terms.get("cost_cents", 0))
	var added_daily_cost_cents := int(terms.get("added_daily_cost_cents", 0))
	var projected_spendable := _projected_spendable_after_obligation_change_cents(
		cost_cents,
		added_daily_cost_cents,
	)
	var reason := state_reason
	if reason.is_empty() and action_id == &"purchase_parcel":
		reason = _campus_access_gate_reason()
	if reason.is_empty() and day < CAMPUS_EXPANSION_UNLOCK_DAY:
		reason = "North Meadow filings become visible on Day %d." % CAMPUS_EXPANSION_UNLOCK_DAY
	if reason.is_empty() and not staffing_planning_open():
		reason = "North Meadow filings may only be authorized during clear review planning."
	if reason.is_empty() and (campus_expansion_state.get("history", []) as Array).size() >= CAMPUS_EXPANSION_HISTORY_LIMIT:
		reason = "The North Meadow receipt archive is full."
	if reason.is_empty() and (revenue_cents < cost_cents or projected_spendable < 0):
		reason = "The Feed Fund cannot cover this filing and its next recurring obligation."
	var current_farmgate_level := facility_level(FARMGATE_DISPATCH_DEPOT_ID)
	return {
		"accepted": false,
		"known": not terms.is_empty(),
		"action_id": action_id,
		"item_id": item_id,
		"socket_id": socket_id,
		"name": String(terms.get("name", "UNKNOWN CAMPUS FILING")),
		"can_authorize": reason.is_empty(),
		"ready": reason.is_empty(),
		"reason": reason,
		"cost_cents": cost_cents,
		"added_daily_cost_cents": added_daily_cost_cents,
		"current_daily_cost_cents": _campus_daily_cost_for_state(campus_expansion_state),
		"projected_daily_cost_cents": _campus_daily_cost_for_state(preview_state),
		"fund_before_cents": revenue_cents,
		"spendable_before_cents": spendable_fund_cents(),
		"required_spendable_cents": _required_spendable_for_obligation_change_cents(
			cost_cents,
			added_daily_cost_cents,
		),
		"projected_spendable_cents": projected_spendable,
		"claim_capacity_before": current_claim_capacity(),
		"claim_capacity_after": (
			_claim_capacity_for_facilities(owned_facilities)
			+ _campus_claim_capacity_bonus_for_state(preview_state)
		),
		"farmgate_capacity_before": _farmgate_storage_capacity_eggs(),
		"farmgate_capacity_after": _farmgate_storage_capacity_for_level_and_campus(
			current_farmgate_level,
			preview_state,
		),
	}


func _authorize_campus_expansion_action(
	action_id: StringName,
	item_id: StringName,
	socket_id: StringName = &"",
) -> Dictionary:
	var quote := campus_expansion_action_quote(action_id, item_id, socket_id)
	if not bool(quote.get("can_authorize", false)):
		return quote
	var from_socket_id := StringName(String(campus_expansion_state.get("pod_socket_id", "")))
	var cost_cents := int(quote["cost_cents"])
	var fund_before := revenue_cents
	var daily_before := _campus_daily_cost_for_state(campus_expansion_state)
	var claim_bonus_before := _campus_claim_capacity_bonus_for_state(campus_expansion_state)
	var farmgate_bonus_before := (
		CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if _campus_cold_chain_active_for_state(campus_expansion_state) else
		0
	)
	revenue_cents -= cost_cents
	_apply_campus_action_to_state(campus_expansion_state, action_id, item_id, socket_id)
	var outcome := _campus_action_outcome(action_id, item_id, from_socket_id, socket_id)
	var access_gate_id: StringName = &""
	var access_standing_points := 0
	var access_farmgate_level := 0
	if action_id == &"purchase_parcel":
		access_farmgate_level = maxi(0, facility_level(FARMGATE_DISPATCH_DEPOT_ID))
		access_standing_points = maxi(0, farm_mutual_standing())
		access_gate_id = &"farmgate_dispatch" if access_farmgate_level >= 1 else &"farm_mutual_standing"
	var receipt := {
		"accepted": true,
		"receipt_id": int(campus_expansion_state.get("next_receipt_id", 1)),
		"day": day,
		"action_id": action_id,
		"item_id": item_id,
		"socket_id": socket_id,
		"from_socket_id": from_socket_id,
		"cost_cents": cost_cents,
		"added_daily_cost_cents": int(quote["added_daily_cost_cents"]),
		"fund_before_cents": fund_before,
		"fund_after_cents": revenue_cents,
		"daily_cost_before_cents": daily_before,
		"daily_cost_after_cents": _campus_daily_cost_for_state(campus_expansion_state),
		"claim_capacity_bonus_before": claim_bonus_before,
		"claim_capacity_bonus_after": _campus_claim_capacity_bonus_for_state(campus_expansion_state),
		"farmgate_capacity_bonus_before": farmgate_bonus_before,
		"farmgate_capacity_bonus_after": (
			CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
			if _campus_cold_chain_active_for_state(campus_expansion_state) else
			0
		),
		"access_gate_id": access_gate_id,
		"access_standing_points": access_standing_points,
		"access_farmgate_level": access_farmgate_level,
		"reason": "",
		"outcome": outcome,
	}
	campus_expansion_state["next_receipt_id"] = int(receipt["receipt_id"]) + 1
	campus_expansion_state["capital_spend_total_cents"] = (
		int(campus_expansion_state.get("capital_spend_total_cents", 0)) + cost_cents
	)
	var history := (campus_expansion_state.get("history", []) as Array).duplicate(true)
	history.append(receipt.duplicate(true))
	campus_expansion_state["history"] = history
	campus_expansion_state["last_receipt"] = receipt.duplicate(true)
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	var result := receipt.duplicate(true)
	result["campus_expansion"] = campus_expansion_snapshot()
	return result


func purchase_campus_parcel(parcel_id: StringName = CAMPUS_PARCEL_ID) -> Dictionary:
	return _authorize_campus_expansion_action(&"purchase_parcel", parcel_id)


func commission_campus_service(service_id: StringName) -> Dictionary:
	return _authorize_campus_expansion_action(&"commission_service", service_id)


func place_campus_module(module_id: StringName, socket_id: StringName) -> Dictionary:
	return _authorize_campus_expansion_action(&"place_module", module_id, socket_id)


func relocate_campus_module(module_id: StringName, socket_id: StringName) -> Dictionary:
	return _authorize_campus_expansion_action(&"relocate_module", module_id, socket_id)


func campus_expansion_snapshot() -> Dictionary:
	var sockets: Array[Dictionary] = []
	var placed_socket := StringName(String(campus_expansion_state.get("pod_socket_id", "")))
	var any_socket_can_place := false
	var any_socket_can_relocate := false
	var placement_reason := "No cleared North Meadow socket is currently available."
	var relocation_reason := "Place the Egg Routing Pod before filing a relocation."
	for socket_id in CAMPUS_SOCKET_ORDER:
		var definition := CAMPUS_SOCKET_DEFINITIONS[socket_id] as Dictionary
		var placement_quote := campus_expansion_action_quote(
			&"place_module",
			CAMPUS_MODULE_ID,
			socket_id,
		)
		var relocation_quote := campus_expansion_action_quote(
			&"relocate_module",
			CAMPUS_MODULE_ID,
			socket_id,
		)
		var can_place := bool(placement_quote.get("can_authorize", false))
		var can_relocate := bool(relocation_quote.get("can_authorize", false))
		if can_place:
			any_socket_can_place = true
			placement_reason = ""
		elif not any_socket_can_place and not bool(definition["route_blocked"]):
			placement_reason = String(placement_quote.get("reason", placement_reason))
		if can_relocate:
			any_socket_can_relocate = true
			relocation_reason = ""
		elif not any_socket_can_relocate and not bool(definition["route_blocked"]):
			relocation_reason = String(relocation_quote.get("reason", relocation_reason))
		sockets.append({
			"id": socket_id,
			"name": String(definition["name"]),
			"route_blocked": bool(definition["route_blocked"]),
			"blocked_reason": String(definition["blocked_reason"]),
			"placement_valid": not bool(definition["route_blocked"]),
			"occupied": placed_socket == socket_id,
			"module_id": CAMPUS_MODULE_ID if placed_socket == socket_id else &"",
			"can_place": can_place,
			"can_relocate": can_relocate,
			"placement_cost_cents": int(placement_quote.get("cost_cents", 0)),
			"placement_recurring_cost_cents": int(
				placement_quote.get("added_daily_cost_cents", 0)
			),
			"relocation_cost_cents": int(relocation_quote.get("cost_cents", 0)),
			"placement_reason": String(placement_quote.get("reason", "")),
			"relocation_reason": String(relocation_quote.get("reason", "")),
			"reason": (
				String(definition["blocked_reason"])
				if bool(definition["route_blocked"]) else
				String(placement_quote.get("reason", ""))
			),
			"placement_quote": placement_quote,
			"relocation_quote": relocation_quote,
		})
	var services: Array[Dictionary] = []
	for service_id in CAMPUS_SERVICE_ORDER:
		var definition := CAMPUS_SERVICE_DEFINITIONS[service_id] as Dictionary
		var service_quote := campus_expansion_action_quote(&"commission_service", service_id)
		var connected := _campus_service_owned_for_state(campus_expansion_state, service_id)
		services.append({
			"id": service_id,
			"name": String(definition["name"]),
			"commissioned": connected,
			"connected": connected,
			"can_connect": bool(service_quote.get("can_authorize", false)),
			"reason": String(service_quote.get("reason", "")),
			"required_for_pod": bool(definition["required_for_pod"]),
			"capital_cost_cents": int(definition["capital_cost_cents"]),
			"daily_cost_cents": int(definition["daily_cost_cents"]),
			"quote": service_quote,
		})
	var parcel_definition := CAMPUS_PARCEL_DEFINITIONS[CAMPUS_PARCEL_ID] as Dictionary
	var parcel_quote := campus_expansion_action_quote(&"purchase_parcel", CAMPUS_PARCEL_ID)
	var parcel_owned := bool(campus_expansion_state.get("parcel_owned", false))
	var pod_owned := bool(campus_expansion_state.get("pod_owned", false))
	var pod_definition := CAMPUS_MODULE_DEFINITIONS[CAMPUS_MODULE_ID] as Dictionary
	var circulation_connected := _campus_service_owned_for_state(
		campus_expansion_state,
		&"circulation",
	)
	var power_connected := _campus_service_owned_for_state(campus_expansion_state, &"power")
	var cold_chain_connected := _campus_service_owned_for_state(
		campus_expansion_state,
		&"cold_chain",
	)
	var pod_operational := _campus_pod_operational_for_state(campus_expansion_state)
	var cold_chain_active := _campus_cold_chain_active_for_state(campus_expansion_state)
	var claim_bonus := _campus_claim_capacity_bonus_for_state(campus_expansion_state)
	var farmgate_bonus := _campus_farmgate_capacity_bonus_for_state(
		campus_expansion_state,
		facility_level(FARMGATE_DISPATCH_DEPOT_ID),
	)
	var construction_stage: StringName = &"access"
	if parcel_owned:
		construction_stage = &"site_work"
	if parcel_owned and circulation_connected and power_connected:
		construction_stage = &"services_ready"
	if pod_owned:
		construction_stage = &"pod_placed"
	if pod_operational:
		construction_stage = &"operational"
	if cold_chain_active:
		construction_stage = &"cold_chain_operational"
	var construction_stages: Array[Dictionary] = [
		{
			"id": &"parcel_deed",
			"label": "PARCEL DEED",
			"status": (
				&"complete" if parcel_owned else
				&"active" if bool(parcel_quote.get("can_authorize", false)) else
				&"pending"
			),
			"complete": parcel_owned,
			"detail": (
				"North Meadow deed filed."
				if parcel_owned else
				String(parcel_quote.get("reason", "North Meadow deed held."))
			),
			"cost_cents": int(parcel_definition["capital_cost_cents"]),
		},
		{
			"id": &"circulation_link",
			"label": "FLOCK CIRCULATION",
			"status": &"complete" if circulation_connected else &"active" if parcel_owned else &"pending",
			"complete": circulation_connected,
			"detail": "Circulation connected." if circulation_connected else "Commission after the parcel deed.",
			"cost_cents": int((CAMPUS_SERVICE_DEFINITIONS[&"circulation"] as Dictionary)["capital_cost_cents"]),
		},
		{
			"id": &"power_drop",
			"label": "COOP POWER",
			"status": &"complete" if power_connected else &"active" if parcel_owned else &"pending",
			"complete": power_connected,
			"detail": "Power connected." if power_connected else "Commission after the parcel deed.",
			"cost_cents": int((CAMPUS_SERVICE_DEFINITIONS[&"power"] as Dictionary)["capital_cost_cents"]),
		},
		{
			"id": &"pod_pad",
			"label": "EGG ROUTING POD",
			"status": &"complete" if pod_owned else &"active" if parcel_owned else &"pending",
			"complete": pod_owned,
			"detail": (
				"Installed at %s." % String(placed_socket).replace("_", " ").to_upper()
				if pod_owned else
				placement_reason
			),
			"cost_cents": int(pod_definition["capital_cost_cents"]),
		},
		{
			"id": &"commissioning",
			"label": "POD COMMISSIONING",
			"status": &"complete" if pod_operational else &"active" if pod_owned else &"pending",
			"complete": pod_operational,
			"detail": (
				"Routing pod operational."
				if pod_operational else
				"Requires parcel, placement, circulation, and power."
			),
		},
		{
			"id": &"cold_chain",
			"label": "COLD-CHAIN LOOP",
			"status": &"complete" if cold_chain_active else &"active" if parcel_owned else &"pending",
			"complete": cold_chain_active,
			"detail": (
				"Farmgate storage extension active."
				if cold_chain_active else
				"Optional service; its storage benefit waits for pod commissioning."
			),
			"cost_cents": int((CAMPUS_SERVICE_DEFINITIONS[&"cold_chain"] as Dictionary)["capital_cost_cents"]),
		},
	]
	var operational_benefits: Array[String] = [
		"LIVE CLAIM CAPACITY  +%d FILES%s" % [claim_bonus, " / ACTIVE" if claim_bonus > 0 else " / HELD"],
		"FARMGATE FINISHED-EGG STORAGE  +%d EGGS%s" % [farmgate_bonus, " / ACTIVE" if farmgate_bonus > 0 else " / HELD"],
	]
	var routing_pod := {
		"id": CAMPUS_MODULE_ID,
		"name": String(pod_definition["name"]),
		"placed": pod_owned,
		"owned": pod_owned,
		"current_socket_id": placed_socket,
		"capital_cost_cents": int(pod_definition["capital_cost_cents"]),
		"relocation_cost_cents": int(pod_definition["relocation_cost_cents"]),
		"daily_cost_cents": int(pod_definition["daily_cost_cents"]),
		"can_place": any_socket_can_place,
		"can_relocate": any_socket_can_relocate,
		"placement_reason": placement_reason,
		"relocation_reason": relocation_reason,
		"operational": pod_operational,
	}
	return {
		"id": &"campus_expansion",
		"visible": day >= CAMPUS_EXPANSION_UNLOCK_DAY,
		"unlock_day": CAMPUS_EXPANSION_UNLOCK_DAY,
		"access_gate_met": _campus_access_gate_met(),
		"access_gate_reason": _campus_access_gate_reason(),
		"access_standing_requirement": CAMPUS_EXPANSION_STANDING_REQUIREMENT,
		"parcel_id": CAMPUS_PARCEL_ID,
		"parcel_owned": parcel_owned,
		"parcel_quote": parcel_quote,
		"parcel": {
			"id": CAMPUS_PARCEL_ID,
			"name": String(parcel_definition["name"]),
			"owned": parcel_owned,
			"can_purchase": bool(parcel_quote.get("can_authorize", false)),
			"capital_cost_cents": int(parcel_definition["capital_cost_cents"]),
			"daily_cost_cents": int(parcel_definition["daily_cost_cents"]),
			"reason": String(parcel_quote.get("reason", "")),
			"quote": parcel_quote,
		},
		"services": services,
		"sockets": sockets,
		"module_id": CAMPUS_MODULE_ID,
		"pod_owned": pod_owned,
		"pod_socket_id": placed_socket,
		"pod_operational": pod_operational,
		"routing_pod": routing_pod,
		"cold_chain_connected": cold_chain_connected,
		"cold_chain_active": cold_chain_active,
		"claim_capacity_bonus": claim_bonus,
		"farmgate_capacity_bonus_eggs": farmgate_bonus,
		"construction_stage": construction_stage,
		"construction_stages": construction_stages,
		"operational_benefits": operational_benefits,
		"summary": "NORTH MEADOW / %s / POD %s" % [
			String(construction_stage).replace("_", " ").to_upper(),
			"OPERATIONAL" if pod_operational else "HELD",
		],
		"current_daily_cost_cents": current_daily_campus_cost_cents(),
		"capital_spend_total_cents": int(campus_expansion_state.get("capital_spend_total_cents", 0)),
		"next_receipt_id": int(campus_expansion_state.get("next_receipt_id", 1)),
		"last_receipt": (campus_expansion_state.get("last_receipt", {}) as Dictionary).duplicate(true),
		"history": (campus_expansion_state.get("history", []) as Array).duplicate(true),
	}


func _campus_portfolio_context(
	planning_override: Variant = null,
	worker_id_override: Array = [],
	worker_name_override: Dictionary = {},
	campus_state_override: Dictionary = {},
	target_day: int = -1,
) -> Dictionary:
	var source_campus := campus_expansion_state if campus_state_override.is_empty() else campus_state_override
	var grid_active := (
		bool(source_campus.get("parcel_owned", false))
		and _campus_service_owned_for_state(source_campus, &"circulation")
		and _campus_service_owned_for_state(source_campus, &"power")
	)
	var cold_active := grid_active and _campus_service_owned_for_state(source_campus, &"cold_chain")
	var valid_worker_ids: Array[int] = []
	var worker_names: Dictionary = {}
	if worker_id_override.is_empty():
		for worker in workers:
			if not worker.employed:
				continue
			valid_worker_ids.append(worker.id)
			worker_names[worker.id] = worker.display_name
	else:
		for raw_worker_id: Variant in worker_id_override:
			if _is_integral_number(raw_worker_id):
				valid_worker_ids.append(int(raw_worker_id))
		worker_names = worker_name_override.duplicate(true)
	return {
		"day": day if target_day < 0 else target_day,
		"planning_open": (
			staffing_planning_open()
			if planning_override == null else
			bool(planning_override)
		),
		# North Meadow's commissioned utility trunk is deliberately large enough
		# for the four authored portfolio modules, but every project reserves its
		# exact share at authorization so the player cannot overbook it.
		"power_capacity_units": 5 if grid_active else 0,
		"cold_capacity_units": 2 if cold_active else 0,
		"valid_worker_ids": valid_worker_ids,
		"worker_names": worker_names,
		"can_fund": true,
	}


func campus_portfolio_deed_quote(parcel_id: StringName) -> Dictionary:
	var context := _campus_portfolio_context()
	var quote: Dictionary = _campus_portfolio.quote_deed(parcel_id, context)
	return _enriched_campus_portfolio_quote(
		quote,
		_campus_portfolio_finance_basis(),
		&"deed",
	)


func purchase_campus_portfolio_deed(parcel_id: StringName) -> Dictionary:
	var quote := campus_portfolio_deed_quote(parcel_id)
	if not bool(quote.get("can_authorize", false)):
		return quote
	var fund_before := revenue_cents
	var result: Dictionary = _campus_portfolio.authorize_deed(
		parcel_id,
		day,
		_campus_portfolio_context(),
	)
	if not bool(result.get("accepted", false)):
		return result
	var cost := int(quote.get("cost_cents", 0))
	revenue_cents -= cost
	result["fund_before_cents"] = fund_before
	result["fund_after_cents"] = revenue_cents
	result["projected_spendable_fund_cents"] = int(quote.get("projected_spendable_fund_cents", 0))
	result["campus_portfolio"] = campus_portfolio_snapshot()
	snapshot_changed.emit(snapshot())
	return result


func campus_portfolio_project_quote(module_id: StringName, pad_id: StringName) -> Dictionary:
	var context := _campus_portfolio_context()
	var quote: Dictionary = _campus_portfolio.quote_project(module_id, pad_id, context)
	return _enriched_campus_portfolio_quote(
		quote,
		_campus_portfolio_finance_basis(),
		&"module",
	)


func _campus_portfolio_finance_basis() -> Dictionary:
	var protected := protected_reserve_cents()
	return {
		"revenue_cents": revenue_cents,
		"protected_reserve_cents": protected,
		"spendable_fund_cents": maxi(0, revenue_cents - protected),
	}


func _enriched_campus_portfolio_quote(
	raw_quote: Dictionary,
	finance_basis: Dictionary,
	kind: StringName,
) -> Dictionary:
	var quote := raw_quote.duplicate(true)
	var cost := maxi(0, int(quote.get("cost_cents", 0)))
	var added_daily := maxi(0, int(quote.get("added_daily_cost_cents", 0)))
	var protected := maxi(0, int(finance_basis.get("protected_reserve_cents", 0)))
	var fund := maxi(0, int(finance_basis.get("revenue_cents", revenue_cents)))
	var projected_spendable := fund - protected - cost - added_daily
	if bool(quote.get("can_authorize", false)) and projected_spendable < 0:
		quote["can_authorize"] = false
		quote["ready"] = false
		quote["reason"] = (
			"The Feed Fund is $%.2f short after protecting this deed's first land obligation."
			% (float(-projected_spendable) / 100.0)
			if kind == &"deed" else
			"The Feed Fund is $%.2f short after protecting this module's completed upkeep."
			% (float(-projected_spendable) / 100.0)
		)
	quote["required_spendable_cents"] = cost + added_daily
	quote["projected_spendable_fund_cents"] = projected_spendable
	quote["current_spendable_fund_cents"] = int(finance_basis.get(
		"spendable_fund_cents",
		maxi(0, fund - protected),
	))
	quote["current_protected_reserve_cents"] = protected
	quote["projected_protected_reserve_cents"] = protected + added_daily
	return quote


func authorize_campus_portfolio_project(
	module_id: StringName,
	pad_id: StringName,
) -> Dictionary:
	var quote := campus_portfolio_project_quote(module_id, pad_id)
	if not bool(quote.get("can_authorize", false)):
		return quote
	var fund_before := revenue_cents
	var result: Dictionary = _campus_portfolio.authorize_project(
		module_id,
		pad_id,
		day,
		_campus_portfolio_context(),
	)
	if not bool(result.get("accepted", false)):
		return result
	var cost := int(quote.get("cost_cents", 0))
	revenue_cents -= cost
	result["fund_before_cents"] = fund_before
	result["fund_after_cents"] = revenue_cents
	result["projected_spendable_fund_cents"] = int(quote.get("projected_spendable_fund_cents", 0))
	result["campus_portfolio"] = campus_portfolio_snapshot()
	snapshot_changed.emit(snapshot())
	return result


func assign_campus_portfolio_worker(module_id: StringName, worker_id: int) -> Dictionary:
	if not staffing_planning_open():
		return {
			"accepted": false,
			"action_id": &"assign_worker",
			"module_id": module_id,
			"worker_id": worker_id,
			"reason": "Campus duty assignments may only be filed during clear review planning.",
		}
	var state_value: Variant = _campus_portfolio.modules.get(String(module_id), {})
	var module_state := state_value as Dictionary if state_value is Dictionary else {}
	var previous_worker := int(module_state.get("worker_id", -1))
	var added_daily := CampusPortfolioStateScript.CAMPUS_DUTY_PREMIUM_CENTS if previous_worker < 0 else 0
	var projected_spendable := _projected_spendable_after_obligation_change_cents(0, added_daily)
	if projected_spendable < 0:
		return {
			"accepted": false,
			"action_id": &"assign_worker",
			"module_id": module_id,
			"worker_id": worker_id,
			"reason": "The Feed Fund cannot protect the $1.00 daily campus-duty premium.",
			"projected_spendable_fund_cents": projected_spendable,
		}
	var context := _campus_portfolio_context()
	var result: Dictionary = _campus_portfolio.assign_worker(
		module_id,
		worker_id,
		context.get("valid_worker_ids", []) as Array,
		context,
	)
	if bool(result.get("accepted", false)):
		result["projected_spendable_fund_cents"] = projected_spendable
		result["campus_portfolio"] = campus_portfolio_snapshot()
		snapshot_changed.emit(snapshot())
	return result


func unassign_campus_portfolio_worker(module_id: StringName) -> Dictionary:
	if not staffing_planning_open():
		return {
			"accepted": false,
			"action_id": &"unassign_worker",
			"module_id": module_id,
			"reason": "Campus duty assignments may only be changed during clear review planning.",
		}
	var capacity_reason := _campus_portfolio_unassignment_capacity_reason(module_id)
	if not capacity_reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"unassign_worker",
			"module_id": module_id,
			"reason": capacity_reason,
		}
	var context := _campus_portfolio_context()
	var result: Dictionary = _campus_portfolio.unassign_worker(
		module_id,
		context.get("valid_worker_ids", []) as Array,
		context,
	)
	if bool(result.get("accepted", false)):
		result["campus_portfolio"] = campus_portfolio_snapshot()
		snapshot_changed.emit(snapshot())
	return result


func _campus_portfolio_assignment_for_worker(worker_id: int) -> StringName:
	for module_id: StringName in CampusPortfolioStateScript.MODULE_ORDER:
		var state_value: Variant = _campus_portfolio.modules.get(String(module_id), {})
		if state_value is Dictionary and int((state_value as Dictionary).get("worker_id", -1)) == worker_id:
			return module_id
	return &""


func _campus_portfolio_unassignment_capacity_reason(module_id: StringName) -> String:
	if module_id == CampusPortfolioStateScript.COLLECTION_RAIL_HUB:
		var capacity_without_rail := (
			_claim_capacity_for_facilities_and_campus(owned_facilities, campus_expansion_state)
		)
		if _outstanding_claim_count() + _pending_market_contract_claim_count() > capacity_without_rail:
			return "Route or finish claims before releasing the Collection Rail hen; the live ledger exceeds capacity without her."
	elif module_id == CampusPortfolioStateScript.GRAIN_RECOVERY_MILL:
		var base_feed_capacity := _facility_level_schedule_value(
			FEED_PROCUREMENT_CAPACITY_SCOOPS,
			facility_level(FEED_PROCUREMENT_COOP_ID),
			0,
		)
		if _feed_procurement.stock_scoops() > base_feed_capacity:
			return "Use the Grain Recovery overflow stock before releasing its named hen."
	elif module_id == CampusPortfolioStateScript.CREEKSIDE_CHILLING_EXCHANGE:
		var base_farmgate_capacity := _farmgate_storage_capacity_for_level_and_campus(
			facility_level(FARMGATE_DISPATCH_DEPOT_ID),
			campus_expansion_state,
		)
		if _farmgate_dispatch.stock_count() > base_farmgate_capacity:
			return "Dispatch Creekside's overflow egg lots before releasing its named hen."
	return ""


func current_daily_portfolio_cost_cents() -> int:
	return _campus_portfolio.daily_cost_cents()


func campus_portfolio_snapshot(north_projection: Dictionary = {}) -> Dictionary:
	var context := _campus_portfolio_context()
	var projection: Dictionary = _campus_portfolio.snapshot(context)
	var finance_basis := _campus_portfolio_finance_basis()
	var assignments := (projection.get("workers", []) as Array).duplicate(true)
	var parcel_rows := (projection.get("parcels", []) as Array).duplicate(true)
	for index in parcel_rows.size():
		var row := (parcel_rows[index] as Dictionary).duplicate(true)
		var parcel_id := StringName(String(row.get("id", "")))
		var raw_quote_value: Variant = row.get("quote", {})
		var raw_quote := (
			raw_quote_value as Dictionary
			if raw_quote_value is Dictionary else
			_campus_portfolio.quote_deed(parcel_id, context)
		)
		var quote := _enriched_campus_portfolio_quote(raw_quote, finance_basis, &"deed")
		row["quote"] = quote
		row["can_purchase"] = bool(quote.get("can_authorize", false))
		row["reason"] = String(quote.get("reason", ""))
		row["benefit_lines"] = [
			"Adds two route-safe construction pads to the visible farm-office campus.",
			"Every completed module adds a real operating benefit and recurring obligation.",
		]
		parcel_rows[index] = row
	var north := north_projection if not north_projection.is_empty() else campus_expansion_snapshot()
	var north_parcel := (north.get("parcel", {}) as Dictionary).duplicate(true)
	north_parcel["id"] = &"north_meadow"
	north_parcel["name"] = "NORTH MEADOW"
	north_parcel["status_label"] = (
		"UTILITY HUB ONLINE" if bool(north.get("pod_operational", false)) else
		"DEED FILED" if bool(north_parcel.get("owned", false)) else
		"READY" if bool(north_parcel.get("can_purchase", false)) else
		"HELD"
	)
	north_parcel["benefit_lines"] = [
		"Supplies the shared circulation, five-unit power trunk, and two-unit cold loop.",
		"Open North Meadow details to file its deed, services, pod, or relocation.",
	]
	parcel_rows.push_front(north_parcel)
	projection["parcels"] = parcel_rows

	var module_rows := (projection.get("modules", []) as Array).duplicate(true)
	for index in module_rows.size():
		var module := (module_rows[index] as Dictionary).duplicate(true)
		var module_id := StringName(String(module.get("id", "")))
		var pad_quotes: Dictionary = {}
		var allowed_pad_ids: Array[StringName] = []
		for quote_value: Variant in module.get("placement_quotes", []) as Array:
			if not quote_value is Dictionary:
				continue
			var pad_quote := (quote_value as Dictionary).duplicate(true)
			var pad_id := StringName(String(pad_quote.get("pad_id", "")))
			pad_quote = _enriched_campus_portfolio_quote(
				pad_quote,
				finance_basis,
				&"module",
			)
			pad_quotes[pad_id] = pad_quote
			allowed_pad_ids.append(pad_id)
		module["pad_quotes"] = pad_quotes
		module["allowed_pad_ids"] = allowed_pad_ids
		module["requires_staff"] = true
		module["staff_required"] = 1
		module["effect_lines"] = (module.get("benefits", []) as Array).duplicate(true)
		module_rows[index] = module
	projection["modules"] = module_rows
	projection["module_catalog"] = module_rows.duplicate(true)

	var project_rows := (projection.get("projects", []) as Array).duplicate(true)
	for index in project_rows.size():
		var project := (project_rows[index] as Dictionary).duplicate(true)
		var duration := maxi(1, int(project.get("duration_shifts", 1)))
		var remaining := clampi(int(project.get("remaining_shifts", duration)), 0, duration)
		var progress := duration - remaining
		project["job_id"] = int(project.get("project_id", index + 1))
		project["progress_shifts"] = progress
		project["stage_id"] = (
			&"queued" if StringName(String(project.get("status", ""))) == &"queued" else
			&"foundation" if progress * 2 < duration else
			&"frame"
		)
		project["stage_label"] = String(project["stage_id"]).replace("_", " ").to_upper()
		project_rows[index] = project
	projection["projects"] = project_rows

	var assigned_by_worker: Dictionary = {}
	for assignment_value: Variant in assignments:
		if assignment_value is Dictionary:
			assigned_by_worker[int((assignment_value as Dictionary).get("worker_id", -1))] = StringName(
				String((assignment_value as Dictionary).get("module_id", ""))
			)
	var worker_rows: Array[Dictionary] = []
	for worker in workers:
		if not worker.employed:
			continue
		var assigned_module := StringName(assigned_by_worker.get(worker.id, &""))
		worker_rows.append({
			"id": worker.id,
			"name": worker.display_name,
			"role": worker.career_title(),
			"available": assigned_module == &"",
			"can_assign": assigned_module == &"",
			"assigned_module_id": assigned_module,
		})
	projection["workers"] = worker_rows
	projection["assignments"] = assignments
	projection["resources"] = {
		"feed_fund_cents": revenue_cents,
		"spendable_fund_cents": spendable_fund_cents(),
		"protected_reserve_cents": protected_reserve_cents(),
	}
	var contractor := projection.get("contractor", {}) as Dictionary
	var network := projection.get("network", {}) as Dictionary
	(projection["resources"] as Dictionary)["contractor_used"] = int(contractor.get("active_slots", 0))
	(projection["resources"] as Dictionary)["contractor_capacity"] = int(contractor.get("capacity_slots", 1))
	(projection["resources"] as Dictionary)["power_used"] = int(network.get("power_reserved_units", 0))
	(projection["resources"] as Dictionary)["power_capacity"] = int(network.get("power_capacity_units", 0))
	(projection["resources"] as Dictionary)["cold_used"] = int(network.get("cold_reserved_units", 0))
	(projection["resources"] as Dictionary)["cold_capacity"] = int(network.get("cold_capacity_units", 0))
	projection["summary"] = "%d/3 DEEDS / %d ACTIVE / %d QUEUED" % [
		(1 if bool(north_parcel.get("owned", false)) else 0)
		+ int(bool((_campus_portfolio.parcels as Dictionary).get("orchard_row", false)))
		+ int(bool((_campus_portfolio.parcels as Dictionary).get("creekside_yard", false))),
		int(contractor.get("active_slots", 0)),
		int(contractor.get("queue_count", 0)),
	]
	return projection


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


func _facility_purchase_effect_copy(facility_id: StringName, level: int) -> Dictionary:
	var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
	return {
		"benefits": (definition.get("benefits", []) as Array).duplicate(true),
		"tradeoffs": (definition.get("tradeoffs", []) as Array).duplicate(true),
		"storage_capacity_eggs": (
			_facility_level_schedule_value(FARMGATE_DISPATCH_STORAGE_CAPACITY_EGGS, level, 0)
			if facility_id == FARMGATE_DISPATCH_DEPOT_ID else 0
		),
		"dispatch_capacity_eggs": (
			_facility_level_schedule_value(FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS, level, 0)
			if facility_id == FARMGATE_DISPATCH_DEPOT_ID else 0
		),
		"shelf_life_shifts": (
			_facility_level_schedule_value(FARMGATE_DISPATCH_SHELF_LIFE_SHIFTS, level, 0)
			if facility_id == FARMGATE_DISPATCH_DEPOT_ID else 0
		),
	}


func facility_purchase_preflight(facility_id: StringName) -> Dictionary:
	## A read-only receipt shared by the UI and the authoritative mutation. This
	## keeps duplicate, gate, phase, and fund rejections completely atomic.
	return facility_status(facility_id)


func purchase_facility(facility_id: StringName) -> Dictionary:
	var preflight := facility_purchase_preflight(facility_id)
	if not bool(preflight.get("can_purchase", false)):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		return rejection

	var cost_cents := int(preflight["cost_cents"])
	var fund_before := revenue_cents
	var spendable_before := spendable_fund_cents()
	var protected_reserve_before := protected_reserve_cents()
	var upkeep_before := current_daily_facility_maintenance_cents()
	var next_shift_quota_before := quota_target
	var next_level := facility_level(facility_id) + 1
	revenue_cents -= cost_cents
	owned_facilities[facility_id] = next_level
	if facility_id == ROOSTER_OPERATIONS_OFFICE_ID:
		_ensure_manager_posts_for_office_level()
	if facility_id == WELLNESS_NEST_ID:
		quota_target = clampi(quota_target + 1, 1, 10_000)
	var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
	var outcome := _facility_purchase_outcome(facility_id, next_level, definition)
	var result := facility_status(facility_id)
	result.merge({
		"accepted": true,
		"action_id": &"purchase_facility",
		"facility_id": facility_id,
		"day": day,
		"level": next_level,
		"purchased_level": next_level,
		"cost_cents": cost_cents,
		"capital_cost_cents": cost_cents,
		"added_daily_operating_cents": int(preflight.get("added_daily_operating_cents", 0)),
		"maintenance_delta_cents": int(preflight.get("maintenance_delta_cents", 0)),
		"supervisor_payroll_delta_cents": int(
			preflight.get("supervisor_payroll_delta_cents", 0)
		),
		"required_spendable_cents": int(preflight.get("required_spendable_cents", cost_cents)),
		"projected_spendable_fund_cents": int(preflight.get("projected_spendable_fund_cents", 0)),
		"current_flock_relations_case_capacity": int(
			preflight.get("current_flock_relations_case_capacity", 0)
		),
		"next_flock_relations_case_capacity": int(
			preflight.get("next_flock_relations_case_capacity", 0)
		),
		"flock_relations_case_capacity_delta": int(
			preflight.get("flock_relations_case_capacity_delta", 0)
		),
		"current_flock_relations_resolution_limit": int(
			preflight.get("current_flock_relations_resolution_limit", 0)
		),
		"next_flock_relations_resolution_limit": int(
			preflight.get("next_flock_relations_resolution_limit", 0)
		),
		"flock_relations_resolution_limit_delta": int(
			preflight.get("flock_relations_resolution_limit_delta", 0)
		),
		"fund_delta_cents": revenue_cents - fund_before,
		"spendable_fund_cents": spendable_fund_cents(),
		"next_shift_quota_before": next_shift_quota_before,
		"next_shift_quota_after": quota_target,
		"next_shift_quota_delta": quota_target - next_shift_quota_before,
		"outcome": outcome,
	}, true)
	var commissioning_receipt := {
		"accepted": true,
		"action_id": &"purchase_facility",
		"facility_id": facility_id,
		"facility_name": String(definition.get("name", "CAPITAL FACILITY")),
		"level_name": _facility_level_name(definition, next_level),
		"day": day,
		"purchased_level": next_level,
		"max_level": int(definition.get("max_level", 1)),
		"cost_cents": cost_cents,
		"fund_before_cents": fund_before,
		"fund_after_cents": revenue_cents,
		"spendable_before_cents": spendable_before,
		"spendable_after_cents": spendable_fund_cents(),
		"protected_reserve_before_cents": protected_reserve_before,
		"protected_reserve_after_cents": protected_reserve_cents(),
		"upkeep_before_cents": upkeep_before,
		"upkeep_after_cents": current_daily_facility_maintenance_cents(),
		"upkeep_delta_cents": (
			current_daily_facility_maintenance_cents() - upkeep_before
		),
		"effect": _facility_purchase_effect_copy(facility_id, next_level),
	}
	last_facility_purchase_receipt = commissioning_receipt.duplicate(true)
	facility_commissioning_history.append(commissioning_receipt.duplicate(true))
	while facility_commissioning_history.size() > FARMGATE_COMMISSIONING_HISTORY_LIMIT:
		facility_commissioning_history.pop_front()
	if (
		pinned_capital_plan_id == facility_id
		and next_level >= int(definition.get("max_level", 1))
	):
		pinned_capital_plan_id = &""
	result["commissioning_receipt"] = commissioning_receipt.duplicate(true)
	result["capital_plan"] = capital_plan_snapshot()
	facility_purchased.emit(facility_id, next_level, cost_cents)
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return result


func _facility_purchase_outcome(
	facility_id: StringName,
	level: int,
	definition: Dictionary
) -> String:
	if facility_id == PACKING_ANNEX_ID:
		match level:
			1:
				return "Packing Annex level 1 opened: the flock fills cartons and the farmer signs the label."
			2:
				return "Packing Annex level 2 automated sealing; throughput is now described as management innovation."
			3:
				return "Packing Annex level 3 opened premium dispatch and a larger farmer-credit stamp."
	if facility_id == RECORDS_ANNEX_ID:
		match level:
			1:
				return "Records Annex level 1 opened six more file roosts; missed work may now become overdue work."
			2:
				return "Records Annex level 2 opened pneumatic triage and six additional live-file slots."
			3:
				return "Records Annex level 3 sealed the retention vault at 36 files and $11.00 daily upkeep."
	if facility_id == FARM_MUTUAL_SERVICE_COOP_ID:
		match level:
			1:
				return "Service Coop level 1 installed the Bronze client seal desk; fulfilled binder premiums now carry a 50% service bonus."
			2:
				return "Service Coop level 2 opened Silver timed dispatch; fulfilled binder premiums now carry a 100% service bonus."
			3:
				return "Service Coop level 3 opened the Gold account gallery; fulfilled binder premiums now carry a 150% service bonus."
	if facility_id == FARM_MUTUAL_NEGOTIATION_ROOM_ID:
		return "Farm Mutual Negotiation Room commissioned: one signed rider may now reshape each binder's operational risk."
	if facility_id == WELLNESS_NEST_ID:
		match level:
			1:
				return "Wellness Nest level 1 opened Quiet Nest Cubbies; Finance added one file to the next clutch target."
			2:
				return "Wellness Nest level 2 opened Rotating Recovery; improved rest now supports one more target file."
			3:
				return "Wellness Nest level 3 certified the Rested Flock Suite and raised the target once more."
	if facility_id == TRAINING_ROOST_ID:
		match level:
			1:
				return "Training Roost level 1 opened a Practice Terminal; sponsorship now costs $10.00."
			2:
				return "Training Roost level 2 opened the Cross-Lane Classroom; sponsorship now costs $8.00."
			3:
				return "Training Roost level 3 opened the Credential Gallery; sponsorship now costs $6.00."
	if facility_id == ROOSTER_OPERATIONS_OFFICE_ID:
		match level:
			1:
				return "Rooster Office level 1 opened the Shift Board Perch; two flock check-ins now fit beneath one supervisor's gaze."
			2:
				return "Rooster Office level 2 sealed the Glass Supervision Pod; three hens may now receive management attention each shift."
			3:
				return "Rooster Office level 3 opened the Command Roost Gallery; four daily check-ins now support a complete visibility narrative."
	if facility_id == IT_COOP_ID:
		match level:
			1:
				return "IT Coop level 1 repaired the cable bench; AUTO now recognizes accredited secondary peckwork and runs 3% faster."
			2:
				return "IT Coop level 2 opened predictive dispatch; AUTO runs 6% faster and rescues urgent folders sooner."
			3:
				return "IT Coop level 3 commissioned the automated sorter; AUTO runs 10% faster while every system exception costs more to explain."
	if facility_id == FLOCK_RELATIONS_OFFICE_ID:
		match level:
			1:
				return "Flock Relations level 1 opened Open-Nest Case Intake; one workplace file may now receive a review disposition."
			2:
				return "Flock Relations level 2 opened the Mediation & PIP Room; two open cases and two daily dispositions now fit the ledger."
			3:
				return "Flock Relations level 3 opened the Mandatory Arbitration Roost; three cases may now be managed into final language."
	if facility_id == FEED_PROCUREMENT_COOP_ID:
		match level:
			1:
				return "Provisions Co-op level 1 opened the Receiving Hopper; one local-grain shift may now be held outside the spot market."
			2:
				return "Provisions Co-op level 2 opened the Dry Grain Reserve; bulk mash can now trade thrift for flock strain."
			3:
				return "Provisions Co-op level 3 opened the Feed Futures Desk; four shifts of grain may now be fixed at today's seasonal quote."
	if facility_id == FARMER_RELATIONS_GALLERY_ID:
		match level:
			1:
				return "Harvest Credit Gallery level 1 opened the Basket Press Desk; each completed shift may now become one paid public story."
			2:
				return "Harvest Credit Gallery level 2 opened the Clutch Results Wall; verified sound and golden output now earns regional placement rates."
			3:
				return "Harvest Credit Gallery level 3 opened the Executive Harvest Stage; the farmer's method now travels at the bureau's richest publicity rate."
	if facility_id == FARMGATE_DISPATCH_DEPOT_ID:
		match level:
			1:
				return "Farmgate Depot level 1 opened the Roadside Loading Shed; finished eggs now wait for a filed dispatch mandate."
			2:
				return "Farmgate Depot level 2 opened the Chilled County Dock; sixteen eggs may reach the auction route each shift."
			3:
				return "Farmgate Depot level 3 commissioned the Regional Route Fleet; six premium eggs may now enter the farmer's showcase."
	return "%s commissioned. Finance has converted shell integrity into a recurring expense." % String(
		definition["name"]
	)


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


func market_contract_planning_open() -> bool:
	return day >= CONTRACT_BOARD_UNLOCK_DAY and staffing_planning_open()


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


func _market_contract_offer_on_cooldown(offer_id: StringName) -> bool:
	return (
		StringName(last_market_contract_result.get("status", &"")) == &"breached"
		and StringName(last_market_contract_result.get("offer_id", &"")) == offer_id
		and int(last_market_contract_result.get("day", 0)) == day - 1
	)


func market_contract_offer_catalog() -> Array[Dictionary]:
	var offers: Array[Dictionary] = []
	if day < CONTRACT_BOARD_UNLOCK_DAY:
		return offers
	for offer_id in MARKET_CONTRACT_OFFER_ORDER:
		offers.append(market_contract_offer_preflight(offer_id))
	return offers


func market_contract_offer_preflight(
	offer_id: StringName,
	clause_id: StringName = &"standard_terms"
) -> Dictionary:
	return _market_contract_offer_preflight(offer_id, clause_id, true)


func _market_contract_offer_preflight(
	offer_id: StringName,
	clause_id: StringName,
	attach_clause_options: bool
) -> Dictionary:
	var clause_known := MARKET_CONTRACT_CLAUSE_DEFINITIONS.has(clause_id)
	var offer := {}
	if clause_known:
		offer = _market_contract_quote_for_day(
			offer_id,
			day,
			maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID)),
			maxi(0, facility_level(FARM_MUTUAL_NEGOTIATION_ROOM_ID)),
			clause_id,
		)
	if offer.is_empty():
		var unknown := {
			"id": offer_id,
			"offer_id": offer_id,
			"known": MARKET_CONTRACT_DEFINITIONS.has(offer_id),
			"clause_known": clause_known,
			"clause_id": clause_id,
			"clause_available": false,
			"can_sign": false,
			"reason": (
				"Farm Mutual does not recognize that binder."
				if not MARKET_CONTRACT_DEFINITIONS.has(offer_id) else
				"Farm Mutual does not recognize that negotiated clause."
			),
		}
		if attach_clause_options and MARKET_CONTRACT_DEFINITIONS.has(offer_id):
			unknown["clause_options"] = _market_contract_clause_options(offer_id)
		return unknown
	var available_slots := maxi(
		0,
		current_claim_capacity()
		- _outstanding_claim_count()
		- _pending_market_contract_claim_count(),
	)
	var breach_cents := int(offer.get("breach_cents", 0))
	var spendable := spendable_fund_cents()
	var required_active_staff := int(offer.get("required_active_staff", 0))
	var active_staff := active_worker_count()
	var on_cooldown := _market_contract_offer_on_cooldown(offer_id)
	var reason := ""
	if not bool(offer.get("clause_available", false)):
		reason = "Commission the Farm Mutual Negotiation Room before signing this clause."
	elif day < CONTRACT_BOARD_UNLOCK_DAY:
		reason = "Complete two shifts before Farm Mutual opens its contract folders."
	elif shift_phase != ShiftPhase.REVIEW:
		reason = "Market binders may be signed only during closed-shift planning."
	elif not pending_decision.is_empty():
		reason = "File the closing credit memo before accepting outside peckwork."
	elif (
		not market_contract_decline_receipt.is_empty()
		and int(market_contract_decline_receipt.get("target_day", 0)) == day
	):
		reason = "The standard book was already filed for Day %d." % day
	elif not active_market_contract.is_empty():
		reason = "One Farm Mutual binder is already signed for Day %d." % int(
			active_market_contract.get("target_day", day)
		)
	elif on_cooldown:
		reason = "%s is cooling in Farm Mutual review for one planning day after yesterday's breach." % String(
			offer.get("short_name", "This binder")
		)
	elif current_claim_capacity() < int(offer.get("required_claim_capacity", 0)):
		reason = "%s requires %d live-file roosts; the bureau currently has %d." % [
			String(offer.get("short_name", "This binder")),
			int(offer.get("required_claim_capacity", 0)),
			current_claim_capacity(),
		]
	elif active_staff < required_active_staff:
		reason = "%s requires %d active hens; the bureau currently staffs %d." % [
			String(offer.get("short_name", "This binder")),
			required_active_staff,
			active_staff,
		]
	elif available_slots < int(offer.get("total_claims", 0)):
		reason = "%d more empty file roost%s required before these folders can be reserved." % [
			int(offer.get("total_claims", 0)) - available_slots,
			"" if int(offer.get("total_claims", 0)) - available_slots == 1 else "s",
		]
	elif spendable < breach_cents:
		reason = "$%.2f more spendable Feed Fund is required to reserve the breach clause." % (
			float(breach_cents - spendable) / 100.0
		)
	offer["known"] = true
	offer["clause_known"] = true
	offer["planning_open"] = market_contract_planning_open()
	offer["available_claim_slots"] = available_slots
	offer["spendable_fund_cents"] = spendable
	offer["breach_reserve_cents"] = breach_cents
	offer["spendable_after_reserve_cents"] = spendable - breach_cents
	offer["active_staff_count"] = active_staff
	offer["active_staff_shortfall"] = maxi(0, required_active_staff - active_staff)
	offer["staffing_ready"] = active_staff >= required_active_staff
	offer["on_cooldown"] = on_cooldown
	offer["cooldown_until_day"] = day if on_cooldown else 0
	offer["can_sign"] = reason.is_empty()
	offer["reason"] = reason
	if attach_clause_options:
		offer["clause_options"] = _market_contract_clause_options(offer_id)
	return offer


func _market_contract_clause_options(offer_id: StringName) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for clause_id in MARKET_CONTRACT_CLAUSE_ORDER:
		options.append(_market_contract_offer_preflight(offer_id, clause_id, false))
	return options


func market_contract_board_status() -> Dictionary:
	var unlocked := day >= CONTRACT_BOARD_UNLOCK_DAY
	var standing := farm_mutual_standing_status()
	var accreditation := farm_mutual_service_coop_status()
	var negotiation_room := farm_mutual_negotiation_room_status()
	var season := market_season_for_day(day)
	var active := active_market_contract.duplicate(true)
	if not active.is_empty():
		active["remaining_required"] = maxi(
			0,
			int(active.get("required_completed", 0))
			- int(active.get("timely_sound_completed", 0)),
		)
		active["pending_arrivals"] = _pending_market_contract_claim_count()
		active["breach_reserve_cents"] = current_market_contract_reserve_cents()
	return {
		"unlocked": unlocked,
		"unlock_day": CONTRACT_BOARD_UNLOCK_DAY,
		"unlock_requirement": "Complete two shifts to open Farm Mutual's contract folders.",
		"planning_open": market_contract_planning_open(),
		"target_day": day,
		"season": season,
		"season_id": season.get("id", &"baseline_neutral"),
		"season_label": String(season.get("label", "BASELINE NEUTRAL BOOK")),
		"standing": standing,
		"accreditation": accreditation,
		"negotiation_room": negotiation_room,
		"offers": market_contract_offer_catalog(),
		"active": active,
		"active_contract": active.duplicate(true),
		"decline_available": (
			unlocked
			and market_contract_planning_open()
			and active.is_empty()
			and market_contract_decline_receipt.is_empty()
		),
		"decline_receipt": market_contract_decline_receipt.duplicate(true),
		"last_result": last_market_contract_result.duplicate(true),
		"claim_capacity": current_claim_capacity(),
		"claims_outstanding": _outstanding_claim_count(),
		"reserved_claim_slots": _pending_market_contract_claim_count(),
		"breach_reserve_cents": current_market_contract_reserve_cents(),
		"contracts_signed_total": market_contracts_signed_total,
		"contracts_succeeded_total": market_contracts_succeeded_total,
		"contracts_breached_total": market_contracts_breached_total,
		"market_standing": int(standing.get("points", 0)),
		"market_standing_rank": standing.get("rank", &"unlisted"),
		"market_clean_contract_streak": market_clean_contract_streak,
		"best_market_clean_contract_streak": best_market_clean_contract_streak,
		"service_coop_level": int(accreditation.get("level", 0)),
		"service_coop_premium_bonus_basis_points": int(
			accreditation.get("premium_bonus_basis_points", 0)
		),
		"negotiation_room_level": int(negotiation_room.get("level", 0)),
		"premium_today_cents": market_contract_premium_today_cents,
		"premium_total_cents": market_contract_premium_total_cents,
		"breach_today_cents": market_contract_breach_today_cents,
		"breach_total_cents": market_contract_breach_total_cents,
	}


func sign_market_contract(
	offer_id: StringName,
	clause_id: StringName = &"standard_terms"
) -> Dictionary:
	## Signing is a reserve transaction, not income or expense. The exact folders
	## and claim IDs are authored now, then released at their disclosed times
	## without opening a modal or stopping the production clock.
	var preflight := market_contract_offer_preflight(offer_id, clause_id)
	if not bool(preflight.get("can_sign", false)):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		return rejection
	var fund_before := revenue_cents
	var claim_ids: Array[int] = []
	var scheduled_claims: Array[Dictionary] = []
	for schedule_value in preflight.get("scheduled_claims", []):
		var schedule := (schedule_value as Dictionary).duplicate(true)
		var claim_id := _next_claim_id
		_next_claim_id += 1
		claim_ids.append(claim_id)
		schedule["claim_id"] = claim_id
		schedule["released"] = false
		schedule["rejected"] = false
		scheduled_claims.append(schedule)
	var contract_id := "FM-%04d-%s" % [day, String(offer_id).to_upper()]
	active_market_contract = preflight.duplicate(true)
	for transient_field in [
		"known", "clause_known", "planning_open", "available_claim_slots",
		"spendable_fund_cents", "breach_reserve_cents", "spendable_after_reserve_cents",
		"active_staff_count", "active_staff_shortfall", "staffing_ready", "on_cooldown",
		"cooldown_until_day", "can_sign", "reason", "clause_options",
	]:
		active_market_contract.erase(transient_field)
	active_market_contract.merge({
		"version": 2,
		"contract_id": contract_id,
		"offer_id": String(offer_id),
		"id": String(offer_id),
		"signed_day": day,
		"target_day": day,
		"deadline_day": day,
		"status": "signed",
		"legacy_staffing_grandfathered": false,
		"legacy_terms_grandfathered": false,
		"scheduled_claims": scheduled_claims,
		"claim_ids": claim_ids,
		"accepted_claim_ids": [],
		"completed_claim_ids": [],
		"sound_completed_claim_ids": [],
		"timely_sound_claim_ids": [],
		"cracked_claim_ids": [],
		"late_claim_ids": [],
		"rejected_claim_ids": [],
		"released_batch_count": 0,
		"completed_count": 0,
		"sound_completed": 0,
		"timely_sound_completed": 0,
		"rush_completed_on_time": 0,
		"cracked_count": 0,
		"late_count": 0,
	}, true)
	market_contracts_signed_total += 1
	var result := market_contract_board_status()
	result.merge({
		"accepted": true,
		"action_id": &"sign_market_contract",
		"offer_id": offer_id,
		"clause_id": clause_id,
		"contract_id": contract_id,
		"required_active_staff": int(preflight.get("required_active_staff", 0)),
		"base_premium_cents": int(preflight.get("base_premium_cents", 0)),
		"season_premium_delta_cents": int(preflight.get("season_premium_delta_cents", 0)),
		"clause_premium_delta_cents": int(preflight.get("clause_premium_delta_cents", 0)),
		"market_premium_cents": int(preflight.get("market_premium_cents", 0)),
		"service_coop_level_at_signing": int(preflight.get("service_coop_level_at_signing", 0)),
		"service_coop_bonus_cents": int(preflight.get("service_coop_bonus_cents", 0)),
		"premium_bonus_basis_points": int(preflight.get("premium_bonus_basis_points", 0)),
		"premium_cents": int(preflight.get("premium_cents", 0)),
		"fund_before_cents": fund_before,
		"fund_after_cents": revenue_cents,
		"fund_delta_cents": revenue_cents - fund_before,
		"outcome": "%s signed for Day %d. $%.2f remains reserved against breach." % [
			String(preflight.get("short_name", "Farm Mutual binder")),
			day,
			float(preflight.get("breach_cents", 0)) / 100.0,
		],
	}, true)
	announcement_posted.emit(String(result["outcome"]))
	market_contract_signed.emit(result.duplicate(true))
	snapshot_changed.emit(snapshot())
	return result


func decline_market_contract() -> Dictionary:
	## Outside work is optional, but skipping it must be a visible authored choice
	## rather than an accidental close button or a silent failure to sign.
	var reason := ""
	if day < CONTRACT_BOARD_UNLOCK_DAY:
		reason = "Farm Mutual has not opened its client folders yet."
	elif not staffing_planning_open():
		reason = "The standard book may be filed only during closed-shift planning."
	elif not active_market_contract.is_empty():
		reason = "A Farm Mutual binder is already signed for Day %d." % day
	elif (
		not market_contract_decline_receipt.is_empty()
		and int(market_contract_decline_receipt.get("target_day", 0)) == day
	):
		reason = "The standard book is already filed for Day %d." % day
	if not reason.is_empty():
		return {
			"accepted": false,
			"action_id": &"decline_market_contract",
			"target_day": day,
			"reason": reason,
			"outcome": reason,
		}
	market_contract_decline_receipt = {
		"version": 1,
		"accepted": true,
		"action_id": "decline_market_contract",
		"status": "declined",
		"day": day,
		"target_day": day,
		"outcome": "STANDARD BOOK FILED: no outside Farm Mutual binder will arrive on Day %d." % day,
	}
	var result := market_contract_board_status()
	result.merge(market_contract_decline_receipt.duplicate(true), true)
	announcement_posted.emit(String(market_contract_decline_receipt["outcome"]))
	market_contract_declined.emit(result.duplicate(true))
	snapshot_changed.emit(snapshot())
	return result


func _legacy_market_contract_offer_for_day(offer_id: StringName, target_day: int) -> Dictionary:
	if not MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	var definition := MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary
	var lane_mix: Dictionary = {}
	var rush_lane_mix: Dictionary = {}
	var arrival_batches: Array[Dictionary] = []
	var scheduled_claims: Array[Dictionary] = []
	var rush_claims := 0
	var service_window := int(definition.get("service_window_minutes", 1))
	var batch_index := 0
	for batch_value in definition.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		var arrival_minute := clampi(
			int(batch.get("minute_of_day", SHIFT_START_MINUTE)),
			SHIFT_START_MINUTE,
			SHIFT_END_MINUTE,
		)
		var rush := bool(batch.get("rush", false))
		var batch_lanes: Array[String] = []
		for lane_value in batch.get("lanes", []):
			var lane := StringName(String(lane_value))
			if lane not in CLAIM_LANES:
				continue
			var lane_key := String(lane)
			lane_mix[lane_key] = int(lane_mix.get(lane_key, 0)) + 1
			if rush:
				rush_lane_mix[lane_key] = int(rush_lane_mix.get(lane_key, 0)) + 1
				rush_claims += 1
			var deadline_minute := mini(SHIFT_END_MINUTE, arrival_minute + service_window)
			batch_lanes.append(lane_key)
			scheduled_claims.append({
				"batch_index": batch_index,
				"lane": lane_key,
				"rush": rush,
				"arrival_minute_of_day": arrival_minute,
				"arrival_time": _format_time(arrival_minute),
				"deadline_minute_of_day": deadline_minute,
				"deadline_time": _format_time(deadline_minute),
				"service_window_minutes": deadline_minute - arrival_minute,
			})
		arrival_batches.append({
			"batch_index": batch_index,
			"minute_of_day": arrival_minute,
			"time": _format_time(arrival_minute),
			"deadline_minute_of_day": mini(SHIFT_END_MINUTE, arrival_minute + service_window),
			"deadline_time": _format_time(mini(SHIFT_END_MINUTE, arrival_minute + service_window)),
			"lanes": batch_lanes,
			"lane_mix": _contract_lane_mix(batch_lanes),
			"count": batch_lanes.size(),
			"rush": rush,
		})
		batch_index += 1
	var total_claims := scheduled_claims.size()
	var required_completed := int(definition.get("required_deliveries", total_claims))
	var base_premium_cents := int(definition.get("premium_cents", 0))
	var service_coop_level := maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID))
	var service_coop_bonus_cents := _service_coop_premium_bonus_cents(
		base_premium_cents,
		service_coop_level,
	)
	var arrival_lines: Array[String] = []
	for batch in arrival_batches:
		arrival_lines.append("%s  %s%s" % [
			String(batch.get("time", "9:00 AM")),
			_contract_lane_mix_label(batch.get("lane_mix", {}) as Dictionary),
			"  ·  RUSH" if bool(batch.get("rush", false)) else "",
		])
	return {
		"id": offer_id,
		"offer_id": offer_id,
		"name": String(definition.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(definition.get("short_name", "MUTUAL BINDER")),
		"client": String(definition.get("client", "FARM MUTUAL")),
		"tagline": String(definition.get("tagline", "Outside peckwork filed.")),
		"tone": StringName(definition.get("tone", &"quality")),
		"target_day": target_day,
		"deadline_day": target_day,
		"required_claim_capacity": int(definition.get("required_claim_capacity", 0)),
		"required_active_staff": int(definition.get("required_active_staff", 0)),
		"required_completed": required_completed,
		"required_deliveries": required_completed,
		"total_claims": total_claims,
		"rush_claims": rush_claims,
		"service_window_minutes": service_window,
		"base_premium_cents": base_premium_cents,
		"service_coop_level_at_signing": service_coop_level,
		"service_coop_bonus_cents": service_coop_bonus_cents,
		"premium_bonus_basis_points": (
			service_coop_level * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"premium_cents": base_premium_cents + service_coop_bonus_cents,
		"breach_cents": int(definition.get("breach_cents", 0)),
		"lane_mix": lane_mix,
		"lane_mix_label": _contract_lane_mix_label(lane_mix),
		"rush_lane_mix": rush_lane_mix,
		"rush_lane_mix_label": _contract_lane_mix_label(rush_lane_mix),
		"arrival_batches": arrival_batches,
		"scheduled_claims": scheduled_claims,
		"arrival_schedule": "\n".join(arrival_lines),
		"success_required": "%d sound or golden folders delivered inside their disclosed service windows." % required_completed,
		"benefit": "+$%.2f closing premium on fulfillment ($%.2f base + $%.2f Service Coop)" % [
			float(base_premium_cents + service_coop_bonus_cents) / 100.0,
			float(base_premium_cents) / 100.0,
			float(service_coop_bonus_cents) / 100.0,
		],
		"tradeoff": "-$%.2f breach charge if fewer than %d folders arrive clean and on time" % [
			float(definition.get("breach_cents", 0)) / 100.0,
			required_completed,
		],
	}


func _market_contract_offer_for_day(offer_id: StringName, target_day: int) -> Dictionary:
	return _market_contract_quote_for_day(
		offer_id,
		target_day,
		maxi(0, facility_level(FARM_MUTUAL_SERVICE_COOP_ID)),
		maxi(0, facility_level(FARM_MUTUAL_NEGOTIATION_ROOM_ID)),
		&"standard_terms",
	)


func _market_contract_quote_for_day(
	offer_id: StringName,
	target_day: int,
	service_coop_level: int,
	negotiation_room_level: int,
	clause_id: StringName,
	force_neutral_terms: bool = false
) -> Dictionary:
	if not MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	if not MARKET_CONTRACT_CLAUSE_DEFINITIONS.has(clause_id):
		return {}
	var definition := MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary
	var clause := MARKET_CONTRACT_CLAUSE_DEFINITIONS[clause_id] as Dictionary
	var authored_lane_mix: Dictionary = {}
	var scheduled_claims: Array[Dictionary] = []
	var authored_service_window := int(definition.get("service_window_minutes", 1))
	var service_window := authored_service_window
	if clause_id == &"expedited_hatch_rider":
		service_window = maxi(60, authored_service_window - 60)
	var authored_dominant_lane := _market_contract_dominant_lane(definition)
	var batch_index := 0
	for batch_value in definition.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		var arrival_minute := clampi(
			int(batch.get("minute_of_day", SHIFT_START_MINUTE)),
			SHIFT_START_MINUTE,
			SHIFT_END_MINUTE,
		)
		var authored_rush := bool(batch.get("rush", false))
		for lane_value in batch.get("lanes", []):
			var authored_lane := StringName(String(lane_value))
			if authored_lane not in CLAIM_LANES:
				continue
			var authored_lane_key := String(authored_lane)
			authored_lane_mix[authored_lane_key] = int(
				authored_lane_mix.get(authored_lane_key, 0)
			) + 1
			var effective_lane := (
				authored_dominant_lane
				if clause_id == &"specialist_roost_endorsement" else
				authored_lane
			)
			var deadline_minute := mini(SHIFT_END_MINUTE, arrival_minute + service_window)
			scheduled_claims.append({
				"batch_index": batch_index,
				"lane": String(effective_lane),
				"authored_lane": authored_lane_key,
				"rush": authored_rush,
				"authored_rush": authored_rush,
				"arrival_minute_of_day": arrival_minute,
				"arrival_time": _format_time(arrival_minute),
				"deadline_minute_of_day": deadline_minute,
				"deadline_time": _format_time(deadline_minute),
				"service_window_minutes": deadline_minute - arrival_minute,
			})
		batch_index += 1
	if clause_id == &"expedited_hatch_rider":
		var latest_standard_index := -1
		var latest_standard_arrival := -1
		for schedule_index in scheduled_claims.size():
			var candidate := scheduled_claims[schedule_index]
			if bool(candidate.get("rush", false)):
				continue
			var candidate_arrival := int(candidate.get("arrival_minute_of_day", -1))
			if candidate_arrival >= latest_standard_arrival:
				latest_standard_arrival = candidate_arrival
				latest_standard_index = schedule_index
		if latest_standard_index >= 0:
			var expedited_schedule := scheduled_claims[latest_standard_index]
			expedited_schedule["rush"] = true
			scheduled_claims[latest_standard_index] = expedited_schedule

	var lane_mix: Dictionary = {}
	var rush_lane_mix: Dictionary = {}
	var rush_claims := 0
	for schedule in scheduled_claims:
		var lane_key := String(schedule.get("lane", ""))
		lane_mix[lane_key] = int(lane_mix.get(lane_key, 0)) + 1
		if bool(schedule.get("rush", false)):
			rush_lane_mix[lane_key] = int(rush_lane_mix.get(lane_key, 0)) + 1
			rush_claims += 1
	var arrival_batches: Array[Dictionary] = []
	for authored_batch_index in (definition.get("arrival_batches", []) as Array).size():
		var batch_lanes: Array[String] = []
		var batch_rush_count := 0
		var arrival_minute := SHIFT_START_MINUTE
		var deadline_minute := SHIFT_START_MINUTE
		for schedule in scheduled_claims:
			if int(schedule.get("batch_index", -1)) != authored_batch_index:
				continue
			batch_lanes.append(String(schedule.get("lane", "")))
			arrival_minute = int(schedule.get("arrival_minute_of_day", SHIFT_START_MINUTE))
			deadline_minute = int(schedule.get("deadline_minute_of_day", SHIFT_END_MINUTE))
			if bool(schedule.get("rush", false)):
				batch_rush_count += 1
		arrival_batches.append({
			"batch_index": authored_batch_index,
			"minute_of_day": arrival_minute,
			"time": _format_time(arrival_minute),
			"deadline_minute_of_day": deadline_minute,
			"deadline_time": _format_time(deadline_minute),
			"lanes": batch_lanes,
			"lane_mix": _contract_lane_mix(batch_lanes),
			"count": batch_lanes.size(),
			"rush": batch_rush_count == batch_lanes.size() and not batch_lanes.is_empty(),
			"contains_rush": batch_rush_count > 0,
			"rush_count": batch_rush_count,
		})

	var total_claims := scheduled_claims.size()
	var required_completed := int(definition.get("required_deliveries", total_claims))
	var authored_base_premium_cents := int(definition.get("premium_cents", 0))
	var authored_breach_cents := int(definition.get("breach_cents", 0))
	var season := (
		_neutral_market_season_for_day(target_day)
		if force_neutral_terms else
		market_season_for_day(target_day)
	)
	var season_lane_demand := season.get("lane_demand_basis_points", {}) as Dictionary
	var demand_numerator := 0
	for lane in CLAIM_LANES:
		var authored_lane_key := String(lane)
		demand_numerator += (
			int(authored_lane_mix.get(authored_lane_key, 0))
			* int(season_lane_demand.get(authored_lane_key, 0))
		)
	var season_demand_basis_points := _signed_half_up_ratio(
		demand_numerator,
		maxi(1, total_claims),
	)
	var season_premium_delta_cents := _basis_point_delta_cents(
		authored_base_premium_cents,
		season_demand_basis_points,
	)
	var season_breach_basis_points := maxi(
		0,
		_signed_half_up_ratio(season_demand_basis_points, 2),
	)
	var season_breach_delta_cents := _basis_point_delta_cents(
		authored_breach_cents,
		season_breach_basis_points,
	)
	var clause_premium_basis_points := int(clause.get("premium_basis_points", 0))
	var clause_breach_basis_points := int(clause.get("breach_basis_points", 0))
	var clause_premium_delta_cents := _basis_point_delta_cents(
		authored_base_premium_cents,
		clause_premium_basis_points,
	)
	var clause_breach_delta_cents := _basis_point_delta_cents(
		authored_breach_cents,
		clause_breach_basis_points,
	)
	var market_premium_cents := (
		authored_base_premium_cents
		+ season_premium_delta_cents
		+ clause_premium_delta_cents
	)
	service_coop_level = clampi(service_coop_level, 0, 3)
	negotiation_room_level = clampi(negotiation_room_level, 0, 1)
	var service_coop_bonus_cents := _service_coop_premium_bonus_cents(
		authored_base_premium_cents,
		service_coop_level,
	)
	var premium_cents := market_premium_cents + service_coop_bonus_cents
	var breach_cents := (
		authored_breach_cents
		+ season_breach_delta_cents
		+ clause_breach_delta_cents
	)
	var welfare_gate_minimum := (
		RESTED_FLOCK_WELFARE_MINIMUM
		if clause_id == &"rested_flock_warranty" else
		0
	)
	var arrival_lines: Array[String] = []
	for batch in arrival_batches:
		arrival_lines.append("%s  %s%s" % [
			String(batch.get("time", "9:00 AM")),
			_contract_lane_mix_label(batch.get("lane_mix", {}) as Dictionary),
			"  ·  RUSH" if bool(batch.get("contains_rush", false)) else "",
		])
	var requires_room := bool(clause.get("requires_negotiation_room", false))
	var success_required := "%d sound or golden folders delivered inside their disclosed service windows." % required_completed
	if welfare_gate_minimum > 0:
		success_required += " Closing flock welfare must also remain at %d or above." % welfare_gate_minimum
	return {
		"id": offer_id,
		"offer_id": offer_id,
		"name": String(definition.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(definition.get("short_name", "MUTUAL BINDER")),
		"client": String(definition.get("client", "FARM MUTUAL")),
		"tagline": String(definition.get("tagline", "Outside peckwork filed.")),
		"tone": StringName(definition.get("tone", &"quality")),
		"target_day": target_day,
		"deadline_day": target_day,
		"quote_id": "FM-%04d-%s-%s" % [
			target_day,
			String(offer_id).to_upper(),
			String(clause_id).to_upper(),
		],
		"season": season.duplicate(true),
		"season_id": season.get("id", &"baseline_neutral"),
		"season_label": String(season.get("label", "BASELINE NEUTRAL BOOK")),
		"season_demand_basis_points": season_demand_basis_points,
		"required_claim_capacity": int(definition.get("required_claim_capacity", 0)),
		"required_active_staff": int(definition.get("required_active_staff", 0)),
		"required_completed": required_completed,
		"required_deliveries": required_completed,
		"total_claims": total_claims,
		"rush_claims": rush_claims,
		"authored_service_window_minutes": authored_service_window,
		"service_window_minutes": service_window,
		"clause_id": clause_id,
		"clause_label": String(clause.get("label", "STANDARD TERMS")),
		"clause_summary": String(clause.get("summary", "")),
		"clause_category": StringName(clause.get("category", &"standard")),
		"category": StringName(clause.get("category", &"standard")),
		"label": String(clause.get("label", "STANDARD TERMS")),
		"summary": String(clause.get("summary", "")),
		"requires_negotiation_room": requires_room,
		"clause_available": not requires_room or negotiation_room_level > 0,
		"negotiation_room_level_at_signing": negotiation_room_level,
		"authored_base_premium_cents": authored_base_premium_cents,
		"base_premium_cents": authored_base_premium_cents,
		"season_premium_delta_cents": season_premium_delta_cents,
		"clause_premium_basis_points": clause_premium_basis_points,
		"clause_premium_delta_cents": clause_premium_delta_cents,
		"market_premium_cents": market_premium_cents,
		"service_coop_level_at_signing": service_coop_level,
		"service_coop_bonus_cents": service_coop_bonus_cents,
		"premium_bonus_basis_points": (
			service_coop_level * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"contracted_service_coop_bonus_cents": service_coop_bonus_cents,
		"contracted_premium_cents": premium_cents,
		"premium_cents": premium_cents,
		"authored_breach_cents": authored_breach_cents,
		"season_breach_basis_points": season_breach_basis_points,
		"season_breach_delta_cents": season_breach_delta_cents,
		"clause_breach_basis_points": clause_breach_basis_points,
		"clause_breach_delta_cents": clause_breach_delta_cents,
		"contracted_breach_cents": breach_cents,
		"breach_cents": breach_cents,
		"welfare_gate_minimum": welfare_gate_minimum,
		"welfare_gate_required": welfare_gate_minimum > 0,
		"authored_dominant_lane": String(authored_dominant_lane),
		"authored_lane_mix": authored_lane_mix,
		"lane_mix": lane_mix,
		"lane_mix_label": _contract_lane_mix_label(lane_mix),
		"rush_lane_mix": rush_lane_mix,
		"rush_lane_mix_label": _contract_lane_mix_label(rush_lane_mix),
		"arrival_batches": arrival_batches,
		"scheduled_claims": scheduled_claims,
		"arrival_schedule": "\n".join(arrival_lines),
		"success_required": success_required,
		"benefit": "+$%.2f closing premium on fulfillment ($%.2f market + $%.2f Service Coop)" % [
			float(premium_cents) / 100.0,
			float(market_premium_cents) / 100.0,
			float(service_coop_bonus_cents) / 100.0,
		],
		"tradeoff": "-$%.2f breach charge if the signed requirements are missed" % (
			float(breach_cents) / 100.0
		),
	}


func _market_contract_dominant_lane(definition: Dictionary) -> StringName:
	var authored_counts: Dictionary = {}
	for batch_value in definition.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		for lane_value in batch.get("lanes", []):
			var lane := StringName(String(lane_value))
			if lane in CLAIM_LANES:
				authored_counts[lane] = int(authored_counts.get(lane, 0)) + 1
	var dominant_lane: StringName = CLAIM_LANES[0]
	var dominant_count := -1
	for lane in CLAIM_LANES:
		var count := int(authored_counts.get(lane, 0))
		if count > dominant_count:
			dominant_count = count
			dominant_lane = lane
	return dominant_lane


func _contract_lane_mix(lanes: Array[String]) -> Dictionary:
	var mix: Dictionary = {}
	for lane in lanes:
		mix[lane] = int(mix.get(lane, 0)) + 1
	return mix


func _contract_lane_mix_label(mix: Dictionary) -> String:
	var parts: Array[String] = []
	for lane in CLAIM_LANES:
		var count := int(mix.get(String(lane), mix.get(lane, 0)))
		if count <= 0:
			continue
		parts.append("%s %d" % [String((CLAIM_LANE_DEFINITIONS[lane] as Dictionary)["short_name"]), count])
	return "  ·  ".join(parts) if not parts.is_empty() else "NO FOLDERS"


func _pending_market_contract_claim_count() -> int:
	if active_market_contract.is_empty() or int(active_market_contract.get("target_day", 0)) != day:
		return 0
	var count := 0
	for scheduled_value in active_market_contract.get("scheduled_claims", []):
		var scheduled := scheduled_value as Dictionary
		if not bool(scheduled.get("released", false)) and not bool(scheduled.get("rejected", false)):
			count += 1
	return count


func _release_due_market_contract_claims() -> int:
	if active_market_contract.is_empty() or int(active_market_contract.get("target_day", 0)) != day:
		return 0
	var scheduled_claims := active_market_contract.get("scheduled_claims", []) as Array
	var accepted_ids := active_market_contract.get("accepted_claim_ids", []) as Array
	var rejected_ids := active_market_contract.get("rejected_claim_ids", []) as Array
	var released_count := 0
	var released_batches: Dictionary = {}
	for schedule_value in scheduled_claims:
		var schedule := schedule_value as Dictionary
		if (
			bool(schedule.get("released", false))
			or bool(schedule.get("rejected", false))
			or int(schedule.get("arrival_minute_of_day", SHIFT_END_MINUTE + 1)) > minute_of_day
		):
			continue
		var claim_id := int(schedule.get("claim_id", -1))
		var lane := StringName(String(schedule.get("lane", "")))
		if claim_id < 1 or lane not in CLAIM_LANES:
			schedule["rejected"] = true
			rejected_ids.append(claim_id)
			continue
		if _outstanding_claim_count() >= current_claim_capacity():
			# This should be unreachable because pending contract folders reserve
			# capacity from ambient intake. Retain an explicit breach ledger instead
			# of laundering the failure into ordinary missed-intake value.
			schedule["rejected"] = true
			rejected_ids.append(claim_id)
			continue
		var definition := CLAIM_LANE_DEFINITIONS[lane] as Dictionary
		var arrival_minute_of_day := int(schedule.get("arrival_minute_of_day", minute_of_day))
		var deadline_minute_of_day := int(schedule.get("deadline_minute_of_day", SHIFT_END_MINUTE))
		var operational_start := _operational_minute_for_shift_start(day)
		var arrival_operational := operational_start + arrival_minute_of_day - SHIFT_START_MINUTE
		var deadline_operational := operational_start + deadline_minute_of_day - SHIFT_START_MINUTE
		var claim := ClaimState.new(
			claim_id,
			lane,
			"FARM MUTUAL · %s" % String(definition.get("display_name", "PECKWORK")),
			float(definition.get("base_difficulty", 1.0)),
			int(definition.get("base_value_cents", 0)),
			float(definition.get("crack_modifier", 0.0)),
			arrival_operational,
			deadline_operational,
			maxi(1, deadline_operational - arrival_operational),
			false,
			-1,
			day,
			0,
		)
		_append_claim_to_queue(claim)
		schedule["released"] = true
		accepted_ids.append(claim_id)
		released_batches[int(schedule.get("batch_index", 0))] = true
		released_count += 1
	active_market_contract["scheduled_claims"] = scheduled_claims
	active_market_contract["accepted_claim_ids"] = accepted_ids
	active_market_contract["rejected_claim_ids"] = rejected_ids
	var fully_released_batches := 0
	for batch_value in active_market_contract.get("arrival_batches", []):
		var batch := batch_value as Dictionary
		var batch_index := int(batch.get("batch_index", -1))
		var batch_complete := true
		for schedule_value in scheduled_claims:
			var schedule := schedule_value as Dictionary
			if int(schedule.get("batch_index", -2)) != batch_index:
				continue
			if not bool(schedule.get("released", false)) and not bool(schedule.get("rejected", false)):
				batch_complete = false
				break
		if batch_complete:
			fully_released_batches += 1
	active_market_contract["released_batch_count"] = fully_released_batches
	if released_count > 0:
		active_market_contract["status"] = "active"
		announcement_posted.emit(
			"FARM MUTUAL INTAKE: %d contracted folder%s arrived at %s without pausing production." % [
				released_count,
				"" if released_count == 1 else "s",
				_format_time(minute_of_day),
			]
		)
	return released_count


func _record_market_contract_completion(claim: ClaimState, quality: StringName) -> void:
	if claim == null or active_market_contract.is_empty():
		return
	if int(active_market_contract.get("target_day", 0)) != day:
		return
	var accepted_ids := active_market_contract.get("accepted_claim_ids", []) as Array
	var completed_ids := active_market_contract.get("completed_claim_ids", []) as Array
	if claim.id not in accepted_ids or claim.id in completed_ids:
		return
	var schedule: Dictionary = {}
	for schedule_value in active_market_contract.get("scheduled_claims", []):
		var candidate := schedule_value as Dictionary
		if int(candidate.get("claim_id", -1)) == claim.id:
			schedule = candidate
			break
	if schedule.is_empty():
		return
	var clean := quality in [&"sound", &"golden"]
	var on_time := minute_of_day <= int(schedule.get("deadline_minute_of_day", SHIFT_END_MINUTE))
	completed_ids.append(claim.id)
	active_market_contract["completed_claim_ids"] = completed_ids
	active_market_contract["completed_count"] = completed_ids.size()
	if clean:
		var sound_ids := active_market_contract.get("sound_completed_claim_ids", []) as Array
		sound_ids.append(claim.id)
		active_market_contract["sound_completed_claim_ids"] = sound_ids
		active_market_contract["sound_completed"] = sound_ids.size()
	else:
		var cracked_ids := active_market_contract.get("cracked_claim_ids", []) as Array
		cracked_ids.append(claim.id)
		active_market_contract["cracked_claim_ids"] = cracked_ids
		active_market_contract["cracked_count"] = cracked_ids.size()
	if clean and on_time:
		var timely_ids := active_market_contract.get("timely_sound_claim_ids", []) as Array
		timely_ids.append(claim.id)
		active_market_contract["timely_sound_claim_ids"] = timely_ids
		active_market_contract["timely_sound_completed"] = timely_ids.size()
		if bool(schedule.get("rush", false)):
			active_market_contract["rush_completed_on_time"] = int(
				active_market_contract.get("rush_completed_on_time", 0)
			) + 1
	else:
		var late_ids := active_market_contract.get("late_claim_ids", []) as Array
		late_ids.append(claim.id)
		active_market_contract["late_claim_ids"] = late_ids
		active_market_contract["late_count"] = late_ids.size()
	var delivered := int(active_market_contract.get("timely_sound_completed", 0))
	var required := int(active_market_contract.get("required_completed", 0))
	active_market_contract["remaining_required"] = maxi(0, required - delivered)
	if delivered == required:
		announcement_posted.emit(
			"FARM MUTUAL THRESHOLD MET: %d clean folders arrived on time; the premium is pending close." % required
		)
	elif bool(schedule.get("rush", false)) and not (clean and on_time):
		announcement_posted.emit(
			"CONTRACT RUSH MISSED: folder #%04d was %s; Farm Mutual retained the breach clause." % [
				claim.id,
				("cracked" if not clean else "late"),
			]
		)


func _settle_market_contract(completed_day: int) -> Dictionary:
	if (
		active_market_contract.is_empty()
		or int(active_market_contract.get("target_day", 0)) != completed_day
	):
		return {}
	_finalize_market_contract_schedule_evidence()
	var completed_contract := active_market_contract.duplicate(true)
	var delivered := int(completed_contract.get("timely_sound_completed", 0))
	var required := int(completed_contract.get("required_completed", 0))
	var closing_welfare := _flock_welfare_score()
	var welfare_gate_minimum := int(completed_contract.get("welfare_gate_minimum", 0))
	var delivery_threshold_met := delivered >= required
	var welfare_gate_met := welfare_gate_minimum <= 0 or closing_welfare >= welfare_gate_minimum
	var success := delivery_threshold_met and welfare_gate_met
	var base_premium_cents := int(completed_contract.get("base_premium_cents", 0))
	var contracted_service_bonus_cents := int(completed_contract.get("service_coop_bonus_cents", 0))
	var contracted_premium_cents := int(completed_contract.get("premium_cents", 0))
	var contracted_breach_cents := int(completed_contract.get("breach_cents", 0))
	var premium_cents := contracted_premium_cents if success else 0
	var service_coop_bonus_cents := contracted_service_bonus_cents if success else 0
	var breach_cents := contracted_breach_cents if not success else 0
	var fund_before := revenue_cents
	var standing_before := farm_mutual_standing()
	var clean_streak_before := market_clean_contract_streak
	if success:
		revenue_cents += premium_cents
		credited_today_cents += premium_cents
		market_contract_premium_today_cents += premium_cents
		market_contract_premium_total_cents += premium_cents
		market_contracts_succeeded_total += 1
		market_clean_contract_streak += 1
		best_market_clean_contract_streak = maxi(
			best_market_clean_contract_streak,
			market_clean_contract_streak,
		)
	else:
		# The full authored clause was reserved at signing and protected from every
		# discretionary debit thereafter. Settlement therefore remains an exact
		# integer-cent sink instead of quietly converting insolvency into a discount.
		if revenue_cents < breach_cents:
			push_error("Farm Mutual breach reserve invariant failed before settlement.")
		revenue_cents = maxi(0, revenue_cents - breach_cents)
		market_contract_breach_today_cents += breach_cents
		market_contract_breach_total_cents += breach_cents
		market_contracts_breached_total += 1
		market_clean_contract_streak = 0
	var standing_after := farm_mutual_standing()
	var settlement_outcome := ""
	if success:
		settlement_outcome = "%s fulfilled: Farm Mutual credited a $%.2f premium after the flock delivered %d/%d clean folders on time." % [
			String(completed_contract.get("short_name", "Contract")),
			float(premium_cents) / 100.0,
			delivered,
			required,
		]
	elif delivery_threshold_met and not welfare_gate_met:
		settlement_outcome = "%s breached: its rested-flock welfare safeguard failed at %d/%d despite %d/%d clean folders arriving on time; Farm Mutual charged $%.2f." % [
			String(completed_contract.get("short_name", "Contract")),
			closing_welfare,
			welfare_gate_minimum,
			delivered,
			required,
			float(breach_cents) / 100.0,
		]
	else:
		settlement_outcome = "%s breached: Farm Mutual charged $%.2f after only %d/%d clean folders arrived on time." % [
			String(completed_contract.get("short_name", "Contract")),
			float(breach_cents) / 100.0,
			delivered,
			required,
		]
	var result := {
		"version": 2,
		"contract_id": String(completed_contract.get("contract_id", "")),
		"offer_id": String(completed_contract.get("offer_id", "")),
		"name": String(completed_contract.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(completed_contract.get("short_name", "MUTUAL BINDER")),
		"client": String(completed_contract.get("client", "FARM MUTUAL")),
		"day": completed_day,
		"target_day": completed_day,
		"status": "fulfilled" if success else "breached",
		"success": success,
		"delivery_threshold_met": delivery_threshold_met,
		"welfare_gate_met": welfare_gate_met,
		"closing_welfare": closing_welfare,
		"welfare_gate_minimum": welfare_gate_minimum,
		"welfare_gate_required": welfare_gate_minimum > 0,
		"required_completed": required,
		"timely_sound_completed": delivered,
		"sound_completed": int(completed_contract.get("sound_completed", 0)),
		"completed_count": int(completed_contract.get("completed_count", 0)),
		"total_claims": int(completed_contract.get("total_claims", 0)),
		"rush_claims": int(completed_contract.get("rush_claims", 0)),
		"rush_completed_on_time": int(completed_contract.get("rush_completed_on_time", 0)),
		"cracked_count": int(completed_contract.get("cracked_count", 0)),
		"late_count": int(completed_contract.get("late_count", 0)),
		"rejected_count": (completed_contract.get("rejected_claim_ids", []) as Array).size(),
		"required_active_staff": int(completed_contract.get("required_active_staff", 0)),
		"legacy_terms_grandfathered": bool(
			completed_contract.get("legacy_terms_grandfathered", false)
		),
		"season": (completed_contract.get("season", {}) as Dictionary).duplicate(true),
		"season_id": completed_contract.get("season_id", &"baseline_neutral"),
		"season_label": String(completed_contract.get("season_label", "BASELINE NEUTRAL BOOK")),
		"season_demand_basis_points": int(
			completed_contract.get("season_demand_basis_points", 0)
		),
		"clause_id": completed_contract.get("clause_id", &"standard_terms"),
		"clause_label": String(completed_contract.get("clause_label", "STANDARD TERMS")),
		"clause_summary": String(completed_contract.get("clause_summary", "")),
		"clause_category": completed_contract.get("clause_category", &"standard"),
		"negotiation_room_level_at_signing": int(
			completed_contract.get("negotiation_room_level_at_signing", 0)
		),
		"authored_service_window_minutes": int(
			completed_contract.get("authored_service_window_minutes", 0)
		),
		"service_window_minutes": int(completed_contract.get("service_window_minutes", 0)),
		"authored_dominant_lane": String(
			completed_contract.get("authored_dominant_lane", "")
		),
		"authored_lane_mix": (
			completed_contract.get("authored_lane_mix", {}) as Dictionary
		).duplicate(true),
		"lane_mix": (completed_contract.get("lane_mix", {}) as Dictionary).duplicate(true),
		"arrival_batches": (
			completed_contract.get("arrival_batches", []) as Array
		).duplicate(true),
		"scheduled_claims": (
			completed_contract.get("scheduled_claims", []) as Array
		).duplicate(true),
		"claim_ids": (
			completed_contract.get("claim_ids", []) as Array
		).duplicate(),
		"accepted_claim_ids": (
			completed_contract.get("accepted_claim_ids", []) as Array
		).duplicate(),
		"rejected_claim_ids": (
			completed_contract.get("rejected_claim_ids", []) as Array
		).duplicate(),
		"authored_base_premium_cents": int(
			completed_contract.get("authored_base_premium_cents", base_premium_cents)
		),
		"base_premium_cents": base_premium_cents,
		"season_premium_delta_cents": int(
			completed_contract.get("season_premium_delta_cents", 0)
		),
		"clause_premium_basis_points": int(
			completed_contract.get("clause_premium_basis_points", 0)
		),
		"clause_premium_delta_cents": int(
			completed_contract.get("clause_premium_delta_cents", 0)
		),
		"market_premium_cents": int(
			completed_contract.get("market_premium_cents", base_premium_cents)
		),
		"service_coop_level_at_signing": int(completed_contract.get("service_coop_level_at_signing", 0)),
		"service_coop_bonus_cents": service_coop_bonus_cents,
		"contracted_service_coop_bonus_cents": contracted_service_bonus_cents,
		"premium_bonus_basis_points": int(completed_contract.get("premium_bonus_basis_points", 0)),
		"contracted_premium_cents": contracted_premium_cents,
		"premium_cents": premium_cents,
		"authored_breach_cents": int(
			completed_contract.get("authored_breach_cents", contracted_breach_cents)
		),
		"season_breach_basis_points": int(
			completed_contract.get("season_breach_basis_points", 0)
		),
		"season_breach_delta_cents": int(
			completed_contract.get("season_breach_delta_cents", 0)
		),
		"clause_breach_basis_points": int(
			completed_contract.get("clause_breach_basis_points", 0)
		),
		"clause_breach_delta_cents": int(
			completed_contract.get("clause_breach_delta_cents", 0)
		),
		"contracted_breach_cents": contracted_breach_cents,
		"breach_cents": breach_cents,
		"net_contract_cents": premium_cents - breach_cents,
		"fund_before_cents": fund_before,
		"fund_after_cents": revenue_cents,
		"market_standing_before": standing_before,
		"market_standing_after": standing_after,
		"market_standing_delta": standing_after - standing_before,
		"market_standing_rank": farm_mutual_standing_rank(),
		"clean_contract_streak_before": clean_streak_before,
		"clean_contract_streak_after": market_clean_contract_streak,
		"best_clean_contract_streak": best_market_clean_contract_streak,
		"outcome": settlement_outcome,
	}
	last_market_contract_result = result.duplicate(true)
	active_market_contract.clear()
	announcement_posted.emit(String(result["outcome"]))
	market_contract_settled.emit(result.duplicate(true))
	return result


func _finalize_market_contract_schedule_evidence() -> void:
	## Settlement is terminal. Any authored folder that never entered intake becomes
	## an explicit rejection instead of leaving an ambiguous third schedule state.
	var schedules := active_market_contract.get("scheduled_claims", []) as Array
	var rejected_ids := active_market_contract.get("rejected_claim_ids", []) as Array
	for index in schedules.size():
		var schedule := (schedules[index] as Dictionary).duplicate(true)
		if not bool(schedule.get("released", false)) and not bool(schedule.get("rejected", false)):
			var claim_id := int(schedule.get("claim_id", -1))
			schedule["rejected"] = true
			if claim_id > 0 and claim_id not in rejected_ids:
				rejected_ids.append(claim_id)
		schedules[index] = schedule
	active_market_contract["scheduled_claims"] = schedules
	active_market_contract["rejected_claim_ids"] = rejected_ids


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


func current_daily_payroll_cents() -> int:
	return current_daily_hen_payroll_cents() + current_daily_supervisor_payroll_cents()


func daily_facility_expansion_cost_cents() -> int:
	return maxi(0, office_capacity - 4) * FACILITY_COST_PER_EXPANDED_SEAT_CENTS


func current_daily_facility_maintenance_cents() -> int:
	var maintenance_cents := 0
	for facility_id in FACILITY_ORDER:
		var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
		maintenance_cents += _facility_maintenance_for_level(
			definition,
			facility_level(facility_id),
		)
	return maintenance_cents


func current_daily_facility_cost_cents() -> int:
	return (
		daily_facility_expansion_cost_cents()
		+ current_daily_facility_maintenance_cents()
		+ current_daily_campus_cost_cents()
		+ current_daily_portfolio_cost_cents()
	)


func current_daily_operating_cost_cents() -> int:
	return (
		current_daily_feed_cost_cents()
		+ current_daily_facility_cost_cents()
		+ current_daily_payroll_cents()
	)


func current_market_contract_reserve_cents() -> int:
	## A signed binder never charges its breach clause up front. The possible
	## charge is nevertheless protected from discretionary spending until the
	## target shift settles, so failure cannot create money or erase payroll.
	if active_market_contract.is_empty():
		return 0
	if int(active_market_contract.get("target_day", 0)) != day:
		return 0
	return maxi(0, int(active_market_contract.get("breach_cents", 0)))


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
	var treasury := farm_treasury_snapshot()
	return maxi(0, int(treasury.get("total_liabilities_cents", 0)))


func farm_treasury_capital_frozen() -> bool:
	var treasury := farm_treasury_snapshot()
	return bool(treasury.get("capital_frozen", false))


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


func _projected_spendable_after_obligation_change_cents(
	one_time_cost_cents: int,
	added_daily_operating_cents: int
) -> int:
	## Keep this value raw rather than clamping it to zero: a negative projection
	## is the exact reserve deficit that must block the transaction atomically.
	if (
		farm_treasury_capital_frozen()
		and (one_time_cost_cents > 0 or added_daily_operating_cents > 0)
	):
		return -maxi(1, one_time_cost_cents + added_daily_operating_cents)
	return (
		revenue_cents
		- maxi(0, one_time_cost_cents)
		- wage_arrears_cents
		- current_daily_operating_cost_cents()
		- current_market_contract_reserve_cents()
		- farm_treasury_liabilities_cents()
		- added_daily_operating_cents
	)


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


func _manager_action_save_data() -> Dictionary:
	var result := last_manager_action.duplicate(true)
	for id_field in ["action_id", "manager_id", "choice_id", "replaced_manager_id"]:
		if result.has(id_field):
			result[id_field] = String(result[id_field])
	return result


func export_save_state() -> Dictionary:
	## This is the authoritative simulation checkpoint. It intentionally contains
	## only primitives so the campaign save remains portable to Web builds.
	# Tests and administrative tools may advance `day` directly. Normalize the
	# ledger to that authoritative day before serializing so stale daily counters
	# can never be emitted under a newer checkpoint date.
	_feed_procurement.begin_day(day)
	_farmgate_dispatch.begin_day(day)
	_campus_portfolio.begin_day(day, _campus_portfolio_context())
	# Administrative/test fixtures may set permanent facility ownership directly.
	# Materialize every already-funded post before serializing that authority.
	_ensure_manager_posts_for_office_level()
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
	var saved_facilities: Dictionary = {}
	for facility_id in FACILITY_ORDER:
		saved_facilities[String(facility_id)] = facility_level(facility_id)
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
	var saved_incident_bag: Array[String] = []
	for incident_id in _incident_bag:
		saved_incident_bag.append(String(incident_id))
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
		"first_clutch_reinvestment": first_clutch_reinvestment.duplicate(true),
		"requisition_spend_today_cents": requisition_spend_today_cents,
		"requisition_spend_total_cents": requisition_spend_total_cents,
		"orientation_procurement_match_today_cents": orientation_procurement_match_today_cents,
		"orientation_procurement_match_total_cents": orientation_procurement_match_total_cents,
		"lane_processed_totals": saved_lane_totals,
		"lane_processed_today": saved_lane_today,
		"campaign_unlocks": saved_unlocks,
		"owned_facilities": saved_facilities,
		"manager_roster_version": MANAGER_ROSTER_VERSION,
		"manager_roster": manager_roster.duplicate(true),
		"last_manager_action": _manager_action_save_data(),
		"management_reports_today": management_reports_today,
		"management_reports_total": management_reports_total,
		"management_visibility_today": management_visibility_today,
		"feed_procurement_state": _feed_procurement.to_save_data(),
		"harvest_credit_state": _harvest_credit.to_save_data(),
		"farmgate_dispatch_state": _farmgate_dispatch.to_save_data(),
		"farm_treasury_state": _farm_treasury.to_save_data(),
		"pinned_capital_plan_id": String(pinned_capital_plan_id),
		"last_facility_purchase_receipt": last_facility_purchase_receipt.duplicate(true),
		"facility_commissioning_history": facility_commissioning_history.duplicate(true),
		"campus_expansion": campus_expansion_state.duplicate(true),
		"campus_portfolio": _campus_portfolio.to_save_data(),
		"packing_carton_progress": packing_carton_progress,
		"packing_cartons_today": packing_cartons_today,
		"packing_cartons_total": packing_cartons_total,
		"packing_value_bonus_today_cents": packing_value_bonus_today_cents,
		"packing_value_bonus_total_cents": packing_value_bonus_total_cents,
		"packing_carton_bonus_today_cents": packing_carton_bonus_today_cents,
		"packing_carton_bonus_total_cents": packing_carton_bonus_total_cents,
		"intake_rejections_today": intake_rejections_today,
		"intake_rejections_total": intake_rejections_total,
		"intake_missed_value_today_cents": intake_missed_value_today_cents,
		"intake_missed_value_total_cents": intake_missed_value_total_cents,
		"active_market_contract": active_market_contract.duplicate(true),
		"market_contract_decline_receipt": market_contract_decline_receipt.duplicate(true),
		"last_market_contract_result": last_market_contract_result.duplicate(true),
		"market_contracts_signed_total": market_contracts_signed_total,
		"market_contracts_succeeded_total": market_contracts_succeeded_total,
		"market_contracts_breached_total": market_contracts_breached_total,
		"market_clean_contract_streak": market_clean_contract_streak,
		"best_market_clean_contract_streak": best_market_clean_contract_streak,
		"market_contract_premium_today_cents": market_contract_premium_today_cents,
		"market_contract_premium_total_cents": market_contract_premium_total_cents,
		"market_contract_breach_today_cents": market_contract_breach_today_cents,
		"market_contract_breach_total_cents": market_contract_breach_total_cents,
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
		"flock_relations_open_cases": flock_relations_open_cases.duplicate(true),
		"flock_relations_resolutions_used_today": flock_relations_resolutions_used_today,
		"flock_relations_resolved_total": flock_relations_resolved_total,
		"flock_relations_denied_total": flock_relations_denied_total,
		"flock_relations_settlement_spend_total_cents": flock_relations_settlement_spend_total_cents,
		"last_flock_relations_resolution": last_flock_relations_resolution.duplicate(true),
		"flock_relations_resolution_history": flock_relations_resolution_history.duplicate(true),
		"next_flock_relations_case_id": next_flock_relations_case_id,
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
		"career_seed": _career_seed,
		"incident_rng_state": str(_incident_rng.state),
		"incident_bag": saved_incident_bag,
		"last_standard_incident_id": String(_last_standard_incident_id),
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
	if not _is_integral_number(data.get("career_seed", null)):
		return false
	var restored_career_seed := int(data.get("career_seed", 0))
	if restored_career_seed < 1 or restored_career_seed > 2_000_000_000:
		return false
	var incident_rng_value: Variant = data.get("incident_rng_state", null)
	if typeof(incident_rng_value) != TYPE_STRING or not String(incident_rng_value).is_valid_int():
		return false
	var incident_bag_value: Variant = data.get("incident_bag", null)
	if not incident_bag_value is Array or (incident_bag_value as Array).size() > INCIDENT_ORDER.size() - 1:
		return false
	var restored_incident_bag: Array[StringName] = []
	var seen_incident_ids: Dictionary[StringName, bool] = {}
	for incident_value in incident_bag_value as Array:
		if typeof(incident_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return false
		var incident_id := StringName(String(incident_value))
		if incident_id not in INCIDENT_ORDER or seen_incident_ids.has(incident_id):
			return false
		seen_incident_ids[incident_id] = true
		restored_incident_bag.append(incident_id)
	var last_incident_value: Variant = data.get("last_standard_incident_id", null)
	if typeof(last_incident_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	var restored_last_standard_incident_id := StringName(String(last_incident_value))
	if (
		restored_last_standard_incident_id != &""
		and restored_last_standard_incident_id not in INCIDENT_ORDER
	):
		return false
	if (
		(restored_last_standard_incident_id == &"" and not restored_incident_bag.is_empty())
		or seen_incident_ids.has(restored_last_standard_incident_id)
	):
		return false
	if not _is_integral_number(data.get("shift_phase", null)):
		return false
	var saved_shift_phase := int(data.get("shift_phase", -1))
	if saved_shift_phase not in [
		ShiftPhase.AWAITING_DIRECTIVE,
		ShiftPhase.RUNNING,
		ShiftPhase.AWAITING_INCIDENT,
		ShiftPhase.REVIEW,
	]:
		return false
	var restored_upgrade_levels := _validated_upgrade_levels(data.get("upgrade_levels", null))
	if restored_upgrade_levels.size() != UPGRADE_ORDER.size():
		return false
	for ledger_field in [
		"requisition_spend_today_cents",
		"requisition_spend_total_cents",
		"orientation_procurement_match_today_cents",
		"orientation_procurement_match_total_cents",
	]:
		if not _is_integral_number(data.get(ledger_field, null)):
			return false
	var restored_requisition_spend_today := int(data.get("requisition_spend_today_cents", -1))
	var restored_requisition_spend_total := int(data.get("requisition_spend_total_cents", -1))
	var restored_orientation_match_today := int(data.get(
		"orientation_procurement_match_today_cents",
		-1,
	))
	var restored_orientation_match_total := int(data.get(
		"orientation_procurement_match_total_cents",
		-1,
	))
	if (
		restored_requisition_spend_today < 0
		or restored_requisition_spend_today > restored_requisition_spend_total
		or restored_requisition_spend_total > 2_000_000_000
		or restored_orientation_match_today < 0
		or restored_orientation_match_today > restored_orientation_match_total
		or restored_orientation_match_total > ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS
	):
		return false
	var validated_reinvestment := _validated_first_clutch_reinvestment(
		data.get("first_clutch_reinvestment", null),
		saved_day,
		restored_upgrade_levels,
	)
	if not bool(validated_reinvestment.get("valid", false)):
		return false
	var restored_first_clutch_reinvestment := (
		validated_reinvestment.get("record", {}) as Dictionary
	)
	var reinvestment_match_used := int(
		restored_first_clutch_reinvestment.get("procurement_match_used_cents", 0)
	)
	if (
		restored_orientation_match_total != reinvestment_match_used
		or (
			restored_orientation_match_today > 0
			and int(restored_first_clutch_reinvestment.get("resolved_day", 0)) != saved_day
		)
		or restored_requisition_spend_total
		!= _cumulative_upgrade_spend_cents(restored_upgrade_levels) - reinvestment_match_used
	):
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
	var restored_owned_facilities := _validated_owned_facilities(
		data.get("owned_facilities", null),
	)
	if restored_owned_facilities.size() != FACILITY_ORDER.size():
		return false
	var restored_manager_roster := _validated_manager_roster(
		data.get("manager_roster", null),
		int(restored_owned_facilities.get(ROOSTER_OPERATIONS_OFFICE_ID, 0)),
	)
	if restored_manager_roster.is_empty():
		return false
	for management_field in [
		"management_reports_today", "management_reports_total", "management_visibility_today",
	]:
		if not _is_integral_number(data.get(management_field, null)):
			return false
	var restored_reports_today := int(data.get("management_reports_today", -1))
	var restored_reports_total := int(data.get("management_reports_total", -1))
	var restored_visibility_today := int(data.get("management_visibility_today", -1))
	if (
		restored_reports_today < 0 or restored_reports_today > restored_manager_roster.size()
		or restored_reports_total < restored_reports_today or restored_reports_total > 2_000_000_000
		or restored_visibility_today < 0 or restored_visibility_today > restored_manager_roster.size()
	):
		return false
	var restored_last_manager_action_value: Variant = data.get("last_manager_action", {})
	if not restored_last_manager_action_value is Dictionary:
		return false
	var restored_last_manager_action := (restored_last_manager_action_value as Dictionary).duplicate(true)
	if not restored_last_manager_action.is_empty():
		for id_field in ["action_id", "manager_id", "choice_id", "replaced_manager_id"]:
			if restored_last_manager_action.has(id_field):
				restored_last_manager_action[id_field] = StringName(String(restored_last_manager_action[id_field]))
		restored_last_manager_action["day"] = int(restored_last_manager_action.get("day", 0))
		for money_field in ["cost_cents", "fund_before_cents", "fund_after_cents"]:
			if restored_last_manager_action.has(money_field):
				restored_last_manager_action[money_field] = int(restored_last_manager_action[money_field])
	var saved_unlock_values: Variant = data.get("campaign_unlocks", {})
	if not saved_unlock_values is Dictionary:
		return false
	for facility_id in FACILITY_ORDER:
		var restored_facility_level := int(restored_owned_facilities.get(facility_id, 0))
		if restored_facility_level <= 0:
			continue
		var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
		if saved_day < _facility_unlock_day_for_level(definition, restored_facility_level):
			return false
		var unlock_id := StringName(definition.get("unlock_id", &""))
		if unlock_id != &"":
			var saved_unlocks := saved_unlock_values as Dictionary
			var unlock_value: Variant = saved_unlocks.get(
				String(unlock_id),
				saved_unlocks.get(unlock_id, null),
			)
			if typeof(unlock_value) != TYPE_BOOL or not bool(unlock_value):
				return false
	var restored_service_coop_level := int(
		restored_owned_facilities.get(FARM_MUTUAL_SERVICE_COOP_ID, 0)
	)
	if restored_service_coop_level > 0:
		var required_coop_capacity := _service_coop_requirement(
			SERVICE_COOP_LEVEL_CLAIM_CAPACITY_REQUIREMENTS,
			restored_service_coop_level,
		)
		var required_coop_office_capacity := _service_coop_requirement(
			SERVICE_COOP_LEVEL_ACTIVE_STAFF_REQUIREMENTS,
			restored_service_coop_level,
		)
		# Standing and active headcount may fall after a legitimate purchase, so
		# neither may demote or invalidate ownership. Records and authorized desk
		# capacity never shrink and therefore remain strict purchase evidence.
		if (
			_claim_capacity_for_facilities(restored_owned_facilities) < required_coop_capacity
			or saved_office_capacity < required_coop_office_capacity
		):
			return false
	var restored_negotiation_room_level := int(
		restored_owned_facilities.get(FARM_MUTUAL_NEGOTIATION_ROOM_ID, 0)
	)
	# Standing may fall after a legitimate room purchase, but its physical Service
	# Coop dependency cannot disappear from a structurally valid checkpoint.
	if (
		restored_negotiation_room_level > 0
		and restored_service_coop_level < NEGOTIATION_ROOM_REQUIRED_SERVICE_COOP_LEVEL
	):
		return false
	var restored_wellness_level := int(
		restored_owned_facilities.get(WELLNESS_NEST_ID, 0)
	)
	if (
		restored_wellness_level > 0
		and saved_office_capacity < _facility_tier_requirement(
			WELLNESS_NEST_OFFICE_CAPACITY_REQUIREMENTS,
			restored_wellness_level,
		)
	):
		return false
	var restored_training_level := int(
		restored_owned_facilities.get(TRAINING_ROOST_ID, 0)
	)
	# Active headcount and career qualification may fall after a legitimate
	# purchase. Authorized desk capacity and the matching Wellness tier cannot.
	if (
		restored_training_level > restored_wellness_level
		or (
			restored_training_level > 0
			and saved_office_capacity < _facility_tier_requirement(
				TRAINING_ROOST_OFFICE_CAPACITY_REQUIREMENTS,
				restored_training_level,
			)
		)
	):
		return false
	var restored_rooster_operations_level := int(
		restored_owned_facilities.get(ROOSTER_OPERATIONS_OFFICE_ID, 0)
	)
	if (
		restored_rooster_operations_level > 0
		and saved_office_capacity < _facility_tier_requirement(
			ROOSTER_OPERATIONS_OFFICE_CAPACITY_REQUIREMENTS,
			restored_rooster_operations_level,
		)
	):
		return false
	var restored_it_coop_level := int(
		restored_owned_facilities.get(IT_COOP_ID, 0)
	)
	var restored_records_annex_level := int(
		restored_owned_facilities.get(RECORDS_ANNEX_ID, 0)
	)
	# Headcount may fall after a legitimate purchase. Authorized capacity and
	# permanent Records/Rooster dependencies cannot disappear from a valid save.
	if (
		restored_it_coop_level > restored_records_annex_level
		or restored_it_coop_level > restored_rooster_operations_level
		or (
			restored_it_coop_level > 0
			and saved_office_capacity < _facility_tier_requirement(
				IT_COOP_OFFICE_CAPACITY_REQUIREMENTS,
				restored_it_coop_level,
			)
		)
	):
		return false
	var restored_flock_relations_level := int(
		restored_owned_facilities.get(FLOCK_RELATIONS_OFFICE_ID, 0)
	)
	# Headcount may fall after commissioning. Authorized capacity and the matching
	# permanent Rooster Operations / Wellness tiers remain strict purchase evidence.
	if (
		restored_flock_relations_level > restored_rooster_operations_level
		or restored_flock_relations_level > restored_wellness_level
		or (
			restored_flock_relations_level > 0
			and saved_office_capacity < _facility_tier_requirement(
				FLOCK_RELATIONS_OFFICE_CAPACITY_REQUIREMENTS,
				restored_flock_relations_level,
			)
		)
	):
		return false
	var restored_feed_procurement_level := int(
		restored_owned_facilities.get(FEED_PROCUREMENT_COOP_ID, 0)
	)
	# Active headcount may fall after commissioning; authorized desks and the
	# tier's physical bin capacity remain permanent purchase evidence.
	if (
		restored_feed_procurement_level > 0
		and saved_office_capacity < _facility_tier_requirement(
			FEED_PROCUREMENT_OFFICE_CAPACITY_REQUIREMENTS,
			restored_feed_procurement_level,
		)
	):
		return false
	var restored_feed_base_capacity := _facility_level_schedule_value(
		FEED_PROCUREMENT_CAPACITY_SCOOPS,
		restored_feed_procurement_level,
		0,
	)
	var restored_farmer_relations_gallery_level := int(
		restored_owned_facilities.get(FARMER_RELATIONS_GALLERY_ID, 0)
	)
	var restored_packing_annex_level := int(
		restored_owned_facilities.get(PACKING_ANNEX_ID, 0)
	)
	# Active staffing may fall after commissioning, but the permanent matching
	# Packing Annex and authorized desk capacity are structural purchase evidence.
	if (
		restored_farmer_relations_gallery_level > restored_packing_annex_level
		or (
			restored_farmer_relations_gallery_level > 0
			and saved_office_capacity < _facility_tier_requirement(
				FARMER_RELATIONS_GALLERY_OFFICE_CAPACITY_REQUIREMENTS,
				restored_farmer_relations_gallery_level,
			)
		)
	):
		return false
	var restored_harvest_credit = HarvestCreditStateScript.new()
	if not restored_harvest_credit.restore_save_data(
		data.get("harvest_credit_state", null),
		saved_day,
		restored_farmer_relations_gallery_level,
	):
		return false
	var restored_farm_treasury = FarmTreasuryStateScript.new()
	if not restored_farm_treasury.restore_save_data(
		data.get("farm_treasury_state", null)
	):
		return false
	# A checkpoint may be taken during the current shift, but its treasury may
	# never claim to have closed that shift—or a future one—already.
	if restored_farm_treasury.last_closed_day > maxi(0, saved_day - 1):
		return false
	var validated_campus_expansion := _validated_campus_expansion_state(
		data.get("campus_expansion", null),
		saved_day,
	)
	if not bool(validated_campus_expansion.get("valid", false)):
		return false
	var restored_campus_expansion := (
		validated_campus_expansion.get("state", {}) as Dictionary
	).duplicate(true)
	var portfolio_restore_worker_ids: Array[int] = []
	var portfolio_restore_worker_names: Dictionary = {}
	for worker_index in workers.size():
		portfolio_restore_worker_ids.append(worker_index)
		portfolio_restore_worker_names[worker_index] = workers[worker_index].display_name
	var restored_portfolio_context := _campus_portfolio_context(
		saved_shift_phase == ShiftPhase.REVIEW,
		portfolio_restore_worker_ids,
		portfolio_restore_worker_names,
		restored_campus_expansion,
		saved_day,
	)
	var restored_campus_portfolio = CampusPortfolioStateScript.new(saved_day)
	if not restored_campus_portfolio.restore_save_data(
		data.get("campus_portfolio", null),
		saved_day,
		portfolio_restore_worker_ids,
		restored_portfolio_context,
	):
		return false
	var restored_feed_capacity := (
		restored_feed_base_capacity
		+ restored_campus_portfolio.feed_capacity_bonus_scoops(restored_portfolio_context)
	)
	var restored_feed_procurement = FeedProcurementStateScript.new()
	if not restored_feed_procurement.restore_save_data(
		data.get("feed_procurement_state", null),
		saved_day,
		restored_feed_capacity,
		restored_feed_procurement_level,
	) or not _is_valid_feed_procurement_quote_state(restored_feed_procurement):
		return false
	var restored_farmgate_dispatch_level := int(
		restored_owned_facilities.get(FARMGATE_DISPATCH_DEPOT_ID, 0)
	)
	var restored_campus_history := (
		restored_campus_expansion.get("history", []) as Array
	)
	if not restored_campus_history.is_empty():
		var campus_access_receipt := restored_campus_history[0] as Dictionary
		if (
			StringName(campus_access_receipt.get("access_gate_id", &"")) == &"farmgate_dispatch"
			and restored_farmgate_dispatch_level
			< int(campus_access_receipt.get("access_farmgate_level", 0))
		):
			return false
	# Staffing and standing can change after a permanent tier is commissioned.
	# Authorized desk capacity and the matching physical Packing/Gallery tiers are
	# permanent structural evidence and therefore remain strict.
	if (
		restored_farmgate_dispatch_level > restored_packing_annex_level
		or restored_farmgate_dispatch_level > restored_farmer_relations_gallery_level
		or (
			restored_farmgate_dispatch_level > 0
			and saved_office_capacity < _facility_tier_requirement(
				FARMGATE_DISPATCH_OFFICE_CAPACITY_REQUIREMENTS,
				restored_farmgate_dispatch_level,
			)
		)
	):
		return false
	var restored_farmgate_dispatch = FarmgateDispatchStateScript.new()
	if not restored_farmgate_dispatch.restore_save_data(
		data.get("farmgate_dispatch_state", null),
		saved_day,
			_farmgate_storage_capacity_for_level_and_campus(
				restored_farmgate_dispatch_level,
				restored_campus_expansion,
				restored_campus_portfolio.farmgate_capacity_bonus_eggs(
					restored_portfolio_context
				),
			),
		restored_farmgate_dispatch_level,
	):
		return false
	var restored_active_farmgate := restored_farmgate_dispatch.active_mandate as Dictionary
	if not restored_active_farmgate.is_empty():
		var active_farmgate_level := int(restored_active_farmgate.get("facility_level", 0))
		var expected_farmgate_season := market_season_for_day(saved_day)
		var expected_farmgate_season_id := StringName(expected_farmgate_season.get("id", &"spring_hatch_surge"))
		var active_farmgate_mandate_id := StringName(restored_active_farmgate.get("mandate_id", &""))
		if (
			StringName(restored_active_farmgate.get("season_id", &"")) != expected_farmgate_season_id
			or int(restored_active_farmgate.get("dispatch_limit", 0))
			!= _facility_level_schedule_value(
				FARMGATE_DISPATCH_DAILY_DISPATCH_EGGS,
				active_farmgate_level,
				0,
			)
			or (
				active_farmgate_mandate_id == FarmgateDispatchStateScript.COUNTY_AUCTION
				and int(restored_active_farmgate.get("price_basis_points", 0))
				!= _farmgate_auction_basis_points(expected_farmgate_season_id)
			)
		):
			return false
	var restored_last_farmgate_authorization := restored_farmgate_dispatch.last_authorization as Dictionary
	if not restored_last_farmgate_authorization.is_empty():
		var authorization_day := int(restored_last_farmgate_authorization.get("target_day", 0))
		var authorization_season := market_season_for_day(authorization_day)
		var authorization_season_id := StringName(authorization_season.get("id", &"spring_hatch_surge"))
		if (
			StringName(restored_last_farmgate_authorization.get("season_id", &"")) != authorization_season_id
			or (
				StringName(restored_last_farmgate_authorization.get("mandate_id", &""))
				== FarmgateDispatchStateScript.COUNTY_AUCTION
				and int(restored_last_farmgate_authorization.get("price_basis_points", 0))
				!= _farmgate_auction_basis_points(authorization_season_id)
			)
		):
			return false
	for settlement_value in restored_farmgate_dispatch.history:
		var settlement := settlement_value as Dictionary
		var settlement_day := int(settlement.get("day", 0))
		var settlement_mandate_id := StringName(settlement.get("mandate_id", &""))
		var expected_settlement_season := market_season_for_day(settlement_day)
		var expected_settlement_season_id := StringName(expected_settlement_season.get("id", &"spring_hatch_surge"))
		var saved_settlement_season_id := StringName(settlement.get("season_id", &""))
		if (
			int(settlement.get("facility_level", 0)) > restored_farmgate_dispatch_level
			or (
				settlement_mandate_id == FarmgateDispatchStateScript.FARMER_PICKUP
				and saved_settlement_season_id not in [&"baseline_neutral", expected_settlement_season_id]
			)
			or (
				settlement_mandate_id != FarmgateDispatchStateScript.FARMER_PICKUP
				and saved_settlement_season_id != expected_settlement_season_id
			)
			or (
				settlement_mandate_id == FarmgateDispatchStateScript.COUNTY_AUCTION
				and int(settlement.get("price_basis_points", 0))
				!= _farmgate_auction_basis_points(expected_settlement_season_id)
			)
		):
			return false
	var restored_capital_records := _validated_capital_records(
		data.get("pinned_capital_plan_id", null),
		data.get("last_facility_purchase_receipt", null),
		data.get("facility_commissioning_history", null),
		saved_day,
		restored_owned_facilities,
	)
	if not bool(restored_capital_records.get("valid", false)):
		return false
	var intake_fields := [
		"intake_rejections_today",
		"intake_rejections_total",
		"intake_missed_value_today_cents",
		"intake_missed_value_total_cents",
	]
	for intake_field in intake_fields:
		if not _is_integral_number(data.get(intake_field, null)):
			return false
	var restored_intake_rejections_today := int(data.get("intake_rejections_today", -1))
	var restored_intake_rejections_total := int(data.get("intake_rejections_total", -1))
	var restored_intake_missed_today := int(data.get("intake_missed_value_today_cents", -1))
	var restored_intake_missed_total := int(data.get("intake_missed_value_total_cents", -1))
	var minimum_claim_value_cents := int((CLAIM_LANE_DEFINITIONS[&"nest_damage"] as Dictionary)["base_value_cents"])
	var maximum_claim_value_cents := int((CLAIM_LANE_DEFINITIONS[&"appeals"] as Dictionary)["base_value_cents"])
	if (
		restored_intake_rejections_today < 0
		or restored_intake_rejections_today > restored_intake_rejections_total
		or restored_intake_rejections_total > 2_000_000_000
		or restored_intake_missed_today < restored_intake_rejections_today * minimum_claim_value_cents
		or restored_intake_missed_today > restored_intake_rejections_today * maximum_claim_value_cents
		or restored_intake_missed_today > restored_intake_missed_total
		or restored_intake_missed_total < restored_intake_rejections_total * minimum_claim_value_cents
		or restored_intake_missed_total > restored_intake_rejections_total * maximum_claim_value_cents
		or restored_intake_missed_total > 2_000_000_000
	):
		return false
	var market_ledger_fields := [
		"market_contracts_signed_total",
		"market_contracts_succeeded_total",
		"market_contracts_breached_total",
		"market_clean_contract_streak",
		"best_market_clean_contract_streak",
		"market_contract_premium_today_cents",
		"market_contract_premium_total_cents",
		"market_contract_breach_today_cents",
		"market_contract_breach_total_cents",
	]
	for market_field in market_ledger_fields:
		if not _is_integral_number(data.get(market_field, null)):
			return false
	var restored_contracts_signed := int(data.get("market_contracts_signed_total", -1))
	var restored_contracts_succeeded := int(data.get("market_contracts_succeeded_total", -1))
	var restored_contracts_breached := int(data.get("market_contracts_breached_total", -1))
	var restored_clean_contract_streak := int(data.get("market_clean_contract_streak", -1))
	var restored_best_clean_contract_streak := int(data.get("best_market_clean_contract_streak", -1))
	var restored_contract_premium_today := int(data.get("market_contract_premium_today_cents", -1))
	var restored_contract_premium_total := int(data.get("market_contract_premium_total_cents", -1))
	var restored_contract_breach_today := int(data.get("market_contract_breach_today_cents", -1))
	var restored_contract_breach_total := int(data.get("market_contract_breach_total_cents", -1))
	if (
		restored_contracts_signed < 0 or restored_contracts_signed > 2_000_000_000
		or restored_contracts_succeeded < 0
		or restored_contracts_breached < 0
		or restored_contracts_succeeded + restored_contracts_breached > restored_contracts_signed
		or restored_clean_contract_streak < 0
		or restored_clean_contract_streak > restored_best_clean_contract_streak
		or restored_best_clean_contract_streak < 0
		or restored_best_clean_contract_streak > restored_contracts_succeeded
		or restored_contract_premium_today < 0
		or restored_contract_premium_today > restored_contract_premium_total
		or restored_contract_premium_total > 2_000_000_000
		or restored_contract_breach_today < 0
		or restored_contract_breach_today > restored_contract_breach_total
		or restored_contract_breach_total > 2_000_000_000
	):
		return false
	if not restored_campus_history.is_empty():
		var campus_access_receipt := restored_campus_history[0] as Dictionary
		if StringName(campus_access_receipt.get("access_gate_id", &"")) == &"farm_mutual_standing":
			var access_standing := int(campus_access_receipt.get("access_standing_points", 0))
			# With authored +2/-1 standing, the smallest possible evidence history
			# for P points is ceil(P/2) successes plus one breach when P is odd.
			# Later settlements may lower standing, so compare against lifetime totals
			# rather than the current derived rank.
			var required_successes: int = ceili(
				float(access_standing) / float(MARKET_STANDING_SUCCESS_POINTS)
			)
			var required_breaches: int = (
				MARKET_STANDING_SUCCESS_POINTS * required_successes - access_standing
			)
			if (
				restored_contracts_succeeded < required_successes
				or restored_contracts_breached < required_breaches
			):
				return false
	var validated_active_contract := _validated_active_market_contract(
		data.get("active_market_contract", null),
		saved_day,
		int(data.get("shift_phase", -1)),
		int(data.get("minute_of_day", -1)),
		restored_service_coop_level,
		restored_negotiation_room_level,
	)
	var validated_last_contract := _validated_market_contract_result(
		data.get("last_market_contract_result", null),
		saved_day,
		restored_service_coop_level,
		restored_negotiation_room_level,
	)
	var validated_contract_decline := _validated_market_contract_decline_receipt(
		data.get("market_contract_decline_receipt", null),
		saved_day,
		int(data.get("shift_phase", -1)),
	)
	if (
		not bool(validated_active_contract.get("valid", false))
		or not bool(validated_last_contract.get("valid", false))
		or not bool(validated_contract_decline.get("valid", false))
	):
		return false
	var restored_active_contract := validated_active_contract.get("record", {}) as Dictionary
	var restored_last_contract := validated_last_contract.get("record", {}) as Dictionary
	var restored_contract_decline := validated_contract_decline.get("record", {}) as Dictionary
	if not restored_active_contract.is_empty() and not restored_contract_decline.is_empty():
		return false
	var settled_contract_total := restored_contracts_succeeded + restored_contracts_breached
	var restored_market_standing := maxi(
		0,
		MARKET_STANDING_SUCCESS_POINTS * restored_contracts_succeeded
		- MARKET_STANDING_BREACH_POINTS * restored_contracts_breached,
	)
	if (
		(settled_contract_total == 0 and not restored_last_contract.is_empty())
		or (settled_contract_total > 0 and restored_last_contract.is_empty())
		or (
			not restored_last_contract.is_empty()
			and bool(restored_last_contract.get("success", false))
			and restored_contracts_succeeded <= 0
		)
		or (
			not restored_last_contract.is_empty()
			and not bool(restored_last_contract.get("success", false))
			and restored_contracts_breached <= 0
		)
		or (
			not restored_last_contract.is_empty()
			and bool(restored_last_contract.get("success", false))
			and restored_clean_contract_streak <= 0
		)
		or (
			not restored_last_contract.is_empty()
			and not bool(restored_last_contract.get("success", false))
			and restored_clean_contract_streak != 0
		)
	):
		return false
	if not restored_last_contract.is_empty():
		var last_success := bool(restored_last_contract.get("success", false))
		var standing_before_last := (
			maxi(
				0,
				MARKET_STANDING_SUCCESS_POINTS * maxi(0, restored_contracts_succeeded - 1)
				- MARKET_STANDING_BREACH_POINTS * restored_contracts_breached,
			)
			if last_success else
			maxi(
				0,
				MARKET_STANDING_SUCCESS_POINTS * restored_contracts_succeeded
				- MARKET_STANDING_BREACH_POINTS * maxi(0, restored_contracts_breached - 1),
			)
		)
		var expected_rank: StringName = &"unlisted"
		if restored_market_standing >= 12:
			expected_rank = &"gold"
		elif restored_market_standing >= 6:
			expected_rank = &"silver"
		elif restored_market_standing >= 2:
			expected_rank = &"bronze"
		if (
			int(restored_last_contract.get("market_standing_before", -1)) != standing_before_last
			or int(restored_last_contract.get("market_standing_after", -1)) != restored_market_standing
			or int(restored_last_contract.get("market_standing_delta", 0))
			!= restored_market_standing - standing_before_last
			or StringName(restored_last_contract.get("market_standing_rank", &"")) != expected_rank
			or int(restored_last_contract.get("clean_contract_streak_after", -1))
			!= restored_clean_contract_streak
			or int(restored_last_contract.get("best_clean_contract_streak", -1))
			!= restored_best_clean_contract_streak
			or (
				last_success
				and int(restored_last_contract.get("clean_contract_streak_before", -1))
				!= restored_clean_contract_streak - 1
			)
		):
			return false
	if restored_contract_premium_today > 0 and (
		restored_last_contract.is_empty()
		or int(restored_last_contract.get("day", 0)) != saved_day
		or restored_contract_premium_today != int(restored_last_contract.get("premium_cents", 0))
	):
		return false
	if restored_contract_breach_today > 0 and (
		restored_last_contract.is_empty()
		or int(restored_last_contract.get("day", 0)) != saved_day
		or restored_contract_breach_today != int(restored_last_contract.get("breach_cents", 0))
	):
		return false
	var expected_signed_total := (
		restored_contracts_succeeded
		+ restored_contracts_breached
		+ (0 if restored_active_contract.is_empty() else 1)
	)
	if restored_contracts_signed != expected_signed_total:
		return false
	if (
		not restored_active_contract.is_empty()
		and _claim_capacity_for_facilities_and_campus(
			restored_owned_facilities,
			restored_campus_expansion,
			restored_campus_portfolio.claim_capacity_bonus(restored_portfolio_context),
		)
		< int(restored_active_contract.get("required_claim_capacity", 0))
	):
		return false
	var packing_fields := [
		"packing_carton_progress",
		"packing_cartons_today",
		"packing_cartons_total",
		"packing_value_bonus_today_cents",
		"packing_value_bonus_total_cents",
		"packing_carton_bonus_today_cents",
		"packing_carton_bonus_total_cents",
	]
	for packing_field in packing_fields:
		if not _is_integral_number(data.get(packing_field, null)):
			return false
	var restored_packing_progress := int(data.get("packing_carton_progress", -1))
	var restored_packing_cartons_today := int(data.get("packing_cartons_today", -1))
	var restored_packing_cartons_total := int(data.get("packing_cartons_total", -1))
	var restored_packing_value_today := int(data.get("packing_value_bonus_today_cents", -1))
	var restored_packing_value_total := int(data.get("packing_value_bonus_total_cents", -1))
	var restored_packing_carton_bonus_today := int(data.get("packing_carton_bonus_today_cents", -1))
	var restored_packing_carton_bonus_total := int(data.get("packing_carton_bonus_total_cents", -1))
	if (
		restored_packing_progress < 0
		or restored_packing_progress >= PACKING_CARTON_SIZE
		or restored_packing_cartons_today < 0
		or restored_packing_cartons_today > restored_packing_cartons_total
		or restored_packing_cartons_total > 2_000_000_000
		or restored_packing_value_today < 0
		or restored_packing_value_today > restored_packing_value_total
		or restored_packing_value_total > 2_000_000_000
		or restored_packing_carton_bonus_today < 0
		or restored_packing_carton_bonus_today > restored_packing_carton_bonus_total
		or restored_packing_carton_bonus_total > 2_000_000_000
		or restored_packing_carton_bonus_today % PACKING_CARTON_BONUS_PER_LEVEL_CENTS != 0
		or restored_packing_carton_bonus_total % PACKING_CARTON_BONUS_PER_LEVEL_CENTS != 0
	):
		return false
	if (
		int(restored_owned_facilities.get(PACKING_ANNEX_ID, 0)) <= 0
		and (
			restored_packing_progress != 0
			or restored_packing_cartons_today != 0
			or restored_packing_cartons_total != 0
			or restored_packing_value_today != 0
			or restored_packing_value_total != 0
			or restored_packing_carton_bonus_today != 0
			or restored_packing_carton_bonus_total != 0
		)
	):
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
	var personnel_actions_by_day: Dictionary[int, int] = {}
	var seen_personnel_action_serials: Dictionary[int, bool] = {}
	var restored_personnel_action_limit := _facility_level_schedule_value(
		ROOSTER_PERSONNEL_ACTION_LIMITS,
		restored_rooster_operations_level,
		1,
	)
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
			"employment_start_day", "last_personnel_action_day",
			"last_personnel_action_serial",
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
		var saved_action_serial := int(saved_worker.get("last_personnel_action_serial", -1))
		for specialty_field in ["secondary_specialty", "cross_training_target"]:
			if typeof(saved_worker.get(specialty_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return false
		if typeof(saved_worker.get("cross_training_worked_this_shift", null)) != TYPE_BOOL:
			return false
		if not ChickenState.is_valid_personnel_action(saved_action):
			return false
		if (
			(saved_action == &"") != (saved_action_day == 0)
			or (saved_action == &"") != (saved_action_serial == 0)
			or saved_action_serial < 0
		):
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
			if seen_personnel_action_serials.has(restored.last_personnel_action_serial):
				return false
			seen_personnel_action_serials[restored.last_personnel_action_serial] = true
			if (
				restored.last_personnel_action_day == saved_day
				and (
					not restored.employed
					or saved_shift_phase not in [
						ShiftPhase.RUNNING,
						ShiftPhase.AWAITING_INCIDENT,
					]
				)
			):
				return false
			var actions_on_day := int(personnel_actions_by_day.get(
				restored.last_personnel_action_day,
				0,
			)) + 1
			if actions_on_day > restored_personnel_action_limit:
				return false
			personnel_actions_by_day[restored.last_personnel_action_day] = actions_on_day
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
	for module_id: StringName in CampusPortfolioStateScript.MODULE_ORDER:
		var restored_module_value: Variant = restored_campus_portfolio.modules.get(
			String(module_id),
			{},
		)
		if not restored_module_value is Dictionary:
			return false
		var assigned_worker_id := int((restored_module_value as Dictionary).get("worker_id", -1))
		if assigned_worker_id >= 0 and (
			assigned_worker_id >= restored_workers.size()
			or not restored_workers[assigned_worker_id].employed
		):
			return false
	var farmgate_worker_lots: Array[Dictionary] = restored_farmgate_dispatch.lots.duplicate(true)
	for settlement_value in restored_farmgate_dispatch.history:
		var settlement := settlement_value as Dictionary
		for lot_value in settlement.get("sold_lots", []) as Array:
			farmgate_worker_lots.append(lot_value as Dictionary)
		for lot_value in settlement.get("expired_lots", []) as Array:
			farmgate_worker_lots.append(lot_value as Dictionary)
	for lot in farmgate_worker_lots:
		var farmgate_worker_id := int(lot.get("worker_id", -1))
		if (
			farmgate_worker_id < 0 or farmgate_worker_id >= restored_workers.size()
			or String(lot.get("worker_name", "")) != restored_workers[farmgate_worker_id].display_name
		):
			return false
	var validated_flock_relations := _validated_flock_relations_state(
		data,
		saved_day,
		restored_flock_relations_level,
		restored_workers,
	)
	if not bool(validated_flock_relations.get("valid", false)):
		return false
	var restored_flock_relations_cases := (
		validated_flock_relations.get("open_cases", []) as Array[Dictionary]
	)
	var restored_flock_relations_resolutions_used := int(
		validated_flock_relations.get("resolutions_used_today", 0)
	)
	var restored_flock_relations_resolved_total := int(
		validated_flock_relations.get("resolved_total", 0)
	)
	var restored_flock_relations_denied_total := int(
		validated_flock_relations.get("denied_total", 0)
	)
	var restored_flock_relations_spend_total := int(
		validated_flock_relations.get("settlement_spend_total_cents", 0)
	)
	var restored_last_flock_relations_resolution := (
		validated_flock_relations.get("last_resolution", {}) as Dictionary
	)
	var restored_flock_relations_history := (
		validated_flock_relations.get("history", []) as Array[Dictionary]
	)
	var restored_next_flock_relations_case_id := int(
		validated_flock_relations.get("next_case_id", 1)
	)
	if (
		not restored_active_contract.is_empty()
		and int(restored_active_contract.get("required_active_staff", 0)) > restored_active_count
	):
		return false
	var pending_value: Variant = data.get("pending_decision", {})
	if not pending_value is Dictionary or not _is_valid_pending_flock_petition(pending_value, saved_day):
		return false
	var pending_source := pending_value as Dictionary
	var pending_incident_id := StringName(String(pending_source.get("id", "")))
	if (
		pending_incident_id in INCIDENT_ORDER
		and restored_last_standard_incident_id != pending_incident_id
	):
		return false
	var active_directive_value: Variant = data.get("active_directive_id", "")
	if typeof(active_directive_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return false
	var restored_active_directive := StringName(String(active_directive_value))
	if not _is_valid_shift_decision_tuple(
		saved_shift_phase,
		restored_active_directive,
		pending_source,
	):
		return false
	var harvest_status: StringName = StringName(restored_harvest_credit.review_status)
	var pending_kind := StringName(pending_source.get("kind", &""))
	if (
		(harvest_status == HarvestCreditStateScript.STATUS_PRE_CREDIT and (
			saved_shift_phase != ShiftPhase.REVIEW
			or pending_kind not in [&"credit_allocation", &"major_event"]
		))
		or (harvest_status == HarvestCreditStateScript.STATUS_OFFER_OPEN and (
			saved_shift_phase != ShiftPhase.REVIEW or not pending_source.is_empty()
		))
	):
		return false
	var harvest_evidence: Dictionary = (
		restored_harvest_credit.frozen_evidence as Dictionary
	)
	if not harvest_evidence.is_empty() and int(harvest_evidence.get("day", 0)) == restored_order_day:
		if restored_order.is_empty():
			return false
		var restored_top := restored_order[0]
		if (
			int(harvest_evidence.get("top_worker_id", -1)) != int(restored_top.get("worker_id", -1))
			or String(harvest_evidence.get("top_worker_name", "")) != String(restored_top.get("worker_name", ""))
		):
			return false
	if (
		saved_shift_phase == ShiftPhase.REVIEW
		and (not restored_active_contract.is_empty() or not restored_contract_decline.is_empty())
		and not pending_source.is_empty()
	):
		return false
	if StringName(pending_source.get("id", &"")) == FLOCK_PETITION_INCIDENT_ID:
		var pending_sponsor_id := int(pending_source.get("sponsor_worker_id", -1))
		if (
			saved_shift_phase != ShiftPhase.AWAITING_INCIDENT
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
	var restored_pending_contract_claims := 0
	if not restored_active_contract.is_empty():
		var contract_claim_ids := restored_active_contract.get("claim_ids", []) as Array
		var accepted_contract_ids := restored_active_contract.get("accepted_claim_ids", []) as Array
		var completed_contract_ids := restored_active_contract.get("completed_claim_ids", []) as Array
		var rejected_contract_ids := restored_active_contract.get("rejected_claim_ids", []) as Array
		for contract_claim_id_value in contract_claim_ids:
			var contract_claim_id := int(contract_claim_id_value)
			if contract_claim_id in accepted_contract_ids:
				if (
					(contract_claim_id in completed_contract_ids and seen_claim_ids.has(contract_claim_id))
					or (contract_claim_id not in completed_contract_ids and not seen_claim_ids.has(contract_claim_id))
				):
					return false
			elif contract_claim_id in rejected_contract_ids:
				if seen_claim_ids.has(contract_claim_id):
					return false
			else:
				if seen_claim_ids.has(contract_claim_id):
					return false
				restored_pending_contract_claims += 1
	if (
		outstanding_count + restored_pending_contract_claims
		> _claim_capacity_for_facilities_and_campus(
			restored_owned_facilities,
			restored_campus_expansion,
			restored_campus_portfolio.claim_capacity_bonus(restored_portfolio_context),
		)
	):
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
	upgrade_levels = restored_upgrade_levels
	first_clutch_reinvestment = restored_first_clutch_reinvestment
	requisition_spend_today_cents = restored_requisition_spend_today
	requisition_spend_total_cents = restored_requisition_spend_total
	orientation_procurement_match_today_cents = restored_orientation_match_today
	orientation_procurement_match_total_cents = restored_orientation_match_total
	owned_facilities = restored_owned_facilities
	manager_roster = restored_manager_roster
	last_manager_action = restored_last_manager_action
	management_reports_today = restored_reports_today
	management_reports_total = restored_reports_total
	management_visibility_today = restored_visibility_today
	_feed_procurement = restored_feed_procurement
	_harvest_credit = restored_harvest_credit
	_farmgate_dispatch = restored_farmgate_dispatch
	_farm_treasury = restored_farm_treasury
	campus_expansion_state = restored_campus_expansion
	_campus_portfolio = restored_campus_portfolio
	pinned_capital_plan_id = StringName(restored_capital_records.get("pinned_id", &""))
	last_facility_purchase_receipt = (
		restored_capital_records.get("last", {}) as Dictionary
	).duplicate(true)
	facility_commissioning_history = (
		restored_capital_records.get("history", []) as Array[Dictionary]
	).duplicate(true)
	packing_carton_progress = restored_packing_progress
	packing_cartons_today = restored_packing_cartons_today
	packing_cartons_total = restored_packing_cartons_total
	packing_value_bonus_today_cents = restored_packing_value_today
	packing_value_bonus_total_cents = restored_packing_value_total
	packing_carton_bonus_today_cents = restored_packing_carton_bonus_today
	packing_carton_bonus_total_cents = restored_packing_carton_bonus_total
	intake_rejections_today = restored_intake_rejections_today
	intake_rejections_total = restored_intake_rejections_total
	intake_missed_value_today_cents = restored_intake_missed_today
	intake_missed_value_total_cents = restored_intake_missed_total
	active_market_contract = restored_active_contract
	market_contract_decline_receipt = restored_contract_decline
	last_market_contract_result = restored_last_contract
	market_contracts_signed_total = restored_contracts_signed
	market_contracts_succeeded_total = restored_contracts_succeeded
	market_contracts_breached_total = restored_contracts_breached
	market_clean_contract_streak = restored_clean_contract_streak
	best_market_clean_contract_streak = restored_best_clean_contract_streak
	market_contract_premium_today_cents = restored_contract_premium_today
	market_contract_premium_total_cents = restored_contract_premium_total
	market_contract_breach_today_cents = restored_contract_breach_today
	market_contract_breach_total_cents = restored_contract_breach_total
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
	flock_relations_open_cases = restored_flock_relations_cases
	flock_relations_resolutions_used_today = restored_flock_relations_resolutions_used
	flock_relations_resolved_total = restored_flock_relations_resolved_total
	flock_relations_denied_total = restored_flock_relations_denied_total
	flock_relations_settlement_spend_total_cents = restored_flock_relations_spend_total
	last_flock_relations_resolution = restored_last_flock_relations_resolution
	flock_relations_resolution_history = restored_flock_relations_history
	next_flock_relations_case_id = restored_next_flock_relations_case_id
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
	shift_phase = saved_shift_phase
	active_directive_id = restored_active_directive
	pending_decision = _decision_from_save_data(data.get("pending_decision", {}) as Dictionary)
	incidents_resolved_today = clampi(int(data.get("incidents_resolved_today", 0)), 0, INCIDENT_MINUTES.size())

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
	_career_seed = restored_career_seed
	_incident_rng.state = String(incident_rng_value).to_int()
	_incident_bag.assign(restored_incident_bag)
	_last_standard_incident_id = restored_last_standard_incident_id
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
	var original_source_version := source_version
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
			7:
				# Capital facilities begin unowned. The v7 economy therefore migrates
				# without inventing a purchase, maintenance liability, or quality edge.
				migrated["owned_facilities"] = {
					"candling_rework_bay": 0,
				}
				source_version = 8
				migrated["state_version"] = source_version
			8:
				# The first true building expansion arrives neutral for every v8 file.
				# Validate the formerly strict single-entry ledger before extending it;
				# migration must never launder an unknown facility or invent output.
				var legacy_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not legacy_facilities_value is Dictionary:
					return {}
				var legacy_facilities := legacy_facilities_value as Dictionary
				if legacy_facilities.size() != 1:
					return {}
				var legacy_candling_value: Variant = legacy_facilities.get(
					"candling_rework_bay",
					legacy_facilities.get(&"candling_rework_bay", null),
				)
				if (
					not _is_integral_number(legacy_candling_value)
					or int(legacy_candling_value) < 0
					or int(legacy_candling_value) > 1
				):
					return {}
				var migrated_facilities := {
					"candling_rework_bay": int(legacy_candling_value),
				}
				migrated_facilities[String(PACKING_ANNEX_ID)] = 0
				migrated["owned_facilities"] = migrated_facilities
				migrated["packing_carton_progress"] = 0
				migrated["packing_cartons_today"] = 0
				migrated["packing_cartons_total"] = 0
				migrated["packing_value_bonus_today_cents"] = 0
				migrated["packing_value_bonus_total_cents"] = 0
				migrated["packing_carton_bonus_today_cents"] = 0
				migrated["packing_carton_bonus_total_cents"] = 0
				source_version = 9
				migrated["state_version"] = source_version
			9:
				# First Clutch reinvestment is never inferred for an older campaign.
				# Historical upgrade spend is reconstructable from the immutable level
				# schedule, while today's attribution remains neutral because v9 did not
				# record which shift bought each level.
				var migrated_upgrade_levels := _validated_upgrade_levels(
					migrated.get("upgrade_levels", null),
				)
				if migrated_upgrade_levels.size() != UPGRADE_ORDER.size():
					return {}
				migrated["first_clutch_reinvestment"] = {}
				migrated["requisition_spend_today_cents"] = 0
				migrated["requisition_spend_total_cents"] = _cumulative_upgrade_spend_cents(
					migrated_upgrade_levels,
				)
				migrated["orientation_procurement_match_today_cents"] = 0
				migrated["orientation_procurement_match_total_cents"] = 0
				source_version = 10
				migrated["state_version"] = source_version
			10:
				# The Records Annex begins unowned and intake history begins neutral.
				# Validate the exact v10 two-facility ledger before extending it so
				# migration cannot launder an unknown building or invented capacity.
				var v10_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v10_facilities_value is Dictionary:
					return {}
				var v10_facilities := v10_facilities_value as Dictionary
				if v10_facilities.size() != 2:
					return {}
				var v10_candling_value: Variant = v10_facilities.get(
					"candling_rework_bay",
					v10_facilities.get(&"candling_rework_bay", null),
				)
				var v10_packing_value: Variant = v10_facilities.get(
					String(PACKING_ANNEX_ID),
					v10_facilities.get(PACKING_ANNEX_ID, null),
				)
				if (
					not _is_integral_number(v10_candling_value)
					or int(v10_candling_value) < 0
					or int(v10_candling_value) > 1
					or not _is_integral_number(v10_packing_value)
					or int(v10_packing_value) < 0
					or int(v10_packing_value) > 3
				):
					return {}
				var v11_facilities := {
					"candling_rework_bay": int(v10_candling_value),
				}
				v11_facilities[String(PACKING_ANNEX_ID)] = int(v10_packing_value)
				v11_facilities[String(RECORDS_ANNEX_ID)] = 0
				migrated["owned_facilities"] = v11_facilities
				migrated["intake_rejections_today"] = 0
				migrated["intake_rejections_total"] = 0
				migrated["intake_missed_value_today_cents"] = 0
				migrated["intake_missed_value_total_cents"] = 0
				source_version = 11
				migrated["state_version"] = source_version
			11:
				# Farm Mutual did not exist in v11. Preserve every historical file and
				# cent while adding a neutral market ledger; migration must never infer
				# a signature, a premium, or a breach from ordinary lane throughput.
				migrated["active_market_contract"] = {}
				migrated["market_contract_decline_receipt"] = {}
				migrated["last_market_contract_result"] = {}
				migrated["market_contracts_signed_total"] = 0
				migrated["market_contracts_succeeded_total"] = 0
				migrated["market_contracts_breached_total"] = 0
				migrated["market_contract_premium_today_cents"] = 0
				migrated["market_contract_premium_total_cents"] = 0
				migrated["market_contract_breach_today_cents"] = 0
				migrated["market_contract_breach_total_cents"] = 0
				source_version = 12
				migrated["state_version"] = source_version
			12:
				# Service Coop begins unowned. Standing is derived from the exact v12
				# success/breach totals, so genuine history is grandfathered without
				# minting a second balance. In-flight v12 binders retain level-zero
				# premiums and their formerly legal staffing commitment.
				var v12_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v12_facilities_value is Dictionary:
					return {}
				var v12_facilities := v12_facilities_value as Dictionary
				if v12_facilities.size() != 3:
					return {}
				var v13_facilities: Dictionary = {}
				for legacy_facility_id in [
					&"candling_rework_bay",
					PACKING_ANNEX_ID,
					RECORDS_ANNEX_ID,
				]:
					var legacy_level_value: Variant = v12_facilities.get(
						String(legacy_facility_id),
						v12_facilities.get(legacy_facility_id, null),
					)
					if not _is_integral_number(legacy_level_value):
						return {}
					var legacy_max := int((FACILITY_DEFINITIONS[legacy_facility_id] as Dictionary).get("max_level", 1))
					var legacy_level := int(legacy_level_value)
					if legacy_level < 0 or legacy_level > legacy_max:
						return {}
					v13_facilities[String(legacy_facility_id)] = legacy_level
				v13_facilities[String(FARM_MUTUAL_SERVICE_COOP_ID)] = 0
				migrated["owned_facilities"] = v13_facilities

				var migrated_active_value: Variant = migrated.get("active_market_contract", {})
				if not migrated_active_value is Dictionary:
					return {}
				var migrated_active := (migrated_active_value as Dictionary).duplicate(true)
				if not migrated_active.is_empty():
					var active_offer_id := StringName(migrated_active.get("offer_id", &""))
					if not MARKET_CONTRACT_DEFINITIONS.has(active_offer_id):
						return {}
					var active_definition := MARKET_CONTRACT_DEFINITIONS[active_offer_id] as Dictionary
					migrated_active["required_active_staff"] = 0
					migrated_active["legacy_staffing_grandfathered"] = true
					migrated_active["base_premium_cents"] = int(active_definition.get("premium_cents", 0))
					migrated_active["service_coop_level_at_signing"] = 0
					migrated_active["service_coop_bonus_cents"] = 0
					migrated_active["premium_bonus_basis_points"] = 0
				migrated["active_market_contract"] = migrated_active

				var migrated_last_value: Variant = migrated.get("last_market_contract_result", {})
				if not migrated_last_value is Dictionary:
					return {}
				var migrated_last := (migrated_last_value as Dictionary).duplicate(true)
				var seeded_streak := 0
				if not migrated_last.is_empty():
					var last_offer_id := StringName(migrated_last.get("offer_id", &""))
					if not MARKET_CONTRACT_DEFINITIONS.has(last_offer_id):
						return {}
					var last_definition := MARKET_CONTRACT_DEFINITIONS[last_offer_id] as Dictionary
					var last_success := bool(migrated_last.get("success", false))
					seeded_streak = 1 if last_success else 0
					var succeeded_total := maxi(0, int(migrated.get("market_contracts_succeeded_total", 0)))
					var breached_total := maxi(0, int(migrated.get("market_contracts_breached_total", 0)))
					var standing_after := maxi(0, 2 * succeeded_total - breached_total)
					var standing_before := (
						maxi(0, 2 * maxi(0, succeeded_total - 1) - breached_total)
						if last_success else
						maxi(0, 2 * succeeded_total - maxi(0, breached_total - 1))
					)
					migrated_last["required_active_staff"] = 0
					migrated_last["base_premium_cents"] = int(last_definition.get("premium_cents", 0))
					migrated_last["service_coop_level_at_signing"] = 0
					migrated_last["service_coop_bonus_cents"] = 0
					migrated_last["contracted_service_coop_bonus_cents"] = 0
					migrated_last["premium_bonus_basis_points"] = 0
					migrated_last["market_standing_before"] = standing_before
					migrated_last["market_standing_after"] = standing_after
					migrated_last["market_standing_delta"] = standing_after - standing_before
					migrated_last["market_standing_rank"] = String(
						&"gold" if standing_after >= 12 else
						(&"silver" if standing_after >= 6 else (&"bronze" if standing_after >= 2 else &"unlisted"))
					)
					migrated_last["clean_contract_streak_before"] = 0
					migrated_last["clean_contract_streak_after"] = seeded_streak
					migrated_last["best_clean_contract_streak"] = seeded_streak
				migrated["last_market_contract_result"] = migrated_last
				migrated["market_clean_contract_streak"] = seeded_streak
				migrated["best_market_clean_contract_streak"] = seeded_streak
				source_version = 13
				migrated["state_version"] = source_version
			13:
				# Seasonal pricing and negotiation begin neutral for every v13 file.
				# Existing signed and settled terms are grandfathered byte-for-byte in
				# money and operations; no historical day is repriced into a season.
				var v13_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v13_facilities_value is Dictionary:
					return {}
				var v13_facilities := v13_facilities_value as Dictionary
				if v13_facilities.size() != 4:
					return {}
				var v14_facilities: Dictionary = {}
				for legacy_facility_id in [
					&"candling_rework_bay",
					PACKING_ANNEX_ID,
					RECORDS_ANNEX_ID,
					FARM_MUTUAL_SERVICE_COOP_ID,
				]:
					var legacy_level_value: Variant = v13_facilities.get(
						String(legacy_facility_id),
						v13_facilities.get(legacy_facility_id, null),
					)
					if not _is_integral_number(legacy_level_value):
						return {}
					var legacy_level := int(legacy_level_value)
					var legacy_max := int(
						(FACILITY_DEFINITIONS[legacy_facility_id] as Dictionary).get("max_level", 1)
					)
					if legacy_level < 0 or legacy_level > legacy_max:
						return {}
					v14_facilities[String(legacy_facility_id)] = legacy_level
				v14_facilities[String(FARM_MUTUAL_NEGOTIATION_ROOM_ID)] = 0
				migrated["owned_facilities"] = v14_facilities

				var v13_active_value: Variant = migrated.get("active_market_contract", {})
				if not v13_active_value is Dictionary:
					return {}
				migrated["active_market_contract"] = _migrated_v14_active_market_contract(
					v13_active_value as Dictionary
				)
				if (
					not (v13_active_value as Dictionary).is_empty()
					and (migrated["active_market_contract"] as Dictionary).is_empty()
				):
					return {}

				var v13_result_value: Variant = migrated.get("last_market_contract_result", {})
				if not v13_result_value is Dictionary:
					return {}
				migrated["last_market_contract_result"] = _migrated_v14_market_contract_result(
					v13_result_value as Dictionary
				)
				if (
					not (v13_result_value as Dictionary).is_empty()
					and (migrated["last_market_contract_result"] as Dictionary).is_empty()
				):
					return {}
				source_version = 14
				migrated["state_version"] = source_version
			14:
				# v15 adds two neutral cumulative facilities. Validate the exact v14
				# five-key primitive ledger before appending zero levels; every other
				# simulation, worker, contract, quota, and RNG field remains untouched.
				var v14_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v14_facilities_value is Dictionary:
					return {}
				var v14_facilities := v14_facilities_value as Dictionary
				if v14_facilities.size() != V14_FACILITY_ORDER.size():
					return {}
				var seen_v14_facilities: Dictionary = {}
				var v15_facilities: Dictionary = {}
				for raw_facility_id in v14_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in V14_FACILITY_ORDER or seen_v14_facilities.has(facility_id):
						return {}
					var level_value: Variant = v14_facilities[raw_facility_id]
					if not _is_integral_number(level_value):
						return {}
					var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v14_facilities[facility_id] = true
					v15_facilities[String(facility_id)] = level
				if seen_v14_facilities.size() != V14_FACILITY_ORDER.size():
					return {}
				v15_facilities[String(WELLNESS_NEST_ID)] = 0
				v15_facilities[String(TRAINING_ROOST_ID)] = 0
				migrated["owned_facilities"] = v15_facilities
				source_version = 15
				migrated["state_version"] = source_version
			15:
				# v16 adds two neutral cumulative operations facilities. Validate the
				# exact seven-key v15 primitive ledger before appending zero levels;
				# no historical supervision, automation, pressure, or payroll is inferred.
				var v15_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v15_facilities_value is Dictionary:
					return {}
				var v15_facilities := v15_facilities_value as Dictionary
				if v15_facilities.size() != V15_FACILITY_ORDER.size():
					return {}
				var seen_v15_facilities: Dictionary = {}
				var v16_facilities: Dictionary = {}
				for raw_facility_id in v15_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in V15_FACILITY_ORDER or seen_v15_facilities.has(facility_id):
						return {}
					var level_value: Variant = v15_facilities[raw_facility_id]
					if not _is_integral_number(level_value):
						return {}
					var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v15_facilities[facility_id] = true
					v16_facilities[String(facility_id)] = level
				if seen_v15_facilities.size() != V15_FACILITY_ORDER.size():
					return {}
				v16_facilities[String(ROOSTER_OPERATIONS_OFFICE_ID)] = 0
				v16_facilities[String(IT_COOP_ID)] = 0
				migrated["owned_facilities"] = v16_facilities
				var v15_workers_value: Variant = migrated.get("workers", null)
				if not v15_workers_value is Array:
					return {}
				var v15_workers := v15_workers_value as Array
				var migrated_action_serial := 1
				for worker_value in v15_workers:
					if not worker_value is Dictionary:
						return {}
					var worker_record := worker_value as Dictionary
					var action_id := StringName(String(worker_record.get("last_personnel_action", "")))
					worker_record["last_personnel_action_serial"] = (
						migrated_action_serial if action_id != &"" else 0
					)
					if action_id != &"":
						migrated_action_serial += 1
				migrated["workers"] = v15_workers
				source_version = 16
				migrated["state_version"] = source_version
			16:
				# v17 adds one neutral Flock Relations facility and its case ledger. Validate
				# the exact nine-key v16 primitive facility map before extending it so an
				# older checkpoint cannot launder an unknown building or invented casework.
				var v16_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v16_facilities_value is Dictionary:
					return {}
				var v16_facilities := v16_facilities_value as Dictionary
				if v16_facilities.size() != V16_FACILITY_ORDER.size():
					return {}
				var seen_v16_facilities: Dictionary = {}
				var v17_facilities: Dictionary = {}
				for raw_facility_id in v16_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in V16_FACILITY_ORDER or seen_v16_facilities.has(facility_id):
						return {}
					var level_value: Variant = v16_facilities[raw_facility_id]
					if not _is_integral_number(level_value):
						return {}
					var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v16_facilities[facility_id] = true
					v17_facilities[String(facility_id)] = level
				if seen_v16_facilities.size() != V16_FACILITY_ORDER.size():
					return {}
				v17_facilities[String(FLOCK_RELATIONS_OFFICE_ID)] = 0
				migrated["owned_facilities"] = v17_facilities
				migrated["flock_relations_open_cases"] = []
				migrated["flock_relations_resolutions_used_today"] = 0
				migrated["flock_relations_resolved_total"] = 0
				migrated["flock_relations_denied_total"] = 0
				migrated["flock_relations_settlement_spend_total_cents"] = 0
				migrated["last_flock_relations_resolution"] = {}
				migrated["flock_relations_resolution_history"] = []
				migrated["next_flock_relations_case_id"] = 1
				source_version = 17
				migrated["state_version"] = source_version
			17:
				# v18 adds the Flock Provisions Co-op and a neutral FIFO ledger. Validate
				# the exact ten-key v17 facility map before appending the unowned tier;
				# historical saves invent no grain, procurement spend, or spoilage.
				var v17_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v17_facilities_value is Dictionary:
					return {}
				var v17_facilities := v17_facilities_value as Dictionary
				if v17_facilities.size() != V17_FACILITY_ORDER.size():
					return {}
				var seen_v17_facilities: Dictionary = {}
				var v18_facilities: Dictionary = {}
				for raw_facility_id in v17_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in V17_FACILITY_ORDER or seen_v17_facilities.has(facility_id):
						return {}
					var level_value: Variant = v17_facilities[raw_facility_id]
					if not _is_integral_number(level_value):
						return {}
					var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v17_facilities[facility_id] = true
					v18_facilities[String(facility_id)] = level
				if seen_v17_facilities.size() != V17_FACILITY_ORDER.size():
					return {}
				v18_facilities[String(FEED_PROCUREMENT_COOP_ID)] = 0
				migrated["owned_facilities"] = v18_facilities
				migrated["feed_procurement_state"] = FeedProcurementStateScript.neutral_save_data(
					clampi(int(migrated.get("day", 1)), 1, 9999)
				)
				source_version = 18
				migrated["state_version"] = source_version
			18:
				# v19 appends the Harvest Credit Gallery and a neutral publicity ledger.
				# Validate the exact eleven-key v18 facility map before extending it;
				# migration invents no campaign, standing, payout, or attribution history.
				var v18_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v18_facilities_value is Dictionary:
					return {}
				var v18_facilities := v18_facilities_value as Dictionary
				if v18_facilities.size() != V18_FACILITY_ORDER.size():
					return {}
				var seen_v18_facilities: Dictionary = {}
				var v19_facilities: Dictionary = {}
				for raw_facility_id in v18_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in V18_FACILITY_ORDER or seen_v18_facilities.has(facility_id):
						return {}
					var level_value: Variant = v18_facilities[raw_facility_id]
					if not _is_integral_number(level_value):
						return {}
					var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v18_facilities[facility_id] = true
					v19_facilities[String(facility_id)] = level
				if seen_v18_facilities.size() != V18_FACILITY_ORDER.size():
					return {}
				v19_facilities[String(FARMER_RELATIONS_GALLERY_ID)] = 0
				migrated["owned_facilities"] = v19_facilities
				migrated["harvest_credit_state"] = HarvestCreditStateScript.neutral_save_data()
				source_version = 19
				migrated["state_version"] = source_version
			19:
				# v20 appends the Farmgate Dispatch Depot and neutral inventory, mandate,
				# settlement, capital-plan, and commissioning ledgers. No prior egg cash
				# is reclassified, so a v19 checkpoint preserves its exact fund balance.
				var v19_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v19_facilities_value is Dictionary or not _is_integral_number(migrated.get("day", null)):
					return {}
				var v19_facilities := v19_facilities_value as Dictionary
				if v19_facilities.size() != V19_FACILITY_ORDER.size():
					return {}
				var seen_v19_facilities: Dictionary = {}
				var v20_facilities: Dictionary = {}
				for raw_facility_id in v19_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in V19_FACILITY_ORDER or seen_v19_facilities.has(facility_id):
						return {}
					var level_value: Variant = v19_facilities[raw_facility_id]
					if not _is_integral_number(level_value):
						return {}
					var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v19_facilities[facility_id] = true
					v20_facilities[String(facility_id)] = level
				if seen_v19_facilities.size() != V19_FACILITY_ORDER.size():
					return {}
				v20_facilities[String(FARMGATE_DISPATCH_DEPOT_ID)] = 0
				migrated["owned_facilities"] = v20_facilities
				migrated["farmgate_dispatch_state"] = FarmgateDispatchStateScript.neutral_save_data(
					int(migrated["day"])
				)
				migrated["pinned_capital_plan_id"] = ""
				migrated["last_facility_purchase_receipt"] = {}
				migrated["facility_commissioning_history"] = []
				source_version = 20
				migrated["state_version"] = source_version
			20:
				# v21 adds the North Meadow parcel, service, placement, and receipt
				# ledger. The facility catalog is unchanged. A v20 checkpoint may not
				# smuggle invented campus ownership through the neutral migration.
				if migrated.has("campus_expansion"):
					# A checkpoint that identifies itself as v20 must not smuggle
					# v21 ownership. Older migration fixtures historically retain
					# later-schema fields while walking multiple pure migrations, so
					# discard that unknown field and still create the exact neutral v21
					# ledger when the original source genuinely predates v20.
					if original_source_version == 20:
						return {}
					migrated.erase("campus_expansion")
				var v20_facilities_value: Variant = migrated.get("owned_facilities", null)
				if not v20_facilities_value is Dictionary:
					return {}
				var v20_facilities := v20_facilities_value as Dictionary
				if v20_facilities.size() != V20_FACILITY_ORDER.size():
					return {}
				var seen_v20_facilities: Dictionary = {}
				for raw_facility_id in v20_facilities:
					var facility_id := StringName(String(raw_facility_id))
					if facility_id not in V20_FACILITY_ORDER or seen_v20_facilities.has(facility_id):
						return {}
					var level_value: Variant = v20_facilities[raw_facility_id]
					if not _is_integral_number(level_value):
						return {}
					var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
					var level := int(level_value)
					if level < 0 or level > int(definition.get("max_level", 1)):
						return {}
					seen_v20_facilities[facility_id] = true
				if seen_v20_facilities.size() != V20_FACILITY_ORDER.size():
					return {}
				migrated["campus_expansion"] = _neutral_campus_expansion_state()
				source_version = 21
				migrated["state_version"] = source_version
			21:
				# v22 introduces the two-parcel campus portfolio as a neutral, exact
				# construction ledger. A claimed v21 file may not smuggle later deeds,
				# modules, staffing, or receipts through migration.
				if migrated.has("campus_portfolio"):
					if original_source_version == 21:
						return {}
					migrated.erase("campus_portfolio")
				if not _is_integral_number(migrated.get("day", null)):
					return {}
				migrated["campus_portfolio"] = CampusPortfolioStateScript.neutral_save_data(
					int(migrated["day"])
				)
				source_version = 22
				migrated["state_version"] = source_version
			22:
				# v23 adds the conserving Farm Treasury. A legacy checkpoint knew
				# only its current Feed Fund, so migration preserves that exact cash
				# and invents no credit, invoices, interest, rating, or journal history.
				if migrated.has("farm_treasury_state"):
					if original_source_version == 22:
						return {}
					migrated.erase("farm_treasury_state")
				if (
					not _is_integral_number(migrated.get("day", null))
					or not _is_integral_number(migrated.get("revenue_cents", null))
				):
					return {}
				var migrated_day := int(migrated["day"])
				var migrated_cash := int(migrated["revenue_cents"])
				if (
					migrated_day < 1 or migrated_day > 9999
					or migrated_cash < 0 or migrated_cash > 2_000_000_000
				):
					return {}
				migrated["farm_treasury_state"] = FarmTreasuryStateScript.neutral_save_data(
					migrated_cash,
					maxi(0, migrated_day - 1),
				)
				source_version = 23
				migrated["state_version"] = source_version
			23:
				# v24 gives each career a persisted incident docket. A v23 career had
				# the original fixed seed, so migration preserves that identity and
				# derives a fresh independent incident stream without touching claims,
				# workers, money, or the currently pending decision.
				for docket_field in [
					"career_seed",
					"incident_rng_state",
					"incident_bag",
					"last_standard_incident_id",
				]:
					if migrated.has(docket_field):
						if original_source_version == 23:
							return {}
						migrated.erase(docket_field)
				var migrated_incident_rng := RandomNumberGenerator.new()
				migrated_incident_rng.seed = 1701 + INCIDENT_DOCKET_SEED_OFFSET
				var migrated_last_incident := &""
				var migrated_pending_value: Variant = migrated.get("pending_decision", {})
				if migrated_pending_value is Dictionary:
					var migrated_pending_id := StringName(String(
						(migrated_pending_value as Dictionary).get("id", "")
					))
					if migrated_pending_id in INCIDENT_ORDER:
						migrated_last_incident = migrated_pending_id
				migrated["career_seed"] = 1701
				migrated["incident_rng_state"] = str(migrated_incident_rng.state)
				migrated["incident_bag"] = []
				migrated["last_standard_incident_id"] = String(migrated_last_incident)
				source_version = 24
				migrated["state_version"] = source_version
			24:
				# v25 makes the already-funded supervisor posts named and controllable.
				# Legacy office levels receive the default post for each funded seat, so
				# payroll, action capacity, cash, worker state, and chronology are unchanged.
				var facilities_value: Variant = migrated.get("owned_facilities", null)
				if not facilities_value is Dictionary:
					return {}
				var facilities := facilities_value as Dictionary
				var rooster_level_value: Variant = facilities.get(
					String(ROOSTER_OPERATIONS_OFFICE_ID), facilities.get(ROOSTER_OPERATIONS_OFFICE_ID, null)
				)
				if not _is_integral_number(rooster_level_value):
					return {}
				var roster_count := clampi(int(rooster_level_value) + 1, 1, 4)
				var migrated_roster: Array[Dictionary] = []
				for slot_index in roster_count:
					migrated_roster.append(_new_manager_record(
						MANAGER_DEFAULT_HIRE_ORDER[slot_index], slot_index, 1
					))
				migrated["manager_roster_version"] = MANAGER_ROSTER_VERSION
				migrated["manager_roster"] = migrated_roster
				migrated["last_manager_action"] = {}
				migrated["management_reports_today"] = 0
				migrated["management_reports_total"] = 0
				migrated["management_visibility_today"] = 0
				source_version = 25
				migrated["state_version"] = source_version
			_:
				return {}
	return migrated


func _migrated_v14_active_market_contract(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var offer_id := StringName(String(source.get("offer_id", "")))
	if not MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	var target_day := int(source.get("target_day", source.get("signed_day", 0)))
	var service_coop_level := int(source.get("service_coop_level_at_signing", 0))
	var quote := _market_contract_quote_for_day(
		offer_id,
		target_day,
		service_coop_level,
		0,
		&"standard_terms",
		true,
	)
	if quote.is_empty():
		return {}
	var migrated := quote.duplicate(true)
	migrated.merge(source.duplicate(true), true)
	var migrated_schedules := _migrated_v14_market_contract_schedules(
		source.get("scheduled_claims", null),
		quote.get("scheduled_claims", null),
	)
	if migrated_schedules.size() != (quote.get("scheduled_claims", []) as Array).size():
		return {}
	migrated["scheduled_claims"] = migrated_schedules
	var base_premium_cents := int(source.get("base_premium_cents", -1))
	var contracted_service_bonus_cents := int(source.get("service_coop_bonus_cents", -1))
	var contracted_premium_cents := int(source.get("premium_cents", -1))
	var contracted_breach_cents := int(source.get("breach_cents", -1))
	var neutral_season := _neutral_market_season_for_day(target_day)
	migrated.merge({
		"version": 2,
		"legacy_terms_grandfathered": true,
		"season": neutral_season,
		"season_id": &"baseline_neutral",
		"season_label": "BASELINE NEUTRAL BOOK",
		"season_demand_basis_points": 0,
		"clause_id": &"standard_terms",
		"clause_label": "STANDARD TERMS",
		"clause_summary": String(
			(MARKET_CONTRACT_CLAUSE_DEFINITIONS[&"standard_terms"] as Dictionary).get("summary", "")
		),
		"clause_category": &"standard",
		"category": &"standard",
		"label": "STANDARD TERMS",
		"summary": String(
			(MARKET_CONTRACT_CLAUSE_DEFINITIONS[&"standard_terms"] as Dictionary).get("summary", "")
		),
		"requires_negotiation_room": false,
		"clause_available": true,
		"negotiation_room_level_at_signing": 0,
		"authored_base_premium_cents": base_premium_cents,
		"base_premium_cents": base_premium_cents,
		"season_premium_delta_cents": 0,
		"clause_premium_basis_points": 0,
		"clause_premium_delta_cents": 0,
		"market_premium_cents": base_premium_cents,
		"contracted_service_coop_bonus_cents": contracted_service_bonus_cents,
		"contracted_premium_cents": contracted_premium_cents,
		"authored_breach_cents": contracted_breach_cents,
		"season_breach_basis_points": 0,
		"season_breach_delta_cents": 0,
		"clause_breach_basis_points": 0,
		"clause_breach_delta_cents": 0,
		"contracted_breach_cents": contracted_breach_cents,
		"welfare_gate_minimum": 0,
		"welfare_gate_required": false,
	}, true)
	return migrated


func _migrated_v14_market_contract_result(source: Dictionary) -> Dictionary:
	if source.is_empty():
		return {}
	var offer_id := StringName(String(source.get("offer_id", "")))
	if not MARKET_CONTRACT_DEFINITIONS.has(offer_id):
		return {}
	var target_day := int(source.get("target_day", source.get("day", 0)))
	var service_coop_level := int(source.get("service_coop_level_at_signing", 0))
	var quote := _market_contract_quote_for_day(
		offer_id,
		target_day,
		service_coop_level,
		0,
		&"standard_terms",
		true,
	)
	if quote.is_empty():
		return {}
	var migrated := source.duplicate(true)
	var migrated_schedules := _migrated_v14_market_contract_schedules(
		source.get("scheduled_claims", null),
		quote.get("scheduled_claims", null),
	)
	if migrated_schedules.size() != (quote.get("scheduled_claims", []) as Array).size():
		return {}
	var migrated_claim_ids: Array[int] = []
	var migrated_accepted_ids: Array[int] = []
	var migrated_rejected_ids: Array[int] = []
	for schedule in migrated_schedules:
		if (
			not _is_integral_number(schedule.get("claim_id", null))
			or typeof(schedule.get("released", null)) != TYPE_BOOL
			or typeof(schedule.get("rejected", null)) != TYPE_BOOL
		):
			return {}
		var claim_id := int(schedule.get("claim_id", -1))
		migrated_claim_ids.append(claim_id)
		if bool(schedule.get("released", false)):
			migrated_accepted_ids.append(claim_id)
		elif bool(schedule.get("rejected", false)):
			migrated_rejected_ids.append(claim_id)
	var base_premium_cents := int(source.get("base_premium_cents", -1))
	var contracted_service_bonus_cents := int(
		source.get("contracted_service_coop_bonus_cents", -1)
	)
	var authored_breach_cents := int(
		(MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary).get("breach_cents", -1)
	)
	var neutral_season := _neutral_market_season_for_day(target_day)
	migrated.merge({
		"version": 2,
		"legacy_terms_grandfathered": true,
		"season": neutral_season,
		"season_id": &"baseline_neutral",
		"season_label": "BASELINE NEUTRAL BOOK",
		"season_demand_basis_points": 0,
		"clause_id": &"standard_terms",
		"clause_label": "STANDARD TERMS",
		"clause_summary": String(
			(MARKET_CONTRACT_CLAUSE_DEFINITIONS[&"standard_terms"] as Dictionary).get("summary", "")
		),
		"clause_category": &"standard",
		"negotiation_room_level_at_signing": 0,
		"authored_service_window_minutes": int(quote.get("authored_service_window_minutes", 0)),
		"service_window_minutes": int(quote.get("service_window_minutes", 0)),
		"authored_dominant_lane": String(quote.get("authored_dominant_lane", "")),
		"authored_lane_mix": (quote.get("authored_lane_mix", {}) as Dictionary).duplicate(true),
		"lane_mix": (quote.get("lane_mix", {}) as Dictionary).duplicate(true),
		"arrival_batches": (quote.get("arrival_batches", []) as Array).duplicate(true),
		"scheduled_claims": migrated_schedules,
		"claim_ids": migrated_claim_ids,
		"accepted_claim_ids": migrated_accepted_ids,
		"rejected_claim_ids": migrated_rejected_ids,
		"authored_base_premium_cents": base_premium_cents,
		"base_premium_cents": base_premium_cents,
		"season_premium_delta_cents": 0,
		"clause_premium_basis_points": 0,
		"clause_premium_delta_cents": 0,
		"market_premium_cents": base_premium_cents,
		"contracted_premium_cents": base_premium_cents + contracted_service_bonus_cents,
		"authored_breach_cents": authored_breach_cents,
		"season_breach_basis_points": 0,
		"season_breach_delta_cents": 0,
		"clause_breach_basis_points": 0,
		"clause_breach_delta_cents": 0,
		"contracted_breach_cents": authored_breach_cents,
		"delivery_threshold_met": (
			int(source.get("timely_sound_completed", -1))
			>= int(source.get("required_completed", 0))
		),
		"welfare_gate_met": true,
		"closing_welfare": 0,
		"welfare_gate_minimum": 0,
		"welfare_gate_required": false,
	}, true)
	return migrated


func _migrated_v14_market_contract_schedules(
	source_value: Variant,
	authored_value: Variant
) -> Array[Dictionary]:
	var migrated: Array[Dictionary] = []
	if not source_value is Array or not authored_value is Array:
		return migrated
	var source := source_value as Array
	var authored := authored_value as Array
	if source.size() != authored.size():
		return migrated
	for index in authored.size():
		if not source[index] is Dictionary or not authored[index] is Dictionary:
			migrated.clear()
			return migrated
		var schedule := (source[index] as Dictionary).duplicate(true)
		var authored_schedule := authored[index] as Dictionary
		schedule["authored_lane"] = String(authored_schedule.get("authored_lane", ""))
		schedule["authored_rush"] = bool(authored_schedule.get("authored_rush", false))
		migrated.append(schedule)
	return migrated


func _validated_market_contract_id_array(value: Variant) -> Dictionary:
	if not value is Array:
		return {"valid": false, "ids": []}
	var source := value as Array
	if source.size() > MARKET_CONTRACT_MAX_CLAIMS:
		return {"valid": false, "ids": []}
	var ids: Array[int] = []
	var seen: Dictionary[int, bool] = {}
	for id_value in source:
		if not _is_integral_number(id_value):
			return {"valid": false, "ids": []}
		var claim_id := int(id_value)
		if claim_id < 1 or claim_id > 2_000_000_000 or seen.has(claim_id):
			return {"valid": false, "ids": []}
		seen[claim_id] = true
		ids.append(claim_id)
	return {"valid": true, "ids": ids}


func _market_contract_same_id_order(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for index in left.size():
		if int(left[index]) != int(right[index]):
			return false
	return true


func _market_contract_lane_mix_matches(value: Variant, authored: Dictionary) -> bool:
	if not value is Dictionary:
		return false
	var source := value as Dictionary
	if source.size() != authored.size():
		return false
	for lane in CLAIM_LANES:
		var lane_key := String(lane)
		var authored_count := int(authored.get(lane_key, authored.get(lane, 0)))
		var count_value: Variant = source.get(lane_key, source.get(lane, null))
		if authored_count == 0:
			if count_value != null:
				return false
			continue
		if not _is_integral_number(count_value) or int(count_value) != authored_count:
			return false
	return true


func _market_contract_arrival_batches_match(value: Variant, authored_value: Variant) -> bool:
	if not value is Array or not authored_value is Array:
		return false
	var source := value as Array
	var authored := authored_value as Array
	if source.size() != authored.size():
		return false
	for index in authored.size():
		var batch_value: Variant = source[index]
		var authored_batch_value: Variant = authored[index]
		if not batch_value is Dictionary or not authored_batch_value is Dictionary:
			return false
		var batch := batch_value as Dictionary
		var authored_batch := authored_batch_value as Dictionary
		for field in ["batch_index", "minute_of_day", "deadline_minute_of_day", "count"]:
			if (
				not _is_integral_number(batch.get(field, null))
				or int(batch.get(field, -1)) != int(authored_batch.get(field, -2))
			):
				return false
		for field in ["time", "deadline_time"]:
			if String(batch.get(field, "")) != String(authored_batch.get(field, "")):
				return false
		if typeof(batch.get("rush", null)) != TYPE_BOOL:
			return false
		if bool(batch.get("rush", false)) != bool(authored_batch.get("rush", false)):
			return false
		var lanes_value: Variant = batch.get("lanes", null)
		var authored_lanes_value: Variant = authored_batch.get("lanes", null)
		if not lanes_value is Array or not authored_lanes_value is Array:
			return false
		var lanes := lanes_value as Array
		var authored_lanes := authored_lanes_value as Array
		if lanes.size() != authored_lanes.size():
			return false
		for lane_index in authored_lanes.size():
			if String(lanes[lane_index]) != String(authored_lanes[lane_index]):
				return false
		if not _market_contract_lane_mix_matches(
			batch.get("lane_mix", null),
			authored_batch.get("lane_mix", {}) as Dictionary,
		):
			return false
	return true


func _market_contract_season_matches(value: Variant, expected: Dictionary) -> bool:
	if not value is Dictionary:
		return false
	var source := value as Dictionary
	for field in ["id", "label", "short_label", "summary"]:
		if String(source.get(field, "")) != String(expected.get(field, "")):
			return false
	for field in [
		"target_day", "season_index", "quarter", "year", "start_day", "end_day",
		"days_remaining",
	]:
		if (
			not _is_integral_number(source.get(field, null))
			or int(source.get(field, -99999)) != int(expected.get(field, -99998))
		):
			return false
	var demand_value: Variant = source.get("lane_demand_basis_points", null)
	if not demand_value is Dictionary:
		return false
	var demand := demand_value as Dictionary
	var expected_demand := expected.get("lane_demand_basis_points", {}) as Dictionary
	if demand.size() != CLAIM_LANES.size():
		return false
	for lane in CLAIM_LANES:
		var lane_key := String(lane)
		var demand_basis_points: Variant = demand.get(lane_key, demand.get(lane, null))
		if (
			not _is_integral_number(demand_basis_points)
			or int(demand_basis_points) != int(expected_demand.get(lane_key, 0))
		):
			return false
	return true


func _active_market_contract_quote_matches(
	source: Dictionary,
	expected: Dictionary,
	legacy_terms_grandfathered: bool
) -> bool:
	for field in [
		"authored_service_window_minutes",
		"service_window_minutes",
		"season_demand_basis_points",
		"negotiation_room_level_at_signing",
		"authored_base_premium_cents",
		"base_premium_cents",
		"season_premium_delta_cents",
		"clause_premium_basis_points",
		"clause_premium_delta_cents",
		"market_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"contracted_service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"contracted_premium_cents",
		"premium_cents",
		"authored_breach_cents",
		"season_breach_basis_points",
		"season_breach_delta_cents",
		"clause_breach_basis_points",
		"clause_breach_delta_cents",
		"contracted_breach_cents",
		"breach_cents",
		"welfare_gate_minimum",
	]:
		if (
			not _is_integral_number(source.get(field, null))
			or int(source.get(field, -999999)) != int(expected.get(field, -999998))
		):
			return false
	for field in [
		"quote_id", "season_id", "season_label", "clause_id", "clause_label",
		"clause_summary", "clause_category", "category", "label", "summary",
		"authored_dominant_lane",
	]:
		if String(source.get(field, "")) != String(expected.get(field, "")):
			return false
	for field in [
		"requires_negotiation_room", "clause_available", "welfare_gate_required",
	]:
		if (
			typeof(source.get(field, null)) != TYPE_BOOL
			or bool(source.get(field, false)) != bool(expected.get(field, false))
		):
			return false
	if not _market_contract_season_matches(
		source.get("season", null),
		expected.get("season", {}) as Dictionary,
	):
		return false
	if not _market_contract_lane_mix_matches(
		source.get("authored_lane_mix", null),
		expected.get("authored_lane_mix", {}) as Dictionary,
	):
		return false
	if legacy_terms_grandfathered:
		if (
			String(source.get("season_id", "")) != "baseline_neutral"
			or String(source.get("clause_id", "")) != "standard_terms"
			or int(source.get("negotiation_room_level_at_signing", -1)) != 0
			or int(source.get("season_demand_basis_points", 1)) != 0
			or int(source.get("season_premium_delta_cents", 1)) != 0
			or int(source.get("clause_premium_delta_cents", 1)) != 0
			or int(source.get("season_breach_delta_cents", 1)) != 0
			or int(source.get("clause_breach_delta_cents", 1)) != 0
		):
			return false
	return true


func _market_contract_result_quote_matches(
	source: Dictionary,
	expected: Dictionary,
	legacy_terms_grandfathered: bool
) -> bool:
	for field in [
		"authored_service_window_minutes",
		"service_window_minutes",
		"season_demand_basis_points",
		"negotiation_room_level_at_signing",
		"authored_base_premium_cents",
		"base_premium_cents",
		"season_premium_delta_cents",
		"clause_premium_basis_points",
		"clause_premium_delta_cents",
		"market_premium_cents",
		"service_coop_level_at_signing",
		"contracted_service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"contracted_premium_cents",
		"authored_breach_cents",
		"season_breach_basis_points",
		"season_breach_delta_cents",
		"clause_breach_basis_points",
		"clause_breach_delta_cents",
		"contracted_breach_cents",
		"welfare_gate_minimum",
	]:
		if (
			not _is_integral_number(source.get(field, null))
			or int(source.get(field, -999999)) != int(expected.get(field, -999998))
		):
			return false
	for field in [
		"season_id", "season_label", "clause_id", "clause_label", "clause_summary",
		"clause_category", "authored_dominant_lane",
	]:
		if String(source.get(field, "")) != String(expected.get(field, "")):
			return false
	if not _market_contract_season_matches(
		source.get("season", null),
		expected.get("season", {}) as Dictionary,
	):
		return false
	if not _market_contract_lane_mix_matches(
		source.get("authored_lane_mix", null),
		expected.get("authored_lane_mix", {}) as Dictionary,
	) or not _market_contract_lane_mix_matches(
		source.get("lane_mix", null),
		expected.get("lane_mix", {}) as Dictionary,
	):
		return false
	if not _market_contract_arrival_batches_match(
		source.get("arrival_batches", null),
		expected.get("arrival_batches", null),
	):
		return false
	if not _market_contract_result_schedules_match(
		source.get("scheduled_claims", null),
		expected.get("scheduled_claims", null),
	):
		return false
	if legacy_terms_grandfathered and (
		String(source.get("season_id", "")) != "baseline_neutral"
		or String(source.get("clause_id", "")) != "standard_terms"
		or int(source.get("negotiation_room_level_at_signing", -1)) != 0
		or int(source.get("season_demand_basis_points", 1)) != 0
		or int(source.get("season_premium_delta_cents", 1)) != 0
		or int(source.get("clause_premium_delta_cents", 1)) != 0
		or int(source.get("season_breach_delta_cents", 1)) != 0
		or int(source.get("clause_breach_delta_cents", 1)) != 0
	):
		return false
	return true


func _market_contract_result_schedules_match(value: Variant, expected_value: Variant) -> bool:
	if not value is Array or not expected_value is Array:
		return false
	var source := value as Array
	var expected := expected_value as Array
	if source.size() != expected.size():
		return false
	var previous_claim_id := -1
	for index in expected.size():
		if not source[index] is Dictionary or not expected[index] is Dictionary:
			return false
		var schedule := source[index] as Dictionary
		var expected_schedule := expected[index] as Dictionary
		for field in [
			"batch_index", "arrival_minute_of_day", "deadline_minute_of_day",
			"service_window_minutes",
		]:
			if (
				not _is_integral_number(schedule.get(field, null))
				or int(schedule.get(field, -1)) != int(expected_schedule.get(field, -2))
			):
				return false
		for field in ["lane", "authored_lane", "arrival_time", "deadline_time"]:
			if String(schedule.get(field, "")) != String(expected_schedule.get(field, "")):
				return false
		for field in ["rush", "authored_rush"]:
			if (
				typeof(schedule.get(field, null)) != TYPE_BOOL
				or bool(schedule.get(field, false)) != bool(expected_schedule.get(field, false))
			):
				return false
		if (
			not _is_integral_number(schedule.get("claim_id", null))
			or typeof(schedule.get("released", null)) != TYPE_BOOL
			or typeof(schedule.get("rejected", null)) != TYPE_BOOL
		):
			return false
		var claim_id := int(schedule.get("claim_id", -1))
		var released := bool(schedule.get("released", false))
		var rejected := bool(schedule.get("rejected", false))
		if (
			claim_id < 1
			or claim_id > 2_000_000_000
			or (index > 0 and claim_id != previous_claim_id + 1)
			or released == rejected
		):
			return false
		previous_claim_id = claim_id
	return true


func _validated_active_market_contract(
	value: Variant,
	saved_day: int,
	saved_phase: int,
	saved_minute: int,
	restored_service_coop_level: int,
	restored_negotiation_room_level: int
) -> Dictionary:
	var invalid := {"valid": false, "record": {}}
	if not value is Dictionary:
		return invalid
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	if (
		saved_day < CONTRACT_BOARD_UNLOCK_DAY
		or saved_phase not in [
			ShiftPhase.REVIEW,
			ShiftPhase.AWAITING_DIRECTIVE,
			ShiftPhase.RUNNING,
			ShiftPhase.AWAITING_INCIDENT,
		]
		or saved_minute < SHIFT_START_MINUTE
		or saved_minute > SHIFT_END_MINUTE
	):
		return invalid
	var offer_id := StringName(String(source.get("offer_id", "")))
	if offer_id not in MARKET_CONTRACT_OFFER_ORDER:
		return invalid
	if not _is_integral_number(source.get("version", null)) or int(source.get("version", 0)) != 2:
		return invalid
	if typeof(source.get("legacy_terms_grandfathered", null)) != TYPE_BOOL:
		return invalid
	var legacy_terms_grandfathered := bool(source.get("legacy_terms_grandfathered", false))
	var clause_id := StringName(String(source.get("clause_id", "")))
	if clause_id not in MARKET_CONTRACT_CLAUSE_ORDER:
		return invalid
	for frozen_level_field in [
		"service_coop_level_at_signing",
		"negotiation_room_level_at_signing",
	]:
		if not _is_integral_number(source.get(frozen_level_field, null)):
			return invalid
	var service_coop_level_at_signing := int(source.get("service_coop_level_at_signing", -1))
	var negotiation_room_level_at_signing := int(
		source.get("negotiation_room_level_at_signing", -1)
	)
	if (
		service_coop_level_at_signing < 0
		or service_coop_level_at_signing > restored_service_coop_level
		or service_coop_level_at_signing > 3
		or negotiation_room_level_at_signing < 0
		or negotiation_room_level_at_signing > restored_negotiation_room_level
		or negotiation_room_level_at_signing > 1
		or (clause_id != &"standard_terms" and negotiation_room_level_at_signing != 1)
		or (
			legacy_terms_grandfathered
			and (
				clause_id != &"standard_terms"
				or negotiation_room_level_at_signing != 0
			)
		)
	):
		return invalid
	var authored := _market_contract_quote_for_day(
		offer_id,
		saved_day,
		service_coop_level_at_signing,
		negotiation_room_level_at_signing,
		clause_id,
		legacy_terms_grandfathered,
	)
	if authored.is_empty() or not _active_market_contract_quote_matches(
		source,
		authored,
		legacy_terms_grandfathered,
	):
		return invalid
	var expected_contract_id := "FM-%04d-%s" % [saved_day, String(offer_id).to_upper()]
	if (
		String(source.get("contract_id", "")) != expected_contract_id
		or String(source.get("id", "")) != String(offer_id)
	):
		return invalid
	for field in ["signed_day", "target_day", "deadline_day"]:
		if not _is_integral_number(source.get(field, null)) or int(source.get(field, 0)) != saved_day:
			return invalid
	for field in [
		"required_claim_capacity",
		"required_completed",
		"total_claims",
		"rush_claims",
		"service_window_minutes",
		"breach_cents",
	]:
		if (
			not _is_integral_number(source.get(field, null))
			or int(source.get(field, -1)) != int(authored.get(field, -2))
		):
			return invalid
	for field in [
		"required_active_staff",
		"base_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"premium_cents",
	]:
		if not _is_integral_number(source.get(field, null)):
			return invalid
	if typeof(source.get("legacy_staffing_grandfathered", null)) != TYPE_BOOL:
		return invalid
	var legacy_staffing_grandfathered := bool(source.get("legacy_staffing_grandfathered", false))
	var required_active_staff := int(source.get("required_active_staff", -1))
	var authored_required_active_staff := int(authored.get("required_active_staff", -1))
	if (
		(legacy_staffing_grandfathered and required_active_staff != 0)
		or (
			not legacy_staffing_grandfathered
			and required_active_staff != authored_required_active_staff
		)
	):
		return invalid
	var base_premium_cents := int((MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary).get("premium_cents", -1))
	var expected_service_bonus := _service_coop_premium_bonus_cents(
		base_premium_cents,
		service_coop_level_at_signing,
	)
	var expected_bonus_basis_points := (
		service_coop_level_at_signing * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
	)
	if (
		int(source.get("base_premium_cents", -1)) != base_premium_cents
		or int(source.get("service_coop_bonus_cents", -1)) != expected_service_bonus
		or int(source.get("premium_bonus_basis_points", -1)) != expected_bonus_basis_points
		or int(source.get("premium_cents", -1)) != int(authored.get("premium_cents", -2))
	):
		return invalid
	for field in [
		"name",
		"short_name",
		"client",
		"tagline",
		"success_required",
		"lane_mix_label",
		"arrival_schedule",
	]:
		if String(source.get(field, "")) != String(authored.get(field, "")):
			return invalid
	if String(source.get("tone", "")) != String(authored.get("tone", "")):
		return invalid
	if not _market_contract_lane_mix_matches(
		source.get("lane_mix", null),
		authored.get("lane_mix", {}) as Dictionary,
	):
		return invalid
	if not _market_contract_arrival_batches_match(
		source.get("arrival_batches", null),
		authored.get("arrival_batches", null),
	):
		return invalid

	var claim_ids_result := _validated_market_contract_id_array(source.get("claim_ids", null))
	if not bool(claim_ids_result.get("valid", false)):
		return invalid
	var claim_ids := claim_ids_result.get("ids", []) as Array
	var authored_schedules := authored.get("scheduled_claims", []) as Array
	var schedule_values: Variant = source.get("scheduled_claims", null)
	if (
		claim_ids.size() != int(authored.get("total_claims", -1))
		or not schedule_values is Array
		or (schedule_values as Array).size() != authored_schedules.size()
	):
		return invalid
	var normalized_schedules: Array[Dictionary] = []
	var derived_accepted: Array[int] = []
	var derived_rejected: Array[int] = []
	var rush_by_claim_id: Dictionary[int, bool] = {}
	for index in authored_schedules.size():
		var schedule_value: Variant = (schedule_values as Array)[index]
		var authored_schedule_value: Variant = authored_schedules[index]
		if not schedule_value is Dictionary or not authored_schedule_value is Dictionary:
			return invalid
		var schedule := schedule_value as Dictionary
		var authored_schedule := authored_schedule_value as Dictionary
		for field in [
			"batch_index",
			"arrival_minute_of_day",
			"deadline_minute_of_day",
			"service_window_minutes",
		]:
			if (
				not _is_integral_number(schedule.get(field, null))
				or int(schedule.get(field, -1)) != int(authored_schedule.get(field, -2))
			):
				return invalid
		for field in ["lane", "authored_lane", "arrival_time", "deadline_time"]:
			if String(schedule.get(field, "")) != String(authored_schedule.get(field, "")):
				return invalid
		for field in ["rush", "authored_rush"]:
			if (
				typeof(schedule.get(field, null)) != TYPE_BOOL
				or bool(schedule.get(field, false)) != bool(authored_schedule.get(field, false))
			):
				return invalid
		if (
			not _is_integral_number(schedule.get("claim_id", null))
			or int(schedule.get("claim_id", -1)) != int(claim_ids[index])
			or typeof(schedule.get("released", null)) != TYPE_BOOL
			or typeof(schedule.get("rejected", null)) != TYPE_BOOL
		):
			return invalid
		var released := bool(schedule.get("released", false))
		var rejected := bool(schedule.get("rejected", false))
		if released and rejected:
			return invalid
		var arrival_minute := int(authored_schedule.get("arrival_minute_of_day", SHIFT_END_MINUTE + 1))
		var terminal := released or rejected
		if saved_phase in [ShiftPhase.REVIEW, ShiftPhase.AWAITING_DIRECTIVE]:
			if terminal or saved_minute != SHIFT_START_MINUTE:
				return invalid
		else:
			if (arrival_minute <= saved_minute) != terminal:
				return invalid
		var claim_id := int(claim_ids[index])
		if released:
			derived_accepted.append(claim_id)
		elif rejected:
			derived_rejected.append(claim_id)
		rush_by_claim_id[claim_id] = bool(authored_schedule.get("rush", false))
		var normalized_schedule := authored_schedule.duplicate(true)
		normalized_schedule["claim_id"] = claim_id
		normalized_schedule["released"] = released
		normalized_schedule["rejected"] = rejected
		normalized_schedules.append(normalized_schedule)

	var array_fields := [
		"accepted_claim_ids",
		"completed_claim_ids",
		"sound_completed_claim_ids",
		"timely_sound_claim_ids",
		"cracked_claim_ids",
		"late_claim_ids",
		"rejected_claim_ids",
	]
	var validated_arrays: Dictionary = {}
	for field in array_fields:
		var ids_result := _validated_market_contract_id_array(source.get(field, null))
		if not bool(ids_result.get("valid", false)):
			return invalid
		validated_arrays[field] = ids_result.get("ids", [])
	var accepted_ids := validated_arrays["accepted_claim_ids"] as Array
	var rejected_ids := validated_arrays["rejected_claim_ids"] as Array
	if (
		not _market_contract_same_id_order(accepted_ids, derived_accepted)
		or not _market_contract_same_id_order(rejected_ids, derived_rejected)
	):
		return invalid
	var completed_ids := validated_arrays["completed_claim_ids"] as Array
	var sound_ids := validated_arrays["sound_completed_claim_ids"] as Array
	var timely_ids := validated_arrays["timely_sound_claim_ids"] as Array
	var cracked_ids := validated_arrays["cracked_claim_ids"] as Array
	var late_ids := validated_arrays["late_claim_ids"] as Array
	for completed_id in completed_ids:
		if completed_id not in accepted_ids:
			return invalid
		var is_sound: bool = completed_id in sound_ids
		var is_cracked: bool = completed_id in cracked_ids
		var is_timely: bool = completed_id in timely_ids
		var is_late_or_failed: bool = completed_id in late_ids
		if is_sound == is_cracked or (is_timely and not is_sound):
			return invalid
		if is_late_or_failed != (not is_timely):
			return invalid
	for sound_id in sound_ids:
		if sound_id not in completed_ids:
			return invalid
	for timely_id in timely_ids:
		if timely_id not in sound_ids:
			return invalid
	for cracked_id in cracked_ids:
		if cracked_id not in completed_ids:
			return invalid
	for late_id in late_ids:
		if late_id not in completed_ids:
			return invalid
	var rush_completed_on_time := 0
	for timely_id in timely_ids:
		if bool(rush_by_claim_id.get(int(timely_id), false)):
			rush_completed_on_time += 1
	var released_batch_count := 0
	for batch_index in (authored.get("arrival_batches", []) as Array).size():
		var complete := true
		for schedule in normalized_schedules:
			if int(schedule.get("batch_index", -1)) != batch_index:
				continue
			if not bool(schedule.get("released", false)) and not bool(schedule.get("rejected", false)):
				complete = false
				break
		if complete:
			released_batch_count += 1
	var expected_counts := {
		"released_batch_count": released_batch_count,
		"completed_count": completed_ids.size(),
		"sound_completed": sound_ids.size(),
		"timely_sound_completed": timely_ids.size(),
		"rush_completed_on_time": rush_completed_on_time,
		"cracked_count": cracked_ids.size(),
		"late_count": late_ids.size(),
	}
	for field in expected_counts:
		if (
			not _is_integral_number(source.get(field, null))
			or int(source.get(field, -1)) != int(expected_counts[field])
		):
			return invalid
	var expected_status := "active" if not accepted_ids.is_empty() else "signed"
	if String(source.get("status", "")) != expected_status:
		return invalid
	var normalized := {
		"version": 2,
		"contract_id": expected_contract_id,
		"offer_id": String(offer_id),
		"id": String(offer_id),
		"name": String(authored.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(authored.get("short_name", "MUTUAL BINDER")),
		"client": String(authored.get("client", "FARM MUTUAL")),
		"tagline": String(authored.get("tagline", "")),
		"tone": String(authored.get("tone", &"quality")),
		"signed_day": saved_day,
		"target_day": saved_day,
		"deadline_day": saved_day,
		"status": expected_status,
		"required_claim_capacity": int(authored.get("required_claim_capacity", 0)),
		"required_active_staff": required_active_staff,
		"legacy_staffing_grandfathered": legacy_staffing_grandfathered,
		"legacy_terms_grandfathered": legacy_terms_grandfathered,
		"required_completed": int(authored.get("required_completed", 0)),
		"success_required": String(authored.get("success_required", "")),
		"total_claims": int(authored.get("total_claims", 0)),
		"rush_claims": int(authored.get("rush_claims", 0)),
		"service_window_minutes": int(authored.get("service_window_minutes", 0)),
		"base_premium_cents": base_premium_cents,
		"service_coop_level_at_signing": service_coop_level_at_signing,
		"service_coop_bonus_cents": expected_service_bonus,
		"premium_bonus_basis_points": expected_bonus_basis_points,
		"premium_cents": int(authored.get("premium_cents", 0)),
		"breach_cents": int(authored.get("breach_cents", 0)),
		"lane_mix": (authored.get("lane_mix", {}) as Dictionary).duplicate(true),
		"lane_mix_label": String(authored.get("lane_mix_label", "")),
		"arrival_batches": (authored.get("arrival_batches", []) as Array).duplicate(true),
		"arrival_schedule": String(authored.get("arrival_schedule", "")),
		"scheduled_claims": normalized_schedules,
		"claim_ids": claim_ids.duplicate(),
		"accepted_claim_ids": accepted_ids.duplicate(),
		"completed_claim_ids": completed_ids.duplicate(),
		"sound_completed_claim_ids": sound_ids.duplicate(),
		"timely_sound_claim_ids": timely_ids.duplicate(),
		"cracked_claim_ids": cracked_ids.duplicate(),
		"late_claim_ids": late_ids.duplicate(),
		"rejected_claim_ids": rejected_ids.duplicate(),
		"released_batch_count": released_batch_count,
		"completed_count": completed_ids.size(),
		"sound_completed": sound_ids.size(),
		"timely_sound_completed": timely_ids.size(),
		"rush_completed_on_time": rush_completed_on_time,
		"cracked_count": cracked_ids.size(),
		"late_count": late_ids.size(),
	}
	var authoritative_normalized := authored.duplicate(true)
	authoritative_normalized.merge(normalized, true)
	return {"valid": true, "record": authoritative_normalized}


func _validated_market_contract_result(
	value: Variant,
	saved_day: int,
	restored_service_coop_level: int,
	restored_negotiation_room_level: int
) -> Dictionary:
	var invalid := {"valid": false, "record": {}}
	if not value is Dictionary:
		return invalid
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	if not _is_integral_number(source.get("version", null)) or int(source.get("version", 0)) != 2:
		return invalid
	if typeof(source.get("legacy_terms_grandfathered", null)) != TYPE_BOOL:
		return invalid
	var legacy_terms_grandfathered := bool(source.get("legacy_terms_grandfathered", false))
	if not _is_integral_number(source.get("day", null)):
		return invalid
	var result_day := int(source.get("day", 0))
	if result_day < CONTRACT_BOARD_UNLOCK_DAY or result_day > saved_day:
		return invalid
	if (
		not _is_integral_number(source.get("target_day", null))
		or int(source.get("target_day", 0)) != result_day
	):
		return invalid
	var offer_id := StringName(String(source.get("offer_id", "")))
	if offer_id not in MARKET_CONTRACT_OFFER_ORDER:
		return invalid
	var clause_id := StringName(String(source.get("clause_id", "")))
	if clause_id not in MARKET_CONTRACT_CLAUSE_ORDER:
		return invalid
	for frozen_level_field in [
		"service_coop_level_at_signing",
		"negotiation_room_level_at_signing",
	]:
		if not _is_integral_number(source.get(frozen_level_field, null)):
			return invalid
	var service_coop_level_at_signing := int(source.get("service_coop_level_at_signing", -1))
	var negotiation_room_level_at_signing := int(
		source.get("negotiation_room_level_at_signing", -1)
	)
	if (
		service_coop_level_at_signing < 0
		or service_coop_level_at_signing > restored_service_coop_level
		or service_coop_level_at_signing > 3
		or negotiation_room_level_at_signing < 0
		or negotiation_room_level_at_signing > restored_negotiation_room_level
		or negotiation_room_level_at_signing > 1
		or (clause_id != &"standard_terms" and negotiation_room_level_at_signing != 1)
		or (
			legacy_terms_grandfathered
			and (
				clause_id != &"standard_terms"
				or negotiation_room_level_at_signing != 0
			)
		)
	):
		return invalid
	var authored := _market_contract_quote_for_day(
		offer_id,
		result_day,
		service_coop_level_at_signing,
		negotiation_room_level_at_signing,
		clause_id,
		legacy_terms_grandfathered,
	)
	if authored.is_empty() or not _market_contract_result_quote_matches(
		source,
		authored,
		legacy_terms_grandfathered,
	):
		return invalid
	var expected_contract_id := "FM-%04d-%s" % [result_day, String(offer_id).to_upper()]
	if String(source.get("contract_id", "")) != expected_contract_id:
		return invalid
	for field in ["name", "short_name", "client"]:
		if String(source.get(field, "")) != String(authored.get(field, "")):
			return invalid
	for field in ["required_completed", "total_claims", "rush_claims"]:
		if (
			not _is_integral_number(source.get(field, null))
			or int(source.get(field, -1)) != int(authored.get(field, -2))
		):
			return invalid
	if typeof(source.get("success", null)) != TYPE_BOOL:
		return invalid
	var success := bool(source.get("success", false))
	var expected_status := "fulfilled" if success else "breached"
	if String(source.get("status", "")) != expected_status:
		return invalid
	for boolean_field in [
		"delivery_threshold_met", "welfare_gate_met", "welfare_gate_required",
	]:
		if typeof(source.get(boolean_field, null)) != TYPE_BOOL:
			return invalid
	var integer_fields := [
		"timely_sound_completed",
		"sound_completed",
		"completed_count",
		"rush_completed_on_time",
		"cracked_count",
		"late_count",
		"rejected_count",
		"required_active_staff",
		"closing_welfare",
		"base_premium_cents",
		"service_coop_level_at_signing",
		"service_coop_bonus_cents",
		"contracted_service_coop_bonus_cents",
		"premium_bonus_basis_points",
		"premium_cents",
		"breach_cents",
		"net_contract_cents",
		"fund_before_cents",
		"fund_after_cents",
		"market_standing_before",
		"market_standing_after",
		"market_standing_delta",
		"clean_contract_streak_before",
		"clean_contract_streak_after",
		"best_clean_contract_streak",
	]
	for field in integer_fields:
		if not _is_integral_number(source.get(field, null)):
			return invalid
	var total_claims := int(authored.get("total_claims", 0))
	var required := int(authored.get("required_completed", 0))
	var timely := int(source.get("timely_sound_completed", -1))
	var sound := int(source.get("sound_completed", -1))
	var completed := int(source.get("completed_count", -1))
	var rush_on_time := int(source.get("rush_completed_on_time", -1))
	var cracked := int(source.get("cracked_count", -1))
	var late := int(source.get("late_count", -1))
	var rejected := int(source.get("rejected_count", -1))
	var claim_ids_result := _validated_market_contract_id_array(source.get("claim_ids", null))
	var accepted_ids_result := _validated_market_contract_id_array(
		source.get("accepted_claim_ids", null)
	)
	var rejected_ids_result := _validated_market_contract_id_array(
		source.get("rejected_claim_ids", null)
	)
	if (
		not bool(claim_ids_result.get("valid", false))
		or not bool(accepted_ids_result.get("valid", false))
		or not bool(rejected_ids_result.get("valid", false))
	):
		return invalid
	var claim_ids := claim_ids_result.get("ids", []) as Array
	var accepted_ids := accepted_ids_result.get("ids", []) as Array
	var rejected_ids := rejected_ids_result.get("ids", []) as Array
	var derived_claim_ids: Array[int] = []
	var derived_accepted_ids: Array[int] = []
	var derived_rejected_ids: Array[int] = []
	var normalized_result_schedules: Array[Dictionary] = []
	var source_schedules := source.get("scheduled_claims", []) as Array
	var authored_schedules := authored.get("scheduled_claims", []) as Array
	for index in source_schedules.size():
		var schedule := source_schedules[index] as Dictionary
		var claim_id := int(schedule.get("claim_id", -1))
		derived_claim_ids.append(claim_id)
		if bool(schedule.get("released", false)):
			derived_accepted_ids.append(claim_id)
		elif bool(schedule.get("rejected", false)):
			derived_rejected_ids.append(claim_id)
		var normalized_schedule := (authored_schedules[index] as Dictionary).duplicate(true)
		normalized_schedule["claim_id"] = claim_id
		normalized_schedule["released"] = bool(schedule.get("released", false))
		normalized_schedule["rejected"] = bool(schedule.get("rejected", false))
		normalized_result_schedules.append(normalized_schedule)
	if (
		not _market_contract_same_id_order(claim_ids, derived_claim_ids)
		or not _market_contract_same_id_order(accepted_ids, derived_accepted_ids)
		or not _market_contract_same_id_order(rejected_ids, derived_rejected_ids)
	):
		return invalid
	var closing_welfare := int(source.get("closing_welfare", -1))
	var welfare_gate_minimum := int(authored.get("welfare_gate_minimum", 0))
	var delivery_threshold_met := timely >= required
	var welfare_gate_met := welfare_gate_minimum <= 0 or closing_welfare >= welfare_gate_minimum
	if (
		timely < 0 or timely > sound
		or sound < 0 or sound > completed
		or completed < 0 or completed > total_claims
		or sound + cracked != completed
		or cracked < 0
		or late != completed - timely
		or rush_on_time < 0 or rush_on_time > int(authored.get("rush_claims", 0))
		or rush_on_time > timely
		or rejected < 0 or rejected > total_claims
		or rejected != rejected_ids.size()
		or completed + rejected > total_claims
		or closing_welfare < 0 or closing_welfare > 100
		or bool(source.get("delivery_threshold_met", false)) != delivery_threshold_met
		or bool(source.get("welfare_gate_met", false)) != welfare_gate_met
		or bool(source.get("welfare_gate_required", false)) != (welfare_gate_minimum > 0)
		or success != (delivery_threshold_met and welfare_gate_met)
	):
		return invalid
	var authored_required_staff := int(authored.get("required_active_staff", 0))
	var required_active_staff := int(source.get("required_active_staff", -1))
	if (
		(legacy_terms_grandfathered and required_active_staff not in [0, authored_required_staff])
		or (not legacy_terms_grandfathered and required_active_staff != authored_required_staff)
	):
		return invalid
	var base_premium_cents := int((MARKET_CONTRACT_DEFINITIONS[offer_id] as Dictionary).get("premium_cents", -1))
	var contracted_service_bonus := _service_coop_premium_bonus_cents(
		base_premium_cents,
		service_coop_level_at_signing,
	)
	var expected_service_bonus := contracted_service_bonus if success else 0
	var expected_premium := int(authored.get("contracted_premium_cents", 0)) if success else 0
	var expected_breach := int(authored.get("contracted_breach_cents", 0)) if not success else 0
	var premium := int(source.get("premium_cents", -1))
	var breach := int(source.get("breach_cents", -1))
	var net := int(source.get("net_contract_cents", 0))
	var fund_before := int(source.get("fund_before_cents", -1))
	var fund_after := int(source.get("fund_after_cents", -1))
	if (
		int(source.get("base_premium_cents", -1)) != base_premium_cents
		or int(source.get("service_coop_bonus_cents", -1)) != expected_service_bonus
		or int(source.get("contracted_service_coop_bonus_cents", -1)) != contracted_service_bonus
		or int(source.get("premium_bonus_basis_points", -1))
		!= service_coop_level_at_signing * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		or premium != expected_premium
		or breach != expected_breach
		or net != premium - breach
		or fund_before < 0 or fund_before > 2_000_000_000
		or fund_after < 0 or fund_after > 2_000_000_000
		or fund_after != fund_before + net
		or int(source.get("market_standing_delta", 0))
		!= int(source.get("market_standing_after", 0)) - int(source.get("market_standing_before", 0))
		or int(source.get("clean_contract_streak_before", -1)) < 0
		or int(source.get("clean_contract_streak_after", -1)) < 0
		or int(source.get("best_clean_contract_streak", -1))
		< int(source.get("clean_contract_streak_after", 0))
		or StringName(source.get("market_standing_rank", &"")) not in [
			&"unlisted", &"bronze", &"silver", &"gold",
		]
		or String(source.get("outcome", "")).is_empty()
	):
		return invalid
	var normalized := {
		"version": 2,
		"contract_id": expected_contract_id,
		"offer_id": String(offer_id),
		"name": String(authored.get("name", "FARM MUTUAL BINDER")),
		"short_name": String(authored.get("short_name", "MUTUAL BINDER")),
		"client": String(authored.get("client", "FARM MUTUAL")),
		"day": result_day,
		"target_day": result_day,
		"status": expected_status,
		"success": success,
		"delivery_threshold_met": delivery_threshold_met,
		"welfare_gate_met": welfare_gate_met,
		"closing_welfare": closing_welfare,
		"welfare_gate_minimum": welfare_gate_minimum,
		"welfare_gate_required": welfare_gate_minimum > 0,
		"legacy_terms_grandfathered": legacy_terms_grandfathered,
		"required_completed": required,
		"timely_sound_completed": timely,
		"sound_completed": sound,
		"completed_count": completed,
		"total_claims": total_claims,
		"rush_claims": int(authored.get("rush_claims", 0)),
		"rush_completed_on_time": rush_on_time,
		"cracked_count": cracked,
		"late_count": late,
		"rejected_count": rejected,
		"scheduled_claims": normalized_result_schedules,
		"claim_ids": claim_ids.duplicate(),
		"accepted_claim_ids": accepted_ids.duplicate(),
		"rejected_claim_ids": rejected_ids.duplicate(),
		"required_active_staff": required_active_staff,
		"base_premium_cents": base_premium_cents,
		"service_coop_level_at_signing": service_coop_level_at_signing,
		"service_coop_bonus_cents": expected_service_bonus,
		"contracted_service_coop_bonus_cents": contracted_service_bonus,
		"premium_bonus_basis_points": (
			service_coop_level_at_signing * SERVICE_COOP_PREMIUM_BASIS_POINTS_PER_LEVEL
		),
		"premium_cents": premium,
		"breach_cents": breach,
		"net_contract_cents": net,
		"fund_before_cents": fund_before,
		"fund_after_cents": fund_after,
		"market_standing_before": int(source.get("market_standing_before", 0)),
		"market_standing_after": int(source.get("market_standing_after", 0)),
		"market_standing_delta": int(source.get("market_standing_delta", 0)),
		"market_standing_rank": String(source.get("market_standing_rank", "unlisted")),
		"clean_contract_streak_before": int(source.get("clean_contract_streak_before", 0)),
		"clean_contract_streak_after": int(source.get("clean_contract_streak_after", 0)),
		"best_clean_contract_streak": int(source.get("best_clean_contract_streak", 0)),
		"outcome": String(source.get("outcome", "")),
	}
	var authoritative_normalized := authored.duplicate(true)
	authoritative_normalized.merge(normalized, true)
	return {"valid": true, "record": authoritative_normalized}


func _validated_market_contract_decline_receipt(
	value: Variant,
	saved_day: int,
	saved_phase: int
) -> Dictionary:
	var invalid := {"valid": false, "record": {}}
	if not value is Dictionary:
		return invalid
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	if (
		saved_day < CONTRACT_BOARD_UNLOCK_DAY
		or saved_phase not in [
			ShiftPhase.REVIEW,
			ShiftPhase.AWAITING_DIRECTIVE,
			ShiftPhase.RUNNING,
			ShiftPhase.AWAITING_INCIDENT,
		]
		or not _is_integral_number(source.get("version", null))
		or int(source.get("version", 0)) != 1
		or typeof(source.get("accepted", null)) != TYPE_BOOL
		or not bool(source.get("accepted", false))
		or String(source.get("action_id", "")) != "decline_market_contract"
		or String(source.get("status", "")) != "declined"
	):
		return invalid
	for field in ["day", "target_day"]:
		if not _is_integral_number(source.get(field, null)) or int(source.get(field, 0)) != saved_day:
			return invalid
	var expected_outcome := "STANDARD BOOK FILED: no outside Farm Mutual binder will arrive on Day %d." % saved_day
	if String(source.get("outcome", "")) != expected_outcome:
		return invalid
	return {
		"valid": true,
		"record": {
			"version": 1,
			"accepted": true,
			"action_id": "decline_market_contract",
			"status": "declined",
			"day": saved_day,
			"target_day": saved_day,
			"outcome": expected_outcome,
		},
	}


func _validated_upgrade_levels(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var source := value as Dictionary
	if source.size() != UPGRADE_ORDER.size():
		return {}
	var restored: Dictionary = {}
	for key_value in source:
		var upgrade_id := StringName(String(key_value))
		if upgrade_id not in UPGRADE_ORDER or restored.has(upgrade_id):
			return {}
		var level_value: Variant = source[key_value]
		if not _is_integral_number(level_value):
			return {}
		var level := int(level_value)
		if level < 0 or level > MAX_UPGRADE_LEVEL:
			return {}
		restored[upgrade_id] = level
	return restored


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


func _cumulative_upgrade_spend_cents(levels: Dictionary) -> int:
	var total := 0
	for upgrade_id in UPGRADE_ORDER:
		var level := clampi(int(levels.get(upgrade_id, 0)), 0, MAX_UPGRADE_LEVEL)
		for level_before in level:
			total += _upgrade_list_cost_for_level(upgrade_id, level_before)
	return total


func _validated_first_clutch_reinvestment(
	value: Variant,
	saved_day: int,
	restored_upgrade_levels: Dictionary
) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	if source.is_empty():
		return {"valid": true, "record": {}}
	for integer_field in [
		"version", "trigger_day", "trigger_worker_id", "trigger_claim_id",
		"created_value_cents", "fund_at_collection_cents", "protected_reserve_cents",
		"spendable_at_collection_cents", "procurement_match_available_cents",
		"resolved_day", "selected_level", "selected_list_cost_cents",
		"procurement_match_used_cents", "net_cost_cents",
		"fund_before_resolution_cents", "spendable_before_resolution_cents",
		"fund_after_cents", "spendable_after_cents",
	]:
		if not _is_integral_number(source.get(integer_field, null)):
			return {"valid": false, "record": {}}
	for text_field in [
		"status", "trigger_worker_name", "trigger_quality", "choice_id",
	]:
		if typeof(source.get(text_field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	var options_value: Variant = source.get("offered_options", null)
	if not options_value is Array:
		return {"valid": false, "record": {}}
	var version := int(source.get("version", -1))
	var status := StringName(String(source.get("status", "")))
	var trigger_day := int(source.get("trigger_day", -1))
	var worker_id := int(source.get("trigger_worker_id", -1))
	var claim_id := int(source.get("trigger_claim_id", -1))
	var quality := StringName(String(source.get("trigger_quality", "")))
	var created_value := int(source.get("created_value_cents", -1))
	var fund_at_collection := int(source.get("fund_at_collection_cents", -1))
	var protected_reserve := int(source.get("protected_reserve_cents", -1))
	var spendable_at_collection := int(source.get("spendable_at_collection_cents", -1))
	var match_available := int(source.get("procurement_match_available_cents", -1))
	if (
		version != FIRST_CLUTCH_REINVESTMENT_VERSION
		or status not in [&"offered", &"purchased", &"banked"]
		or trigger_day < 1 or trigger_day > saved_day
		or worker_id != FIRST_CLUTCH_WORKER_ID
		or String(source.get("trigger_worker_name", "")) != WORKER_NAMES[FIRST_CLUTCH_WORKER_ID]
		or claim_id < 1
		or quality not in [&"sound", &"golden", &"cracked"]
		or created_value < 1 or created_value > 2_000_000_000
		or fund_at_collection < 0 or fund_at_collection > 2_000_000_000
		or protected_reserve < 0 or protected_reserve > 4_000_000_000
		or spendable_at_collection != maxi(0, fund_at_collection - protected_reserve)
		or match_available < 0
		or match_available > ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS
	):
		return {"valid": false, "record": {}}

	var normalized_options: Array[Dictionary] = []
	var seen_options: Dictionary[StringName, bool] = {}
	var last_order_index := -1
	var highest_list_cost := 0
	for option_value in (options_value as Array):
		if not option_value is Dictionary:
			return {"valid": false, "record": {}}
		var option := option_value as Dictionary
		for integer_field in ["level_before", "next_level", "list_cost_cents"]:
			if not _is_integral_number(option.get(integer_field, null)):
				return {"valid": false, "record": {}}
		if typeof(option.get("id", null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
		var upgrade_id := StringName(String(option.get("id", "")))
		var order_index := UPGRADE_ORDER.find(upgrade_id)
		var level_before := int(option.get("level_before", -1))
		var next_level := int(option.get("next_level", -1))
		var list_cost := int(option.get("list_cost_cents", -1))
		if (
			order_index < 0 or order_index <= last_order_index
			or seen_options.has(upgrade_id)
			or level_before < 0 or level_before >= MAX_UPGRADE_LEVEL
			or next_level != level_before + 1
			or list_cost != _upgrade_list_cost_for_level(upgrade_id, level_before)
			or int(restored_upgrade_levels.get(upgrade_id, -1)) < level_before
		):
			return {"valid": false, "record": {}}
		last_order_index = order_index
		seen_options[upgrade_id] = true
		highest_list_cost = maxi(highest_list_cost, list_cost)
		normalized_options.append({
			"id": String(upgrade_id),
			"level_before": level_before,
			"next_level": next_level,
			"list_cost_cents": list_cost,
		})
	if normalized_options.size() > FIRST_CLUTCH_REINVESTMENT_OFFER_LIMIT:
		return {"valid": false, "record": {}}
	var expected_match := mini(
		ORIENTATION_PROCUREMENT_MATCH_CAP_CENTS,
		maxi(0, highest_list_cost - spendable_at_collection),
	)
	if match_available != expected_match:
		return {"valid": false, "record": {}}

	var choice_id := StringName(String(source.get("choice_id", "")))
	var resolved_day := int(source.get("resolved_day", -1))
	var selected_level := int(source.get("selected_level", -1))
	var selected_list_cost := int(source.get("selected_list_cost_cents", -1))
	var match_used := int(source.get("procurement_match_used_cents", -1))
	var net_cost := int(source.get("net_cost_cents", -1))
	var fund_before := int(source.get("fund_before_resolution_cents", -1))
	var spendable_before := int(source.get("spendable_before_resolution_cents", -1))
	var fund_after := int(source.get("fund_after_cents", -1))
	var spendable_after := int(source.get("spendable_after_cents", -1))
	if status == &"offered":
		if (
			choice_id != &"" or resolved_day != 0 or selected_level != 0
			or selected_list_cost != 0 or match_used != 0 or net_cost != 0
			or fund_before != 0 or spendable_before != 0
			or fund_after != fund_at_collection
			or spendable_after != spendable_at_collection
		):
			return {"valid": false, "record": {}}
		for option in normalized_options:
			var offered_id := StringName(option.get("id", ""))
			if int(restored_upgrade_levels.get(offered_id, -1)) != int(option["level_before"]):
				return {"valid": false, "record": {}}
	elif status == &"banked":
		if (
			choice_id != FIRST_CLUTCH_BANK_CHOICE_ID
			or resolved_day < trigger_day or resolved_day > saved_day
			or selected_level != 0 or selected_list_cost != 0 or match_used != 0 or net_cost != 0
			or fund_before < 0 or fund_before > 2_000_000_000
			or spendable_before < 0 or spendable_before > fund_before
			or fund_after != fund_before or spendable_after != spendable_before
		):
			return {"valid": false, "record": {}}
	else:
		var selected_option: Dictionary = {}
		for option in normalized_options:
			if StringName(option.get("id", "")) == choice_id:
				selected_option = option
				break
		if selected_option.is_empty():
			return {"valid": false, "record": {}}
		var expected_level := int(selected_option["next_level"])
		var expected_list_cost := int(selected_option["list_cost_cents"])
		var expected_match_used := mini(match_available, expected_list_cost)
		var expected_net_cost := expected_list_cost - expected_match_used
		if (
			resolved_day < trigger_day or resolved_day > saved_day
			or selected_level != expected_level
			or selected_list_cost != expected_list_cost
			or match_used != expected_match_used
			or net_cost != expected_net_cost
			or fund_before < net_cost or fund_before > 2_000_000_000
			or spendable_before < net_cost or spendable_before > fund_before
			or fund_after != fund_before - net_cost
			or spendable_after != spendable_before - net_cost
			or int(restored_upgrade_levels.get(choice_id, -1)) < selected_level
		):
			return {"valid": false, "record": {}}

	var normalized := source.duplicate(true)
	normalized["status"] = String(status)
	normalized["trigger_quality"] = String(quality)
	normalized["choice_id"] = String(choice_id)
	normalized["offered_options"] = normalized_options
	return {"valid": true, "record": normalized}


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


func _is_valid_shift_decision_tuple(
	saved_shift_phase: int,
	saved_active_directive: StringName,
	saved_pending_decision: Dictionary,
) -> bool:
	var pending_kind := StringName(saved_pending_decision.get("kind", &""))
	var pending_id := StringName(saved_pending_decision.get("id", &""))
	match saved_shift_phase:
		ShiftPhase.AWAITING_DIRECTIVE:
			return (
				saved_active_directive == &""
				and pending_kind == &"directive"
				and pending_id == &"morning_directive"
			)
		ShiftPhase.RUNNING:
			return (
				DIRECTIVE_DEFINITIONS.has(saved_active_directive)
				and saved_pending_decision.is_empty()
			)
		ShiftPhase.AWAITING_INCIDENT:
			return (
				DIRECTIVE_DEFINITIONS.has(saved_active_directive)
				and pending_kind == &"incident"
				and (
					INCIDENT_DEFINITIONS.has(pending_id)
					or pending_id == FLOCK_PETITION_INCIDENT_ID
				)
			)
		ShiftPhase.REVIEW:
			return (
				saved_active_directive == &""
				and (
					saved_pending_decision.is_empty()
					or pending_kind in [&"credit_allocation", &"major_event"]
				)
			)
	return false


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


func _string_array_matches(value: Variant, expected: Variant) -> bool:
	if not value is Array or not expected is Array:
		return false
	var source := value as Array
	var target := expected as Array
	if source.size() != target.size():
		return false
	for index in source.size():
		if String(source[index]) != String(target[index]):
			return false
	return true


func _validated_campus_expansion_receipt(
	value: Variant,
	saved_day: int,
	expected_receipt_id: int,
	replay_state: Dictionary,
) -> Dictionary:
	if not value is Dictionary:
		return {}
	var receipt := value as Dictionary
	if not _dictionary_has_exact_keys(receipt, CAMPUS_EXPANSION_RECEIPT_KEYS):
		return {}
	if typeof(receipt.get("accepted", null)) != TYPE_BOOL or not bool(receipt["accepted"]):
		return {}
	for key in [
		"receipt_id", "day", "cost_cents", "added_daily_cost_cents", "fund_before_cents",
		"fund_after_cents", "daily_cost_before_cents", "daily_cost_after_cents",
		"claim_capacity_bonus_before", "claim_capacity_bonus_after",
		"farmgate_capacity_bonus_before", "farmgate_capacity_bonus_after",
		"access_standing_points", "access_farmgate_level",
	]:
		if not _is_integral_number(receipt.get(key, null)):
			return {}
	for key in ["action_id", "item_id", "socket_id", "from_socket_id", "access_gate_id"]:
		if typeof(receipt.get(key, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {}
	if typeof(receipt.get("reason", null)) != TYPE_STRING or typeof(receipt.get("outcome", null)) != TYPE_STRING:
		return {}
	var action_id := StringName(String(receipt["action_id"]))
	var item_id := StringName(String(receipt["item_id"]))
	var socket_id := StringName(String(receipt["socket_id"]))
	var from_socket_id := StringName(String(receipt["from_socket_id"]))
	var access_gate_id := StringName(String(receipt["access_gate_id"]))
	var terms := _campus_action_terms(action_id, item_id)
	if terms.is_empty() or not _campus_state_action_reason(
		replay_state,
		action_id,
		item_id,
		socket_id,
	).is_empty():
		return {}
	if action_id in [&"purchase_parcel", &"commission_service"] and socket_id != &"":
		return {}
	var receipt_day := int(receipt["day"])
	var expected_from_socket := StringName(String(replay_state.get("pod_socket_id", "")))
	var cost_cents := int(terms["cost_cents"])
	var added_daily_cost_cents := int(terms["added_daily_cost_cents"])
	var daily_before := _campus_daily_cost_for_state(replay_state)
	var claim_bonus_before := _campus_claim_capacity_bonus_for_state(replay_state)
	# Receipt capacity effects are facility-independent campus bonuses. A Depot
	# may be commissioned later without rewriting this immutable campus history.
	var farmgate_bonus_before := (
		CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if _campus_cold_chain_active_for_state(replay_state) else
		0
	)
	var preview_state := replay_state.duplicate(true)
	_apply_campus_action_to_state(preview_state, action_id, item_id, socket_id)
	var claim_bonus_after := _campus_claim_capacity_bonus_for_state(preview_state)
	var farmgate_bonus_after := (
		CAMPUS_FARMGATE_STORAGE_BONUS_EGGS
		if _campus_cold_chain_active_for_state(preview_state) else
		0
	)
	var fund_before := int(receipt["fund_before_cents"])
	var access_standing := int(receipt["access_standing_points"])
	var access_farmgate := int(receipt["access_farmgate_level"])
	if (
		int(receipt["receipt_id"]) != expected_receipt_id
		or receipt_day < CAMPUS_EXPANSION_UNLOCK_DAY or receipt_day > saved_day
		or int(receipt["cost_cents"]) != cost_cents
		or int(receipt["added_daily_cost_cents"]) != added_daily_cost_cents
		or fund_before < cost_cents or fund_before > 2_000_000_000
		or int(receipt["fund_after_cents"]) != fund_before - cost_cents
		or int(receipt["fund_after_cents"]) < 0
		or int(receipt["daily_cost_before_cents"]) != daily_before
		or int(receipt["daily_cost_after_cents"]) != _campus_daily_cost_for_state(preview_state)
		or int(receipt["claim_capacity_bonus_before"]) != claim_bonus_before
		or int(receipt["claim_capacity_bonus_after"]) != claim_bonus_after
		or int(receipt["farmgate_capacity_bonus_before"]) != farmgate_bonus_before
		or int(receipt["farmgate_capacity_bonus_after"]) != farmgate_bonus_after
		or from_socket_id != expected_from_socket
		or not String(receipt["reason"]).is_empty()
		or String(receipt["outcome"]) != _campus_action_outcome(
			action_id,
			item_id,
			from_socket_id,
			socket_id,
		)
	):
		return {}
	if action_id == &"purchase_parcel":
		if (
			access_standing < 0
			or access_farmgate < 0 or access_farmgate > 3
			or (
				access_gate_id == &"farmgate_dispatch"
				and access_farmgate < 1
			)
			or (
				access_gate_id == &"farm_mutual_standing"
				and (
					access_standing < CAMPUS_EXPANSION_STANDING_REQUIREMENT
					or access_farmgate != 0
				)
			)
			or access_gate_id not in [&"farmgate_dispatch", &"farm_mutual_standing"]
		):
			return {}
	elif access_gate_id != &"" or access_standing != 0 or access_farmgate != 0:
		return {}
	var normalized := receipt.duplicate(true)
	normalized["action_id"] = action_id
	normalized["item_id"] = item_id
	normalized["socket_id"] = socket_id
	normalized["from_socket_id"] = from_socket_id
	normalized["access_gate_id"] = access_gate_id
	for key in [
		"receipt_id", "day", "cost_cents", "added_daily_cost_cents", "fund_before_cents",
		"fund_after_cents", "daily_cost_before_cents", "daily_cost_after_cents",
		"claim_capacity_bonus_before", "claim_capacity_bonus_after",
		"farmgate_capacity_bonus_before", "farmgate_capacity_bonus_after",
		"access_standing_points", "access_farmgate_level",
	]:
		normalized[key] = int(normalized[key])
	return normalized


func _validated_campus_expansion_state(value: Variant, saved_day: int) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false}
	var source := value as Dictionary
	if not _dictionary_has_exact_keys(source, CAMPUS_EXPANSION_SAVE_KEYS):
		return {"valid": false}
	if (
		not _is_integral_number(source.get("version", null))
		or int(source["version"]) != CAMPUS_EXPANSION_SAVE_VERSION
		or typeof(source.get("parcel_owned", null)) != TYPE_BOOL
		or typeof(source.get("pod_owned", null)) != TYPE_BOOL
		or typeof(source.get("pod_socket_id", null)) not in [TYPE_STRING, TYPE_STRING_NAME]
		or not _is_integral_number(source.get("capital_spend_total_cents", null))
		or not _is_integral_number(source.get("next_receipt_id", null))
		or not source.get("last_receipt", null) is Dictionary
		or not source.get("history", null) is Array
	):
		return {"valid": false}
	var services_value: Variant = source.get("services", null)
	if not services_value is Dictionary:
		return {"valid": false}
	var services_source := services_value as Dictionary
	if services_source.size() != CAMPUS_SERVICE_ORDER.size():
		return {"valid": false}
	var normalized_services: Dictionary = {}
	for raw_service_id in services_source:
		var service_id := StringName(String(raw_service_id))
		if (
			service_id not in CAMPUS_SERVICE_ORDER
			or normalized_services.has(String(service_id))
			or typeof(services_source[raw_service_id]) != TYPE_BOOL
		):
			return {"valid": false}
		normalized_services[String(service_id)] = bool(services_source[raw_service_id])
	var history_source := source["history"] as Array
	if history_source.size() > CAMPUS_EXPANSION_HISTORY_LIMIT:
		return {"valid": false}
	var replay_state := _neutral_campus_expansion_state()
	var normalized_history: Array[Dictionary] = []
	var previous_day := 0
	var accumulated_spend := 0
	for index in history_source.size():
		var receipt := _validated_campus_expansion_receipt(
			history_source[index],
			saved_day,
			index + 1,
			replay_state,
		)
		if receipt.is_empty() or int(receipt["day"]) < previous_day:
			return {"valid": false}
		previous_day = int(receipt["day"])
		accumulated_spend += int(receipt["cost_cents"])
		_apply_campus_action_to_state(
			replay_state,
			StringName(receipt["action_id"]),
			StringName(receipt["item_id"]),
			StringName(receipt["socket_id"]),
		)
		normalized_history.append(receipt)
	var pod_socket_id := StringName(String(source["pod_socket_id"]))
	if (
		bool(source["parcel_owned"]) != bool(replay_state["parcel_owned"])
		or normalized_services != _campus_services_for_state(replay_state)
		or bool(source["pod_owned"]) != bool(replay_state["pod_owned"])
		or pod_socket_id != StringName(String(replay_state["pod_socket_id"]))
		or int(source["capital_spend_total_cents"]) != accumulated_spend
		or int(source["next_receipt_id"]) != normalized_history.size() + 1
	):
		return {"valid": false}
	var last_source := source["last_receipt"] as Dictionary
	var normalized_last: Dictionary = {}
	if normalized_history.is_empty():
		if not last_source.is_empty():
			return {"valid": false}
	else:
		normalized_last = _validated_campus_expansion_receipt(
			last_source,
			saved_day,
			normalized_history.size(),
			_campus_replay_state_before_last(normalized_history),
		)
		if normalized_last.is_empty() or normalized_last != normalized_history[normalized_history.size() - 1]:
			return {"valid": false}
	var normalized_state := {
		"version": CAMPUS_EXPANSION_SAVE_VERSION,
		"parcel_owned": bool(source["parcel_owned"]),
		"services": normalized_services,
		"pod_owned": bool(source["pod_owned"]),
		"pod_socket_id": String(pod_socket_id),
		"capital_spend_total_cents": accumulated_spend,
		"next_receipt_id": normalized_history.size() + 1,
		"last_receipt": normalized_last,
		"history": normalized_history,
	}
	return {"valid": true, "state": normalized_state}


func _campus_replay_state_before_last(history: Array[Dictionary]) -> Dictionary:
	var state := _neutral_campus_expansion_state()
	for index in maxi(0, history.size() - 1):
		var receipt := history[index] as Dictionary
		_apply_campus_action_to_state(
			state,
			StringName(receipt["action_id"]),
			StringName(receipt["item_id"]),
			StringName(receipt["socket_id"]),
		)
	return state


func _validated_facility_purchase_receipt(
	value: Variant,
	saved_day: int,
	restored_owned_facilities: Dictionary,
) -> Dictionary:
	if not value is Dictionary:
		return {}
	var receipt := value as Dictionary
	if not _dictionary_has_exact_keys(receipt, FACILITY_PURCHASE_RECEIPT_KEYS):
		return {}
	if typeof(receipt.get("accepted")) != TYPE_BOOL or not bool(receipt["accepted"]):
		return {}
	if StringName(receipt.get("action_id", &"")) != &"purchase_facility":
		return {}
	var facility_id := StringName(receipt.get("facility_id", &""))
	if not FACILITY_DEFINITIONS.has(facility_id):
		return {}
	for key in [
		"day", "purchased_level", "max_level", "cost_cents", "fund_before_cents",
		"fund_after_cents", "spendable_before_cents", "spendable_after_cents",
		"protected_reserve_before_cents", "protected_reserve_after_cents",
		"upkeep_before_cents", "upkeep_after_cents", "upkeep_delta_cents",
	]:
		if not _is_integral_number(receipt.get(key, null)):
			return {}
	var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
	var purchased_level := int(receipt["purchased_level"])
	var max_level := int(definition.get("max_level", 1))
	var day_value := int(receipt["day"])
	var expected_cost := _facility_cost_for_level(definition, purchased_level)
	var expected_upkeep_before := _facility_maintenance_for_level(definition, purchased_level - 1)
	var expected_upkeep_after := _facility_maintenance_for_level(definition, purchased_level)
	var expected_supervisor_delta := 0
	if facility_id == ROOSTER_OPERATIONS_OFFICE_ID:
		expected_supervisor_delta = (
			_facility_level_schedule_value(ROOSTER_SUPERVISOR_PAYROLL_CENTS, purchased_level, 0)
			- _facility_level_schedule_value(ROOSTER_SUPERVISOR_PAYROLL_CENTS, purchased_level - 1, 0)
		)
	var fund_before := int(receipt["fund_before_cents"])
	var fund_after := int(receipt["fund_after_cents"])
	var reserve_before := int(receipt["protected_reserve_before_cents"])
	var reserve_after := int(receipt["protected_reserve_after_cents"])
	var effect_value: Variant = receipt.get("effect", null)
	if not effect_value is Dictionary:
		return {}
	var effect := effect_value as Dictionary
	if not _dictionary_has_exact_keys(effect, FACILITY_PURCHASE_EFFECT_KEYS):
		return {}
	for effect_key in ["storage_capacity_eggs", "dispatch_capacity_eggs", "shelf_life_shifts"]:
		if not _is_integral_number(effect.get(effect_key, null)):
			return {}
	if (
		purchased_level < 1 or purchased_level > max_level
		or purchased_level > int(restored_owned_facilities.get(facility_id, 0))
		or day_value < 1 or day_value > saved_day
		or String(receipt.get("facility_name", "")) != String(definition.get("name", ""))
		or String(receipt.get("level_name", "")) != _facility_level_name(definition, purchased_level)
		or int(receipt["max_level"]) != max_level
		or int(receipt["cost_cents"]) != expected_cost
		or fund_before < expected_cost or fund_before > 2_000_000_000
		or fund_after != fund_before - expected_cost
		or reserve_before < 0 or reserve_before > 2_000_000_000
		or reserve_after != reserve_before + (expected_upkeep_after - expected_upkeep_before) + expected_supervisor_delta
		or int(receipt["spendable_before_cents"]) != maxi(0, fund_before - reserve_before)
		or int(receipt["spendable_after_cents"]) != maxi(0, fund_after - reserve_after)
		or int(receipt["upkeep_before_cents"]) < expected_upkeep_before
		or int(receipt["upkeep_after_cents"]) != int(receipt["upkeep_before_cents"]) + expected_upkeep_after - expected_upkeep_before
		or int(receipt["upkeep_delta_cents"]) != expected_upkeep_after - expected_upkeep_before
		or not _string_array_matches(effect.get("benefits", null), definition.get("benefits", null))
		or not _string_array_matches(effect.get("tradeoffs", null), definition.get("tradeoffs", null))
		or int(effect.get("storage_capacity_eggs", -1)) != int(_facility_purchase_effect_copy(facility_id, purchased_level)["storage_capacity_eggs"])
		or int(effect.get("dispatch_capacity_eggs", -1)) != int(_facility_purchase_effect_copy(facility_id, purchased_level)["dispatch_capacity_eggs"])
		or int(effect.get("shelf_life_shifts", -1)) != int(_facility_purchase_effect_copy(facility_id, purchased_level)["shelf_life_shifts"])
	):
		return {}
	var normalized := receipt.duplicate(true)
	normalized["action_id"] = &"purchase_facility"
	normalized["facility_id"] = facility_id
	for key in [
		"day", "purchased_level", "max_level", "cost_cents", "fund_before_cents",
		"fund_after_cents", "spendable_before_cents", "spendable_after_cents",
		"protected_reserve_before_cents", "protected_reserve_after_cents",
		"upkeep_before_cents", "upkeep_after_cents", "upkeep_delta_cents",
	]:
		normalized[key] = int(normalized.get(key, 0))
	var normalized_effect := (normalized.get("effect", {}) as Dictionary).duplicate(true)
	for key in ["storage_capacity_eggs", "dispatch_capacity_eggs", "shelf_life_shifts"]:
		normalized_effect[key] = int(normalized_effect.get(key, 0))
	normalized["effect"] = normalized_effect
	return normalized


func _validated_capital_records(
	pinned_value: Variant,
	last_value: Variant,
	history_value: Variant,
	saved_day: int,
	restored_owned_facilities: Dictionary,
) -> Dictionary:
	if typeof(pinned_value) not in [TYPE_STRING, TYPE_STRING_NAME]:
		return {"valid": false}
	var pinned_id := StringName(String(pinned_value))
	if pinned_id != &"":
		if not FACILITY_DEFINITIONS.has(pinned_id):
			return {"valid": false}
		var pinned_definition := FACILITY_DEFINITIONS[pinned_id] as Dictionary
		if int(restored_owned_facilities.get(pinned_id, 0)) >= int(pinned_definition.get("max_level", 1)):
			return {"valid": false}
	if not last_value is Dictionary or not history_value is Array:
		return {"valid": false}
	var history_source := history_value as Array
	if history_source.size() > FARMGATE_COMMISSIONING_HISTORY_LIMIT:
		return {"valid": false}
	var restored_history: Array[Dictionary] = []
	var previous_day := 0
	var previous_level_by_facility: Dictionary = {}
	for raw_receipt in history_source:
		var receipt := _validated_facility_purchase_receipt(
			raw_receipt,
			saved_day,
			restored_owned_facilities,
		)
		if receipt.is_empty():
			return {"valid": false}
		var receipt_day := int(receipt["day"])
		var facility_id := StringName(receipt["facility_id"])
		var purchased_level := int(receipt["purchased_level"])
		if receipt_day < previous_day or purchased_level <= int(previous_level_by_facility.get(facility_id, 0)):
			return {"valid": false}
		previous_day = receipt_day
		previous_level_by_facility[facility_id] = purchased_level
		restored_history.append(receipt)
	var last_source := last_value as Dictionary
	var restored_last: Dictionary = {}
	if restored_history.is_empty():
		if not last_source.is_empty():
			return {"valid": false}
	else:
		restored_last = _validated_facility_purchase_receipt(
			last_source,
			saved_day,
			restored_owned_facilities,
		)
		if restored_last.is_empty() or restored_last != restored_history[restored_history.size() - 1]:
			return {"valid": false}
	return {
		"valid": true,
		"pinned_id": pinned_id,
		"last": restored_last,
		"history": restored_history,
	}


func _validated_manager_roster(value: Variant, rooster_office_level: int) -> Array[Dictionary]:
	var invalid: Array[Dictionary] = []
	if not value is Array:
		return invalid
	var source := value as Array
	var expected_count := clampi(rooster_office_level + 1, 1, 4)
	if source.size() != expected_count:
		return invalid
	var result: Array[Dictionary] = []
	var seen_ids: Dictionary[StringName, bool] = {}
	for slot_index in source.size():
		var row_value: Variant = source[slot_index]
		if not row_value is Dictionary:
			return invalid
		var row := (row_value as Dictionary).duplicate(true)
		var candidate_id := StringName(String(row.get("candidate_id", row.get("id", ""))))
		var assignment_id := StringName(String(row.get("assignment_id", "")))
		var posture_id := StringName(String(row.get("posture_id", "")))
		if (
			not MANAGER_CANDIDATE_DEFINITIONS.has(candidate_id)
			or seen_ids.has(candidate_id)
			or assignment_id not in MANAGER_ASSIGNMENT_ORDER
			or posture_id not in MANAGER_POSTURE_ORDER
			or not _is_integral_number(row.get("slot_index", null))
			or int(row.get("slot_index", -1)) != slot_index
			or typeof(row.get("posture_filed", null)) != TYPE_BOOL
		):
			return invalid
		for integer_field in ["hired_day", "influence", "rank", "credit_claims", "interventions", "last_pip_worker_id"]:
			if not _is_integral_number(row.get(integer_field, null)):
				return invalid
		var influence := int(row.get("influence", -1))
		var rank := int(row.get("rank", -1))
		if (
			int(row.get("hired_day", 0)) < 1
			or influence < 0 or influence > 2_000_000_000
			or rank != _manager_rank_for_influence(influence)
			or int(row.get("credit_claims", -1)) < 0
			or int(row.get("interventions", -1)) < 0
			or int(row.get("last_pip_worker_id", -2)) < -1
			or int(row.get("last_pip_worker_id", -2)) >= workers.size()
		):
			return invalid
		seen_ids[candidate_id] = true
		row["id"] = String(candidate_id)
		row["candidate_id"] = String(candidate_id)
		row["assignment_id"] = String(assignment_id)
		row["posture_id"] = String(posture_id)
		result.append(row)
	return result


func _validated_owned_facilities(value: Variant) -> Dictionary:
	## The current schema requires exactly one integral level for every known facility.
	## Rejecting unknown, missing, duplicate-normalized, and out-of-range entries
	## keeps authored effects deterministic after a JSON round trip.
	if not value is Dictionary:
		return {}
	var source := value as Dictionary
	if source.size() != FACILITY_ORDER.size():
		return {}
	var normalized: Dictionary = {}
	for raw_id in source:
		var facility_id := StringName(String(raw_id))
		if not FACILITY_DEFINITIONS.has(facility_id) or normalized.has(facility_id):
			return {}
		var level_value: Variant = source[raw_id]
		if not _is_integral_number(level_value):
			return {}
		var definition := FACILITY_DEFINITIONS[facility_id] as Dictionary
		var level := int(level_value)
		if level < 0 or level > int(definition.get("max_level", 1)):
			return {}
		normalized[facility_id] = level
	if normalized.size() != FACILITY_ORDER.size():
		return {}
	return normalized


func _dictionary_has_exact_keys(source: Dictionary, keys: Array[String]) -> bool:
	if source.size() != keys.size():
		return false
	for key in keys:
		if not source.has(key):
			return false
	return true


func _validated_flock_relations_resolution(
	value: Variant,
	saved_day: int,
	facility_level_value: int,
	restored_workers: Array[ChickenState],
) -> Dictionary:
	if not value is Dictionary:
		return {"valid": false, "record": {}}
	var source := value as Dictionary
	var required_keys: Array[String] = [
		"case_id", "worker_id", "worker_name", "type", "title", "severity",
		"filed_day", "resolved_day", "action_id", "action_label", "cost_cents", "outcome",
	]
	if not _dictionary_has_exact_keys(source, required_keys):
		return {"valid": false, "record": {}}
	for field in ["case_id", "worker_id", "severity", "filed_day", "resolved_day", "cost_cents"]:
		if not _is_integral_number(source.get(field, null)):
			return {"valid": false, "record": {}}
	for field in ["worker_name", "type", "title", "action_id", "action_label", "outcome"]:
		if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
			return {"valid": false, "record": {}}
	var case_id := int(source.get("case_id", 0))
	var worker_id := int(source.get("worker_id", -1))
	var severity := int(source.get("severity", 0))
	var filed_day := int(source.get("filed_day", 0))
	var resolved_day := int(source.get("resolved_day", 0))
	var case_type := StringName(String(source.get("type", "")))
	var action_id := StringName(String(source.get("action_id", "")))
	if (
		case_id < 1
		or worker_id < 0 or worker_id >= restored_workers.size()
		or severity < 1 or severity > 3
		or filed_day < 1 or filed_day > resolved_day
		or resolved_day < 1 or resolved_day > saved_day
		or case_type not in FLOCK_RELATIONS_CASE_TYPES
		or not FLOCK_RELATIONS_ACTION_DEFINITIONS.has(action_id)
	):
		return {"valid": false, "record": {}}
	var worker := restored_workers[worker_id]
	var definition := FLOCK_RELATIONS_ACTION_DEFINITIONS[action_id] as Dictionary
	var expected_label := String(definition.get("label", ""))
	var expected_cost := _flock_relations_action_cost_cents(action_id, severity)
	var title := _flock_relations_case_title(case_type)
	var expected_outcome := "%s closed %s's %s file for $%.2f." % [
		expected_label.capitalize(),
		worker.display_name,
		title.to_lower(),
		float(expected_cost) / 100.0,
	]
	if (
		String(source.get("worker_name", "")) != worker.display_name
		or String(source.get("title", "")) != title
		or int(source.get("cost_cents", -1)) != expected_cost
		or String(source.get("action_label", "")) != expected_label
		or String(source.get("outcome", "")) != expected_outcome
		or facility_level_value < int(definition.get("required_level", 0))
	):
		return {"valid": false, "record": {}}
	return {
		"valid": true,
		"record": {
			"case_id": case_id,
			"worker_id": worker_id,
			"worker_name": worker.display_name,
			"type": case_type,
			"title": title,
			"severity": severity,
			"filed_day": filed_day,
			"resolved_day": resolved_day,
			"action_id": action_id,
			"action_label": expected_label,
			"cost_cents": expected_cost,
			"outcome": expected_outcome,
		},
	}


func _validated_flock_relations_state(
	data: Dictionary,
	saved_day: int,
	facility_level_value: int,
	restored_workers: Array[ChickenState],
) -> Dictionary:
	for field in [
		"flock_relations_resolutions_used_today",
		"flock_relations_resolved_total",
		"flock_relations_denied_total",
		"flock_relations_settlement_spend_total_cents",
		"next_flock_relations_case_id",
	]:
		if not _is_integral_number(data.get(field, null)):
			return {"valid": false}
	var open_value: Variant = data.get("flock_relations_open_cases", null)
	var last_value: Variant = data.get("last_flock_relations_resolution", null)
	var history_value: Variant = data.get("flock_relations_resolution_history", null)
	if not open_value is Array or not last_value is Dictionary or not history_value is Array:
		return {"valid": false}
	var resolution_limit := _facility_level_schedule_value(
		FLOCK_RELATIONS_RESOLUTION_LIMITS,
		facility_level_value,
		0,
	)
	var case_capacity := _facility_level_schedule_value(
		FLOCK_RELATIONS_CASE_CAPACITY,
		facility_level_value,
		0,
	)
	var resolutions_used := int(data.get("flock_relations_resolutions_used_today", -1))
	var resolved_total := int(data.get("flock_relations_resolved_total", -1))
	var denied_total := int(data.get("flock_relations_denied_total", -1))
	var spend_total := int(data.get("flock_relations_settlement_spend_total_cents", -1))
	var next_case_id := int(data.get("next_flock_relations_case_id", 0))
	if (
		resolutions_used < 0 or resolutions_used > resolution_limit
		or resolved_total < 0 or resolved_total > 2_000_000_000
		or denied_total < 0 or denied_total > resolved_total
		or spend_total < 0 or spend_total > 2_000_000_000
		or next_case_id < 1 or next_case_id > 2_000_000_000
		or (open_value as Array).size() > case_capacity
		or (history_value as Array).size() > FLOCK_RELATIONS_HISTORY_LIMIT
	):
		return {"valid": false}
	var open_cases: Array[Dictionary] = []
	var seen_case_ids: Dictionary[int, bool] = {}
	var seen_worker_ids: Dictionary[int, bool] = {}
	for case_value in (open_value as Array):
		if not case_value is Dictionary:
			return {"valid": false}
		var source := case_value as Dictionary
		var case_keys: Array[String] = [
			"case_id", "worker_id", "worker_name", "type", "title", "severity",
			"filed_day", "status", "evidence", "risk_score", "last_carry_day",
		]
		if not _dictionary_has_exact_keys(source, case_keys):
			return {"valid": false}
		for field in ["case_id", "worker_id", "severity", "filed_day", "risk_score", "last_carry_day"]:
			if not _is_integral_number(source.get(field, null)):
				return {"valid": false}
		for field in ["worker_name", "type", "title", "status"]:
			if typeof(source.get(field, null)) not in [TYPE_STRING, TYPE_STRING_NAME]:
				return {"valid": false}
		var evidence_value: Variant = source.get("evidence", null)
		if not evidence_value is Dictionary:
			return {"valid": false}
		var evidence_source := evidence_value as Dictionary
		var evidence_keys: Array[String] = [
			"risk_score", "grievance", "stress", "fatigue", "manager_trust",
			"wage_arrears_cents", "compliance", "it_coop_installed",
			"recent_management_innovation",
		]
		if not _dictionary_has_exact_keys(evidence_source, evidence_keys):
			return {"valid": false}
		if (
			not _is_integral_number(evidence_source.get("risk_score", null))
			or not _is_integral_number(evidence_source.get("wage_arrears_cents", null))
			or typeof(evidence_source.get("it_coop_installed", null)) != TYPE_BOOL
			or typeof(evidence_source.get("recent_management_innovation", null)) != TYPE_BOOL
		):
			return {"valid": false}
		for metric in ["grievance", "stress", "fatigue", "manager_trust", "compliance"]:
			var metric_value: Variant = evidence_source.get(metric, null)
			if typeof(metric_value) not in [TYPE_FLOAT, TYPE_INT]:
				return {"valid": false}
			var metric_number := float(metric_value)
			if not is_finite(metric_number) or metric_number < 0.0 or metric_number > 100.0:
				return {"valid": false}
		var case_id := int(source.get("case_id", 0))
		var worker_id := int(source.get("worker_id", -1))
		var severity := int(source.get("severity", 0))
		var filed_day := int(source.get("filed_day", 0))
		var risk_score := int(source.get("risk_score", 0))
		var last_carry_day := int(source.get("last_carry_day", 0))
		var case_type := StringName(String(source.get("type", "")))
		if (
			case_id < 1 or seen_case_ids.has(case_id)
			or worker_id < 0 or worker_id >= restored_workers.size()
			or seen_worker_ids.has(worker_id)
			or severity < 1 or severity > 3
			or filed_day < 1 or filed_day > saved_day
			or last_carry_day < filed_day or last_carry_day > saved_day
			or risk_score < FLOCK_RELATIONS_CASE_RISK_THRESHOLD or risk_score > 1000
			or case_type not in FLOCK_RELATIONS_CASE_TYPES
			or StringName(String(source.get("status", ""))) != &"open"
		):
			return {"valid": false}
		var worker := restored_workers[worker_id]
		if (
			String(source.get("worker_name", "")) != worker.display_name
			or String(source.get("title", "")) != _flock_relations_case_title(case_type)
			or severity != _flock_relations_case_severity(risk_score)
			or int(evidence_source.get("risk_score", -1)) != risk_score
		):
			return {"valid": false}
		var grievance := float(evidence_source.get("grievance", 0.0))
		var stress := float(evidence_source.get("stress", 0.0))
		var fatigue := float(evidence_source.get("fatigue", 0.0))
		var trust := float(evidence_source.get("manager_trust", 0.0))
		var evidence_compliance := float(evidence_source.get("compliance", 0.0))
		var evidence_arrears := int(evidence_source.get("wage_arrears_cents", -1))
		if evidence_arrears < 0 or evidence_arrears > 2_000_000_000:
			return {"valid": false}
		var expected_risk := roundi(grievance * 2.0 + stress + fatigue + (100.0 - trust))
		if evidence_arrears > 0:
			expected_risk += 120
		if bool(evidence_source.get("it_coop_installed", false)):
			expected_risk += roundi(maxf(0.0, 70.0 - evidence_compliance) * 2.0)
		var expected_type: StringName = &"workplace_grievance"
		if evidence_arrears > 0:
			expected_type = &"pay_dispute"
		elif bool(evidence_source.get("it_coop_installed", false)) and evidence_compliance < 60.0:
			expected_type = &"automation_appeal"
		elif grievance >= 50.0:
			expected_type = &"surveillance_grievance"
		elif stress + fatigue >= 120.0:
			expected_type = &"burnout_case"
		elif bool(evidence_source.get("recent_management_innovation", false)):
			expected_type = &"credit_claim"
		if risk_score != expected_risk or case_type != expected_type:
			return {"valid": false}
		seen_case_ids[case_id] = true
		seen_worker_ids[worker_id] = true
		open_cases.append({
			"case_id": case_id,
			"worker_id": worker_id,
			"worker_name": worker.display_name,
			"type": case_type,
			"title": _flock_relations_case_title(case_type),
			"severity": severity,
			"filed_day": filed_day,
			"status": &"open",
			"evidence": {
				"risk_score": risk_score,
				"grievance": snappedf(grievance, 0.0001),
				"stress": snappedf(stress, 0.0001),
				"fatigue": snappedf(fatigue, 0.0001),
				"manager_trust": snappedf(trust, 0.0001),
				"wage_arrears_cents": evidence_arrears,
				"compliance": snappedf(evidence_compliance, 0.0001),
				"it_coop_installed": bool(evidence_source.get("it_coop_installed", false)),
				"recent_management_innovation": bool(evidence_source.get("recent_management_innovation", false)),
			},
			"risk_score": risk_score,
			"last_carry_day": last_carry_day,
		})
	var history: Array[Dictionary] = []
	var history_spend := 0
	var history_denials := 0
	var resolutions_on_saved_day := 0
	var previous_resolution_day := 0
	for resolution_value in (history_value as Array):
		var validated := _validated_flock_relations_resolution(
			resolution_value,
			saved_day,
			facility_level_value,
			restored_workers,
		)
		if not bool(validated.get("valid", false)):
			return {"valid": false}
		var resolution := validated.get("record", {}) as Dictionary
		var resolved_case_id := int(resolution.get("case_id", 0))
		var resolution_day := int(resolution.get("resolved_day", 0))
		if seen_case_ids.has(resolved_case_id) or resolution_day < previous_resolution_day:
			return {"valid": false}
		seen_case_ids[resolved_case_id] = true
		previous_resolution_day = resolution_day
		history_spend += int(resolution.get("cost_cents", 0))
		if StringName(resolution.get("action_id", &"")) == &"file_pip":
			history_denials += 1
		if resolution_day == saved_day:
			resolutions_on_saved_day += 1
		history.append(resolution)
	var last_resolution: Dictionary = {}
	if not (last_value as Dictionary).is_empty():
		var validated_last := _validated_flock_relations_resolution(
			last_value,
			saved_day,
			facility_level_value,
			restored_workers,
		)
		if not bool(validated_last.get("valid", false)):
			return {"valid": false}
		last_resolution = validated_last.get("record", {}) as Dictionary
	if (
		resolutions_used != resolutions_on_saved_day
		or (resolved_total == 0 and (not history.is_empty() or not last_resolution.is_empty()))
		or (resolved_total > 0 and (history.is_empty() or last_resolution != history[history.size() - 1]))
		or (resolved_total <= FLOCK_RELATIONS_HISTORY_LIMIT and history.size() != resolved_total)
		or (resolved_total > FLOCK_RELATIONS_HISTORY_LIMIT and history.size() != FLOCK_RELATIONS_HISTORY_LIMIT)
		or (resolved_total <= FLOCK_RELATIONS_HISTORY_LIMIT and spend_total != history_spend)
		or (resolved_total > FLOCK_RELATIONS_HISTORY_LIMIT and spend_total < history_spend)
		or (resolved_total <= FLOCK_RELATIONS_HISTORY_LIMIT and denied_total != history_denials)
		or (resolved_total > FLOCK_RELATIONS_HISTORY_LIMIT and denied_total < history_denials)
		or next_case_id != resolved_total + open_cases.size() + 1
	):
		return {"valid": false}
	for recorded_case_id in seen_case_ids:
		if int(recorded_case_id) >= next_case_id:
			return {"valid": false}
	if facility_level_value == 0 and (
		not open_cases.is_empty()
		or resolutions_used != 0
		or resolved_total != 0
		or denied_total != 0
		or spend_total != 0
		or not last_resolution.is_empty()
		or not history.is_empty()
		or next_case_id != 1
	):
		return {"valid": false}
	return {
		"valid": true,
		"open_cases": open_cases,
		"resolutions_used_today": resolutions_used,
		"resolved_total": resolved_total,
		"denied_total": denied_total,
		"settlement_spend_total_cents": spend_total,
		"last_resolution": last_resolution,
		"history": history,
		"next_case_id": next_case_id,
	}


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
	# Signed folders receive immutable IDs before their timed arrival. Include
	# unreleased and already completed contract IDs so a restored allocator can
	# never recycle one into ordinary intake.
	for claim_id_value in active_market_contract.get("claim_ids", []):
		if _is_integral_number(claim_id_value):
			highest = maxi(highest, int(claim_id_value))
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


func _next_personnel_action_serial() -> int:
	var highest := 0
	for worker in workers:
		highest = maxi(highest, worker.last_personnel_action_serial)
	return mini(2_000_000_000, highest + 1)


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


func personnel_action_count_today() -> int:
	return _personnel_actions_for_day(day).size()


func personnel_action_used_today() -> bool:
	return personnel_action_count_today() >= personnel_action_limit()


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


func perform_personnel_action(worker_id: int, action_id: StringName) -> Dictionary:
	## One consequential check-in is available across the entire flock each shift.
	## Every guard runs before the first mutation so denied actions are atomic.
	if worker_id < 0 or worker_id >= workers.size():
		return _rejected_personnel_action("Select a valid hen before filing a check-in.")
	if not workers[worker_id].employed:
		return _rejected_personnel_action("Applicants cannot receive active-roster check-ins.")
	if not PERSONNEL_ACTION_DEFINITIONS.has(action_id):
		return _rejected_personnel_action("That personnel action is not in the approved handbook.")
	var worker := workers[worker_id]
	var definition: Dictionary = PERSONNEL_ACTION_DEFINITIONS[action_id]
	var preferred := _preferred_personnel_action(worker) == action_id
	var career_xp_award := _personnel_action_career_xp_award(worker, action_id, preferred)
	var wage_delta_cents := _personnel_action_wage_delta_cents(worker, career_xp_award)
	if shift_phase != ShiftPhase.RUNNING:
		return _rejected_personnel_action("Resolve the current management decision first.")
	if (
		workers[worker_id].last_personnel_action_day == day
		and workers[worker_id].last_personnel_action != &""
	):
		return _rejected_personnel_action(
			"%s already has a filed flock check-in today." % workers[worker_id].display_name
		)
	if personnel_action_used_today():
		return _rejected_personnel_action(
			"Today's %d flock %s already filed." % [
				personnel_action_limit(),
				"check-in is" if personnel_action_limit() == 1 else "check-ins are",
			]
		)
	var cost_cents := int(definition["cost_cents"])
	var required_spendable_cents := cost_cents + wage_delta_cents
	var available_spendable_cents := spendable_fund_cents()
	if available_spendable_cents < required_spendable_cents:
		var shortfall := float(required_spendable_cents - available_spendable_cents) / 100.0
		var reserve_reason := "Check-in denied: $%.2f more spendable Feed Fund required." % shortfall
		if wage_delta_cents > 0:
			reserve_reason = (
				"Check-in denied: $%.2f more spendable Feed Fund required after the $%.2f daily promotion wage."
				% [shortfall, float(wage_delta_cents) / 100.0]
			)
		return _rejected_personnel_action(reserve_reason)

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
			worker.add_career_xp(career_xp_award)
			executive_confidence = clampf(executive_confidence - 2.0, 0.0, 100.0)
			solidarity = clampf(solidarity + 2.0, 0.0, 100.0)
		&"career_coaching":
			worker.manager_trust = clampf(worker.manager_trust + (9.0 if preferred else 7.0), 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 3.0, 0.0, 100.0)
			worker.morale = clampf(worker.morale + 3.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 3.0, 0.0, 100.0)
			worker.fatigue = clampf(worker.fatigue + 2.0, 0.0, 100.0)
			worker.add_career_xp(career_xp_award)
			compliance = clampf(compliance + 2.0, 0.0, 100.0)
		&"quota_pressure":
			worker.manager_trust = clampf(worker.manager_trust - 12.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance + (10.0 if preferred else 14.0), 0.0, 100.0)
			worker.morale = clampf(worker.morale - 7.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 8.0, 0.0, 100.0)
			worker.fatigue = clampf(worker.fatigue + 4.0, 0.0, 100.0)
			worker.add_career_xp(career_xp_award)
			executive_confidence = clampf(executive_confidence + 3.0, 0.0, 100.0)
			compliance = clampf(compliance + 2.0, 0.0, 100.0)
			solidarity = clampf(solidarity + 4.0, 0.0, 100.0)
	worker.last_personnel_action = action_id
	worker.last_personnel_action_day = day
	worker.last_personnel_action_serial = _next_personnel_action_serial()
	if action_id == &"quota_pressure":
		_breach_safe_pace_compact(&"quota_pressure")

	var effects := {
		"trust": worker.manager_trust - float(before["trust"]),
		"grievance": worker.grievance - float(before["grievance"]),
		"morale": worker.morale - float(before["morale"]),
		"stress": worker.stress - float(before["stress"]),
		"fatigue": worker.fatigue - float(before["fatigue"]),
		"career_xp": worker.career_xp - int(before["career_xp"]),
		"career_coaching_xp_bonus": career_coaching_xp_bonus() if action_id == &"career_coaching" else 0,
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
		"action_serial": worker.last_personnel_action_serial,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"action_id": action_id,
		"action_name": String(definition["name"]),
		"cost_cents": cost_cents,
		"career_xp_award": career_xp_award,
		"daily_wage_delta_cents": wage_delta_cents,
		"preferred": preferred,
		"effects": effects,
		"promoted": String(before["career_title"]) != worker.career_title(),
		"career_title": worker.career_title(),
		"outcome": outcome,
		"personnel_actions_used": personnel_action_count_today(),
		"personnel_action_limit": personnel_action_limit(),
		"personnel_actions_remaining": clampi(
			personnel_action_limit() - personnel_action_count_today(),
			0,
			personnel_action_limit(),
		),
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
	var timing_window := PECK_ASSIST_TIMING_PROFILES[peck_assist_timing_profile] as Dictionary
	var window_start := float(timing_window["window_start"])
	var window_end := float(timing_window["window_end"])
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
		"timing_assist_profile": peck_assist_timing_profile,
		"window_start": window_start,
		"window_end": window_end,
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
	if progress < window_start:
		status["window_state"] = &"not_ready"
		status["reason"] = "Build the claim rhythm to %d%% before stamping." % int(window_start)
		return status
	if progress > window_end:
		status["window_state"] = &"passed"
		status["reason"] = "The safe synchronization window has passed for this claim."
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
	_harvest_credit.release_credit_gate(completed_day)
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


func _is_valid_feed_procurement_quote_state(state: FeedProcurementState) -> bool:
	for lot in state.lots:
		var offer_id := StringName(String(lot.get("offer_id", "")))
		if int(lot.get("unit_cost_cents", -1)) != _feed_offer_unit_price_cents(
			offer_id,
			int(lot.get("ordered_day", 0)),
		):
			return false
	if not state.last_order.is_empty():
		var order_offer_id := StringName(String(state.last_order.get("offer_id", "")))
		if int(state.last_order.get("unit_cost_cents", -1)) != _feed_offer_unit_price_cents(
			order_offer_id,
			int(state.last_order.get("day", 0)),
		):
			return false
	if not state.last_consumption.is_empty():
		if int(state.last_consumption.get("spot_unit_price_cents", -1)) != _feed_spot_unit_price_cents(
			int(state.last_consumption.get("day", 0))
		):
			return false
	if not state.last_spoilage.is_empty():
		for row_value in state.last_spoilage.get("lots", []):
			var row := row_value as Dictionary
			var spoil_offer_id := StringName(String(row.get("offer_id", "")))
			if not FEED_PROCUREMENT_OFFER_DEFINITIONS.has(spoil_offer_id):
				return false
			var definition := FEED_PROCUREMENT_OFFER_DEFINITIONS[spoil_offer_id] as Dictionary
			var ordered_day := (
				int(row.get("expired_day", 0))
				- int(definition.get("shelf_shifts", 1))
				+ 1
			)
			if int(row.get("unit_cost_cents", -1)) != _feed_offer_unit_price_cents(
				spoil_offer_id,
				ordered_day,
			):
				return false
	return true


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
	_decision_serial += 1
	shift_phase = ShiftPhase.AWAITING_DIRECTIVE
	var options: Array[Dictionary] = []
	for directive in directive_catalog():
		options.append({
			"id": directive["id"],
			"label": directive["name"],
			"short_label": directive["short_name"],
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
		"eyebrow": "MORNING DIRECTIVE  ·  DAY %d  ·  DOCKET %s" % [
			day,
			String(case_docket_snapshot().get("id", "PO-1701")),
		],
		"title": "CHOOSE TODAY'S MANAGEMENT POLICY",
		"body": "One policy governs the entire shift. Its benefits and liabilities are both real, even if only one appears in the farmer's presentation.",
		"options": options,
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
	})
	snapshot_changed.emit(snapshot())
	return true


func _incident_choices(incident_id: StringName) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	if not INCIDENT_DEFINITIONS.has(incident_id):
		return choices
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
		# The legacy docket opens with the two familiar onboarding cases. This
		# preserves tutorial expectations while later rotations still vary.
		_incident_bag.reverse()
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
	return {
		"id": "PO-%04d" % posmod(_career_seed, 10_000),
		"career_seed": _career_seed,
		"remaining_in_rotation": _incident_bag.size(),
		"rotation_size": INCIDENT_ORDER.size(),
		"last_incident_id": _last_standard_incident_id,
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
		if _career_seed == 1701 or is_petition_slot:
			# PO-1701 is the shipped balance baseline and the destination for legacy
			# saves. A petition slot with no eligible sponsor also retains its authored
			# structural fallback. New ordinary docket slots use the shuffled bag.
			var rotation_index := (
				(day - 1) * INCIDENT_MINUTES.size() + _incident_slot
			) % INCIDENT_ORDER.size()
			incident_id = INCIDENT_ORDER[rotation_index]
			_last_standard_incident_id = incident_id
		else:
			incident_id = _next_standard_incident_id()
		var definition: Dictionary = INCIDENT_DEFINITIONS[incident_id]
		var options: Array[Dictionary] = []
		for choice in _incident_choices(incident_id):
			options.append(choice.duplicate(true))
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
	var cost_cents := (
		maxi(0, int(chosen.get("cost_cents", 0)))
		if is_flock_petition else
		_incident_option_cost_cents(incident_id, option_id)
	)
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
				_consume_feed_for_shift()
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
	flock_relations_resolutions_used_today = 0
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
	if (
		trained_claim != null
		and trained_claim.deadline_operational_minute
			<= urgent_claim.deadline_operational_minute + automation_specialty_grace_minutes()
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


func _claim_affinity_crack_modifier(worker: ChickenState) -> float:
	if worker.current_claim == null:
		return 0.0
	return (
		SPECIALTY_CRACK_MODIFIER
		if worker.has_specialty(worker.current_claim.lane) else
		MISMATCH_CRACK_MODIFIER
	)


func _facility_claim_speed_multiplier(worker: ChickenState) -> float:
	if worker.current_claim == null or not worker.current_claim.is_rework:
		return 1.0
	return float(facility_effects().get("rework_speed_multiplier", 1.0))


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


func _apply_market_contract_claim_snapshot(claim_snapshot: Dictionary) -> void:
	if claim_snapshot.is_empty() or active_market_contract.is_empty():
		return
	var claim_id := int(claim_snapshot.get("id", -1))
	if claim_id not in (active_market_contract.get("accepted_claim_ids", []) as Array):
		return
	var schedule: Dictionary = {}
	for schedule_value in active_market_contract.get("scheduled_claims", []):
		var candidate := schedule_value as Dictionary
		if int(candidate.get("claim_id", -1)) == claim_id:
			schedule = candidate
			break
	claim_snapshot["market_contract"] = true
	claim_snapshot["market_contract_id"] = String(active_market_contract.get("contract_id", ""))
	claim_snapshot["market_contract_offer_id"] = String(active_market_contract.get("offer_id", ""))
	claim_snapshot["market_contract_name"] = String(active_market_contract.get("short_name", "MUTUAL BINDER"))
	claim_snapshot["market_contract_rush"] = bool(schedule.get("rush", false))
	claim_snapshot["market_contract_deadline_time"] = String(schedule.get("deadline_time", "5:00 PM"))


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
	_tick_count += 1
	minute_of_day += MINUTES_PER_TICK

	_release_due_rework()
	_release_due_market_contract_claims()
	if _tick_count % 3 == 0:
		_offer_new_claim(_choose_arrival_lane())

	for worker in workers:
		if not worker.employed:
			continue
		_update_worker(worker)

	if _maybe_open_incident():
		if publish_snapshot:
			snapshot_changed.emit(snapshot())
		return

	if minute_of_day >= SHIFT_END_MINUTE:
		_complete_workday()

	if publish_snapshot:
		snapshot_changed.emit(snapshot())


## Publishes one complete read model after a SimulationClock batch. Direct
## management transactions and direct advance_tick() calls retain their
## immediate snapshot contract; only clock-serviced accelerated ticks coalesce.
func publish_current_snapshot() -> void:
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
			"A valid collected claim is required before reinvestment can open.",
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


func flock_relations_snapshot() -> Dictionary:
	var published_cases: Array[Dictionary] = []
	for case_record in flock_relations_open_cases:
		published_cases.append(_flock_relations_public_case(case_record))
	return {
		"level": facility_level(FLOCK_RELATIONS_OFFICE_ID),
		"capacity": flock_relations_case_capacity(),
		"resolution_limit": flock_relations_resolution_limit(),
		"resolutions_used_today": flock_relations_resolutions_used_today,
		"open_case_count": flock_relations_open_cases.size(),
		"open_cases": published_cases,
		"resolved_total": flock_relations_resolved_total,
		"denied_total": flock_relations_denied_total,
		"settlement_spend_total_cents": flock_relations_settlement_spend_total_cents,
		"last_resolution": last_flock_relations_resolution.duplicate(true),
	}


func _flock_relations_public_case(case_record: Dictionary) -> Dictionary:
	var case_id := int(case_record.get("case_id", 0))
	var worker_id := int(case_record.get("worker_id", -1))
	var worker_name := String(case_record.get("worker_name", "UNKNOWN HEN"))
	var action_options: Array[Dictionary] = []
	for action_id in FLOCK_RELATIONS_ACTION_ORDER:
		var preflight := flock_relations_resolution_preflight(case_id, action_id)
		action_options.append({
			"action_id": action_id,
			"label": String(preflight.get("label", "CASE ACTION")),
			"required_level": int(preflight.get("required_level", 0)),
			"cost_cents": int(preflight.get("cost_cents", 0)),
			"enabled": bool(preflight.get("can_resolve", false)),
			"reason": String(preflight.get("reason", "")),
			"effect_preview": String(preflight.get("effect_preview", "")),
		})
	var filed_day := int(case_record.get("filed_day", 0))
	var case_type := StringName(case_record.get("type", &"workplace_grievance"))
	var evidence := (case_record.get("evidence", {}) as Dictionary).duplicate(true)
	return {
		"case_id": case_id,
		"docket_id": "FR-D%d-H%d-%d" % [filed_day, worker_id, case_id],
		"worker": {"id": worker_id, "name": worker_name},
		"worker_id": worker_id,
		"worker_name": worker_name,
		"type": case_type,
		"case_type": case_type,
		"title": String(case_record.get("title", "WORKPLACE GRIEVANCE")),
		"severity": int(case_record.get("severity", 1)),
		"filed": filed_day,
		"filed_day": filed_day,
		"status": StringName(case_record.get("status", &"open")),
		"evidence": evidence,
		"evidence_summary": _flock_relations_evidence_summary(evidence),
		"action_options": action_options,
	}


func _flock_relations_evidence_summary(evidence: Dictionary) -> String:
	var summary := "Risk %d | Grievance %.1f | Stress %.1f | Fatigue %.1f | Trust %.1f" % [
		int(evidence.get("risk_score", 0)),
		float(evidence.get("grievance", 0.0)),
		float(evidence.get("stress", 0.0)),
		float(evidence.get("fatigue", 0.0)),
		float(evidence.get("manager_trust", 0.0)),
	]
	var arrears_cents := int(evidence.get("wage_arrears_cents", 0))
	if arrears_cents > 0:
		summary += " | Arrears $%.2f" % (float(arrears_cents) / 100.0)
	if bool(evidence.get("it_coop_installed", false)):
		summary += " | Compliance %.1f" % float(evidence.get("compliance", 0.0))
	return summary


func _flock_relations_case_index(case_id: int) -> int:
	for index in flock_relations_open_cases.size():
		if int(flock_relations_open_cases[index].get("case_id", -1)) == case_id:
			return index
	return -1


func _flock_relations_action_cost_cents(action_id: StringName, severity: int) -> int:
	var bounded_severity := clampi(severity, 1, 3)
	match action_id:
		&"fund_remedy":
			return 800 + bounded_severity * 400
		&"mediate":
			return 400 + bounded_severity * 200
		&"file_pip":
			return 0
		&"binding_arbitration":
			return 600 + bounded_severity * 300
	return 0


func flock_relations_resolution_preflight(case_id: int, action_id: StringName) -> Dictionary:
	var known_action := FLOCK_RELATIONS_ACTION_DEFINITIONS.has(action_id)
	var definition := (
		FLOCK_RELATIONS_ACTION_DEFINITIONS[action_id] as Dictionary
		if known_action else
		{}
	)
	var case_index := _flock_relations_case_index(case_id)
	var case_found := case_index >= 0
	var case_record := (
		flock_relations_open_cases[case_index]
		if case_found else
		{}
	)
	var severity := int(case_record.get("severity", 1))
	var cost_cents := (
		_flock_relations_action_cost_cents(action_id, severity)
		if known_action and case_found else
		0
	)
	var required_level := int(definition.get("required_level", 0))
	var level := facility_level(FLOCK_RELATIONS_OFFICE_ID)
	var installed := level > 0
	var review_open := shift_phase == ShiftPhase.REVIEW
	var within_limit := (
		flock_relations_resolutions_used_today < flock_relations_resolution_limit()
	)
	var tier_available := known_action and installed and level >= required_level
	var affordable := known_action and case_found and spendable_fund_cents() >= cost_cents
	var can_resolve := (
		known_action
		and case_found
		and installed
		and review_open
		and within_limit
		and tier_available
		and affordable
	)
	var reason := ""
	if not known_action:
		reason = "That disposition is not on the Flock Relations action schedule."
	elif not case_found:
		reason = "That workplace case is no longer open."
	elif not installed:
		reason = "Commission Flock Relations before resolving workplace cases."
	elif not review_open:
		reason = "Workplace cases may only be resolved during shift review."
	elif not within_limit:
		reason = "The Flock Relations review limit has been reached for this day."
	elif not tier_available:
		reason = "%s requires Flock Relations level %d; the office is level %d." % [
			String(definition.get("label", "CASE ACTION")),
			required_level,
			level,
		]
	elif not affordable:
		reason = "%s requires $%.2f in spendable Feed Fund." % [
			String(definition.get("label", "CASE ACTION")),
			float(cost_cents) / 100.0,
		]
	return {
		"accepted": can_resolve,
		"can_resolve": can_resolve,
		"case_id": case_id,
		"case_found": case_found,
		"action_id": action_id,
		"known_action": known_action,
		"label": String(definition.get("label", "UNKNOWN DISPOSITION")),
		"required_level": required_level,
		"cost_cents": cost_cents,
		"effect_preview": String(definition.get("effect_preview", "")),
		"level": level,
		"installed": installed,
		"review_open": review_open,
		"resolution_limit": flock_relations_resolution_limit(),
		"resolutions_used_today": flock_relations_resolutions_used_today,
		"within_limit": within_limit,
		"affordable": affordable,
		"spendable_fund_cents": spendable_fund_cents(),
		"reason": reason,
	}


func resolve_flock_relations_case(case_id: int, action_id: StringName) -> Dictionary:
	var preflight := flock_relations_resolution_preflight(case_id, action_id)
	if not bool(preflight.get("can_resolve", false)):
		var rejection := preflight.duplicate(true)
		rejection["accepted"] = false
		return rejection
	var case_index := _flock_relations_case_index(case_id)
	if case_index < 0:
		# The public method is synchronous, but retain a closed atomic guard if that
		# ever changes so no fund or relationship mutation can outlive its case.
		var missing := preflight.duplicate(true)
		missing["accepted"] = false
		missing["can_resolve"] = false
		missing["reason"] = "That workplace case is no longer open."
		return missing
	var case_record := flock_relations_open_cases[case_index]
	var worker_id := int(case_record.get("worker_id", -1))
	if worker_id < 0 or worker_id >= workers.size():
		var invalid_subject := preflight.duplicate(true)
		invalid_subject["accepted"] = false
		invalid_subject["can_resolve"] = false
		invalid_subject["reason"] = "The case subject is not in the authoritative flock ledger."
		return invalid_subject
	var worker := workers[worker_id]
	var public_case_before_resolution := _flock_relations_public_case(case_record)
	var fund_before := revenue_cents
	var trust_before := worker.manager_trust
	var grievance_before := worker.grievance
	var stress_before := worker.stress
	var compliance_before := compliance
	var solidarity_before := solidarity
	var favor_before := executive_confidence
	match action_id:
		&"fund_remedy":
			worker.manager_trust = clampf(worker.manager_trust + 12.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 16.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress - 8.0, 0.0, 100.0)
			compliance = clampf(compliance + 4.0, 0.0, 100.0)
			executive_confidence = clampf(executive_confidence - 2.0, 0.0, 100.0)
		&"mediate":
			worker.manager_trust = clampf(worker.manager_trust + 7.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 9.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress - 4.0, 0.0, 100.0)
			compliance = clampf(compliance + 2.0, 0.0, 100.0)
			executive_confidence = clampf(executive_confidence - 1.0, 0.0, 100.0)
		&"file_pip":
			worker.manager_trust = clampf(worker.manager_trust - 10.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance + 14.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress + 8.0, 0.0, 100.0)
			compliance = clampf(compliance - 3.0, 0.0, 100.0)
			solidarity = clampf(solidarity + 4.0, 0.0, 100.0)
			executive_confidence = clampf(executive_confidence + 3.0, 0.0, 100.0)
			flock_relations_denied_total += 1
		&"binding_arbitration":
			worker.manager_trust = clampf(worker.manager_trust - 3.0, 0.0, 100.0)
			worker.grievance = clampf(worker.grievance - 5.0, 0.0, 100.0)
			worker.stress = clampf(worker.stress - 3.0, 0.0, 100.0)
			compliance = clampf(compliance + 6.0, 0.0, 100.0)
			solidarity = clampf(solidarity + 2.0, 0.0, 100.0)
			executive_confidence = clampf(executive_confidence + 1.0, 0.0, 100.0)
	var cost_cents := int(preflight.get("cost_cents", 0))
	revenue_cents -= cost_cents
	flock_relations_settlement_spend_total_cents += cost_cents
	flock_relations_resolutions_used_today += 1
	flock_relations_resolved_total += 1
	flock_relations_open_cases.remove_at(case_index)
	var action_label := String(preflight.get("label", "CASE DISPOSITION"))
	var outcome := "%s closed %s's %s file for $%.2f." % [
		action_label.capitalize(),
		worker.display_name,
		String(case_record.get("title", "workplace grievance")).to_lower(),
		float(cost_cents) / 100.0,
	]
	var resolution := {
		"case_id": case_id,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"type": StringName(case_record.get("type", &"workplace_grievance")),
		"title": String(case_record.get("title", "WORKPLACE GRIEVANCE")),
		"severity": int(case_record.get("severity", 1)),
		"filed_day": int(case_record.get("filed_day", 0)),
		"resolved_day": day,
		"action_id": action_id,
		"action_label": action_label,
		"cost_cents": cost_cents,
		"outcome": outcome,
	}
	last_flock_relations_resolution = resolution.duplicate(true)
	flock_relations_resolution_history.append(resolution.duplicate(true))
	while flock_relations_resolution_history.size() > FLOCK_RELATIONS_HISTORY_LIMIT:
		flock_relations_resolution_history.pop_front()
	var result := preflight.duplicate(true)
	result.merge({
		"accepted": true,
		"case": public_case_before_resolution,
		"worker_id": worker.id,
		"worker_name": worker.display_name,
		"severity": int(case_record.get("severity", 1)),
		"fund_before_cents": fund_before,
		"fund_after_cents": revenue_cents,
		"fund_delta_cents": revenue_cents - fund_before,
		"trust_before": trust_before,
		"trust_after": worker.manager_trust,
		"grievance_before": grievance_before,
		"grievance_after": worker.grievance,
		"stress_before": stress_before,
		"stress_after": worker.stress,
		"compliance_before": compliance_before,
		"compliance_after": compliance,
		"solidarity_before": solidarity_before,
		"solidarity_after": solidarity,
		"farmer_favor_before": favor_before,
		"farmer_favor_after": executive_confidence,
		"resolution": resolution.duplicate(true),
		"outcome": outcome,
	}, true)
	announcement_posted.emit(outcome)
	snapshot_changed.emit(snapshot())
	return result


func _flock_relations_case_risk(worker: ChickenState) -> int:
	var risk := roundi(
		worker.grievance * 2.0
		+ worker.stress
		+ worker.fatigue
		+ (100.0 - worker.manager_trust)
	)
	if wage_arrears_cents > 0:
		risk += 120
	if facility_level(IT_COOP_ID) > 0:
		risk += roundi(maxf(0.0, 70.0 - compliance) * 2.0)
	return risk


func _recent_management_innovation_allocation(completed_day: int) -> bool:
	if last_credit_allocation.is_empty():
		return false
	var allocation_day := int(last_credit_allocation.get("day", 0))
	return (
		StringName(last_credit_allocation.get("style_id", &"")) == &"management_innovation"
		and allocation_day >= maxi(1, completed_day - 1)
		and allocation_day <= completed_day
	)


func _flock_relations_case_type(worker: ChickenState, completed_day: int) -> StringName:
	if wage_arrears_cents > 0:
		return &"pay_dispute"
	if facility_level(IT_COOP_ID) > 0 and compliance < 60.0:
		return &"automation_appeal"
	if worker.grievance >= 50.0:
		return &"surveillance_grievance"
	if worker.stress + worker.fatigue >= 120.0:
		return &"burnout_case"
	if _recent_management_innovation_allocation(completed_day):
		return &"credit_claim"
	return &"workplace_grievance"


func _flock_relations_case_title(case_type: StringName) -> String:
	match case_type:
		&"pay_dispute":
			return "DEFERRED FEED PAY DISPUTE"
		&"automation_appeal":
			return "AUTOMATED ASSIGNMENT APPEAL"
		&"surveillance_grievance":
			return "SUPERVISION & SURVEILLANCE GRIEVANCE"
		&"burnout_case":
			return "OCCUPATIONAL NEST STRAIN CASE"
		&"credit_claim":
			return "WORK PRODUCT CREDIT CLAIM"
	return "WORKPLACE GRIEVANCE"


func _flock_relations_case_severity(risk_score: int) -> int:
	if risk_score >= 280:
		return 3
	if risk_score >= 220:
		return 2
	return 1


func _worker_has_open_flock_relations_case(worker_id: int) -> bool:
	for case_record in flock_relations_open_cases:
		if int(case_record.get("worker_id", -1)) == worker_id:
			return true
	return false


func _file_flock_relations_case_after_shift(completed_day: int) -> Array[Dictionary]:
	var filings: Array[Dictionary] = []
	if (
		facility_level(FLOCK_RELATIONS_OFFICE_ID) <= 0
		or flock_relations_open_cases.size() >= flock_relations_case_capacity()
	):
		return filings
	var selected_worker: ChickenState
	var selected_risk := -1
	for worker in workers:
		if not worker.employed or _worker_has_open_flock_relations_case(worker.id):
			continue
		var risk := _flock_relations_case_risk(worker)
		if risk < FLOCK_RELATIONS_CASE_RISK_THRESHOLD:
			continue
		if selected_worker == null or risk > selected_risk:
			selected_worker = worker
			selected_risk = risk
	if selected_worker == null:
		return filings
	var case_type := _flock_relations_case_type(selected_worker, completed_day)
	var case_record := {
		"case_id": next_flock_relations_case_id,
		"worker_id": selected_worker.id,
		"worker_name": selected_worker.display_name,
		"type": case_type,
		"title": _flock_relations_case_title(case_type),
		"severity": _flock_relations_case_severity(selected_risk),
		"filed_day": completed_day,
		"status": &"open",
		"evidence": {
			"risk_score": selected_risk,
			"grievance": snappedf(selected_worker.grievance, 0.0001),
			"stress": snappedf(selected_worker.stress, 0.0001),
			"fatigue": snappedf(selected_worker.fatigue, 0.0001),
			"manager_trust": snappedf(selected_worker.manager_trust, 0.0001),
			"wage_arrears_cents": wage_arrears_cents,
			"compliance": snappedf(compliance, 0.0001),
			"it_coop_installed": facility_level(IT_COOP_ID) > 0,
			"recent_management_innovation": _recent_management_innovation_allocation(completed_day),
		},
		"risk_score": selected_risk,
		"last_carry_day": completed_day,
	}
	next_flock_relations_case_id += 1
	flock_relations_open_cases.append(case_record)
	var published := _flock_relations_public_case(case_record)
	filings.append(published)
	announcement_posted.emit(
		"FLOCK RELATIONS: %s filed %s (severity %d)." % [
			selected_worker.display_name,
			String(case_record["title"]).to_lower(),
			int(case_record["severity"]),
		]
	)
	return filings


func _apply_flock_relations_carry_penalties(completed_day: int) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for case_record in flock_relations_open_cases:
		if (
			int(case_record.get("filed_day", completed_day)) >= completed_day
			or int(case_record.get("last_carry_day", 0)) >= completed_day
		):
			continue
		var worker_id := int(case_record.get("worker_id", -1))
		if worker_id < 0 or worker_id >= workers.size():
			continue
		var worker := workers[worker_id]
		var compliance_before := compliance
		var solidarity_before := solidarity
		var grievance_before := worker.grievance
		compliance = clampf(compliance - 1.5, 0.0, 100.0)
		solidarity = clampf(solidarity + 1.5, 0.0, 100.0)
		worker.grievance = clampf(worker.grievance + 2.0, 0.0, 100.0)
		case_record["last_carry_day"] = completed_day
		effects.append({
			"case_id": int(case_record.get("case_id", 0)),
			"worker_id": worker.id,
			"worker_name": worker.display_name,
			"day": completed_day,
			"compliance_before": compliance_before,
			"compliance_after": compliance,
			"solidarity_before": solidarity_before,
			"solidarity_after": solidarity,
			"grievance_before": grievance_before,
			"grievance_after": worker.grievance,
		})
	return effects


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
	var replaced_name := _manager_display_name(manager_roster[manager_roster.size() - 1]) if manager_roster.size() > 1 else ""
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
		var hire_added_daily_operating_cents := (
			_hire_feed_obligation_delta_cents() + worker.daily_wage_cents()
		)
		var hire_projected_spendable_cents := _projected_spendable_after_obligation_change_cents(
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
			current_claim_snapshot["specialty_match"] = worker.has_specialty(worker.current_claim.lane)
			current_claim_snapshot["affinity_speed_multiplier"] = _claim_speed_factor(worker)
			current_claim_snapshot["affinity_crack_modifier"] = _claim_affinity_crack_modifier(worker)
			current_claim_snapshot["facility_speed_multiplier"] = _facility_claim_speed_multiplier(worker)
			current_claim_snapshot["automation_work_multiplier"] = automation_work_multiplier(worker)
			current_claim_snapshot["automation_enrolled"] = worker.assigned_lane == AUTO_ASSIGNMENT
		worker_snapshots.append(worker_snapshot)
	var queue_snapshot := _queue_snapshot()
	var pending_rework_items: Array[Dictionary] = []
	for claim in _pending_rework:
		pending_rework_items.append(claim.snapshot(now))

	var personnel_status := personnel_action_status()
	var campus_expansion_projection := campus_expansion_snapshot()
	var campus_portfolio_projection := campus_portfolio_snapshot(campus_expansion_projection)
	return {
		# Consumers can use this monotonic tick revision to recognize accelerated
		# simulation updates without parsing the full presentation payload. It is
		# deliberately distinct from action/event revisions, which may change
		# authoritative state between ticks.
		"authoritative_tick_revision": _tick_count,
		"case_docket": case_docket_snapshot(),
		"day": day,
		"minute_of_day": minute_of_day,
		"time_label": _format_time(minute_of_day),
		"claims_waiting": claims_waiting,
		"claims_outstanding": _outstanding_claim_count(),
		"claim_capacity": current_claim_capacity(),
		"intake_rejections_today": intake_rejections_today,
		"intake_rejections_total": intake_rejections_total,
		"intake_missed_value_today_cents": intake_missed_value_today_cents,
		"intake_missed_value_total_cents": intake_missed_value_total_cents,
		"contract_board": market_contract_board_status(),
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
		"farm_mutual_service_coop": farm_mutual_service_coop_status(),
		"farm_mutual_negotiation_room": farm_mutual_negotiation_room_status(),
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
		"daily_feed_cost_cents": current_daily_feed_cost_cents(),
		"feed_procurement": feed_procurement_snapshot(),
		"farmer_relations_gallery": farmer_relations_gallery_snapshot(),
		"farmgate_dispatch": farmgate_dispatch_snapshot(),
		"campus_expansion": campus_expansion_projection,
		"campus_portfolio": campus_portfolio_projection,
		"active_staff_count": active_staff,
		"office_capacity": office_capacity,
		"maximum_staff_capacity": MAXIMUM_STAFF_CAPACITY,
		"daily_hen_payroll_cents": current_daily_hen_payroll_cents(),
		"daily_supervisor_payroll_cents": current_daily_supervisor_payroll_cents(),
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
		"staffing_catalog": staffing_catalog(),
		"owned_facilities": owned_facilities.duplicate(),
		"facility_catalog": facility_catalog(),
		"facility_effects": facility_effects(),
		"pinned_capital_plan_id": pinned_capital_plan_id,
		"capital_plan": capital_plan_snapshot(),
		"last_facility_purchase_receipt": last_facility_purchase_receipt.duplicate(true),
		"facility_commissioning_history": facility_commissioning_history.duplicate(true),
		"flock_care": flock_care_snapshot(),
		"operations": operations_snapshot(),
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
			"fatigue_multiplier": _directive_fatigue_multiplier * _incident_strain_multiplier * float(_feed_procurement.active_strain_basis_points) / 10_000.0,
			"stress_multiplier": _directive_stress_multiplier * _incident_strain_multiplier * float(_feed_procurement.active_strain_basis_points) / 10_000.0,
			"feed_strain_basis_points": _feed_procurement.active_strain_basis_points,
			"morale_drain_multiplier": _directive_morale_drain_multiplier,
			"crack_modifier": (
				_directive_crack_modifier
				+ _incident_crack_modifier
				+ _work_to_rule_crack_modifier()
				+ float(facility_effects().get("crack_modifier", 0.0))
			),
			"facility_crack_modifier": float(facility_effects().get("crack_modifier", 0.0)),
			"facility_rework_speed_multiplier": float(facility_effects().get("rework_speed_multiplier", 1.0)),
			"work_to_rule_work_multiplier": _work_to_rule_work_multiplier(),
			"work_to_rule_crack_modifier": _work_to_rule_crack_modifier(),
			"golden_modifier": _incident_golden_modifier,
			"quota_adjustment": _pending_quota_adjustment,
		},
		"upgrade_levels": upgrade_levels.duplicate(),
		"upgrade_catalog": upgrade_catalog(),
		"first_clutch_reinvestment": first_clutch_reinvestment_status(),
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
				* _facility_claim_speed_multiplier(worker)
				* automation_work_multiplier(worker)
				* career_work_factor
				* float(_manager_effect_for_worker(worker).get("work_multiplier", 1.0))
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
				peck_assist_missed.emit(worker.id, missed_claim_id)
			worker.fatigue = minf(100.0, worker.fatigue + (0.65 if overtime_enabled else 0.36) * comfort_factor * _directive_fatigue_multiplier * decision_strain_factor * campaign_fatigue_factor * wellness_strain_factor * feed_strain_factor)
			worker.stress = minf(100.0, worker.stress + (0.40 if overtime_enabled else 0.2) * comfort_factor * _directive_stress_multiplier * decision_strain_factor * campaign_stress_factor * career_strain_factor * wellness_strain_factor * feed_strain_factor)
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
			var break_recovery_factor := wellness_break_recovery_multiplier()
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
	error_risk += _career_relationship_crack_modifier(worker)
	error_risk += _personnel_shift_crack_modifier(worker)
	error_risk += float(_manager_effect_for_worker(worker).get("crack_modifier", 0.0))
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
	if completed_claim != null:
		_record_market_contract_completion(completed_claim, quality)
	var packing_receipt := _apply_packing_contract_value(quality, value_cents)
	value_cents = int(packing_receipt.get("value_cents", value_cents))
	if has_campaign_unlock(&"farmer_credit_bonus"):
		value_cents += 25
	if quality in [&"sound", &"golden"]:
		value_cents += _campus_portfolio.good_egg_bonus_cents(_campus_portfolio_context())
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
	var effective_capacity := _farmgate_storage_capacity_eggs()
	return _farmgate_dispatch.store_lot(
		claim_id,
		laying_day,
		worker_id,
		worker_name,
		quality,
		value_cents,
		farmgate_level,
		shelf_shifts,
		effective_capacity,
		_campus_portfolio.farmgate_overflow_basis_points(_campus_portfolio_context()),
	)


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
	var completed_payroll := completed_hen_payroll + completed_supervisor_payroll
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
		"requisition_spend_cents": completed_requisition_spend_cents,
		"requisition_spend_total_cents": requisition_spend_total_cents,
		"orientation_procurement_match_cents": completed_orientation_match_cents,
		"orientation_procurement_match_total_cents": orientation_procurement_match_total_cents,
		"new_facility_unlocks": completed_new_facility_unlocks.duplicate(true),
		"hen_payroll_cents": completed_hen_payroll,
		"supervisor_payroll_cents": completed_supervisor_payroll,
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
		"directive": completed_directive,
		"incidents_resolved": completed_incidents,
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
