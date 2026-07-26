# Pecking Order core production acceptance record

This record maps the core production checklist to shipped behavior and repeatable
evidence. The five-shift probation file is the authored campaign. Senior Roost
is an optional post-campaign management file; it does not delay or replace the
ending, and the game contains no prestige reset, offline accumulation, paid
currency, or live-service pressure.

## Creative north star

- [x] The first view is a warm low-poly office, while policy copy, surveillance,
      credit transfer, denial handling, and farmer reviews reveal its incentives.
- [x] Chickens physically peck claims screens and lay claim-result eggs; the
      grading rail, Farm Mutual folders, and farmer basket keep farm language,
      insurance work, and output inseparable.
- [x] Major choices disclose exact effects, the beneficiary, and the burden.
      Claim paths, contracts, personnel actions, policies, facilities, and
      incidents all use authoritative previews and receipts.
- [x] Throughput, fast denial, pressure, surveillance, and credit-taking create
      real short-term advantages with worker, audit, trust, or later-queue costs.
- [x] Named hens retain careers, trust, grievance, temperament, nearest-perchmate
      bonds, petitions, commendations, and visible care/recovery.
- [x] The player is consistently a rooster managing the Egg Yield Bureau for
      Farm Mutual. Eggs are completed claims, never a generic commodity market.

Evidence: `department_simulation.gd`, `chicken_state.gd`,
`peckwork_routing_ui.gd`, `probation_campaign_ui.gd`,
`farmer_relations_gallery_visual.gd`, and the live browser career walkthrough.

## Shift loop

- [x] Every shift exposes the clutch target, clock, pause, 1x/3x/10x controls,
      and a clear morning filing action.
- [x] Incoming files route among Nest Damage, Predator Loss, and Appeals.
- [x] Hens visibly travel, sit, peck, lay, grade, and hand eggs to collection.
      Work and egg authorization are rejected unless the assigned hen is seated
      at her real workstation.
- [x] Conditions, skill, staffing, lane fit, temperament, claim path, policy,
      overtime, support, and risk all reach peck pace or shell grading.
- [x] Farmer review reports output, sound/golden/cracked quality, feed, payroll,
      upkeep, contracts, settlement, pressure, and the next target.
- [x] Filed Nest paths restore handler morale, Predator paths add trauma load,
      and Appeals paths change audit order beyond their base deadlines and risk.
- [x] Priority Peck, Feed Party, personnel check-ins, care/training, claim
      resolution, and incident responses provide meaningful mid-shift actions.
- [x] Rework, claimant appeals, complaints, audits, trust loss, petitions, and
      work-to-rule return in later shifts.
- [x] The office view, focused hen dossier, and collapsible Flockwatch keep every
      important action visible or one interaction away.

Evidence: `claimant_resolution_test.gd`, `claim_routing_ui_test.gd`,
`egg_seating_regression_test.gd`, `chicken_seated_wing_pose_test.gd`,
`campaign_balance_playthrough_test.gd`, and `probation_campaign_ui_test.gd`.

## Claims, claimants, and insurance logic

- [x] Claims, policies, risk, appeals, premiums, binders, protected breach
      reserves, settlement, denial, and exceptions are core vocabulary and state.
- [x] Farm Mutual offers disclose lane mix, release timing, capacity, premium,
      rider, reserve impact, and breach charge before signature.
- [x] Simulation state is authoritative; UI, browser narration, and office props
      only render snapshots or emit intent.
- [x] Consequential files show a stable claimant name, incident, requested
      remedy, and human cost of delay.
- [x] A clean fast denial returns the same named claimant in the next shift's
      Appeals tray, preserving the source file and correspondence.
- [x] Settlement protects the claimant at a cash cost; denial favors bureau
      closure at higher shell/audit/worker cost; exception protects the claimant
      with slower handling and a smaller cash cost.
- [x] Farm Mutual is consistently the bureau's insurance client. Claimants are
      the farmers/flocks seeking coverage; internal Egg Yield copy remains
      distinct from customer-facing terms.
- [x] The FILE tab keeps Standard, Settlement, Fast Denial, and Coverage
      Exception readable without simulating legal paperwork.

Evidence: `claim_state.gd`, `department_simulation.gd`,
`claimant_resolution_test.gd`, `market_contract_*_test.gd`, and
`simulation_persistence_test.gd`.

## Egg yield, risk, and economy

- [x] Eggs are authorized only from completed seated claim work and remain
      visibly distinct as sound, golden, or cracked through grading and review.
- [x] Clean-clutch reward, estimated crack risk, exact dollars, protected
      reserves, standing, welfare, and decision effects are disclosed.
- [x] Recovery controls include reserve-safe spending, standard-book fallback,
      Farm Treasury credit and repayment, arrears visibility, retriable probation,
      and prior-year recovery guidance.
- [x] Sound work earns trust and contract value; cracked work creates rework and
      exposure; golden work increases value while inviting farmer credit theft.
- [x] Feed Fund, protected reserves, Farm Mutual standing, welfare, compliance,
      favor, and exposure have separate uses and gates.
- [x] Deterministic balance profiles prove quality, welfare, capacity, contract,
      and recovery strategies remain viable without raw throughput dominating.
- [x] Capacity and queues are bounded, prices use integer cents, and expansion
      adds decisions, obligations, and physical capability rather than idle wait.

Evidence: `campaign_balance_playthrough_test.gd`, `farm_treasury_state_test.gd`,
`farm_treasury_department_test.gd`, `market_contract_economy_test.gd`, and exact
commissioning/settlement receipts.

## Flock management

- [x] Each hen has a name, role, live state, condition, desk, specialty, career,
      temperament, accessory set, work history, and nearest-perchmate bond.
- [x] Fatigue, stress, morale, grievance, trust, welfare, solidarity, and career
      state alter pace, shell risk, recovery, petitions, or personnel outcomes.
- [x] Wellness Nest, Training Roost, Feed Party, hiring, separation, perch
      authorization, reassignment, promotion, and manager staffing have visible
      and mechanical consequences with exact costs.
- [x] Hens cannot process files or lay eggs while walking, attending wellness or
      feed events, training, or otherwise away from the assigned chair.
- [x] Manual routing engages each hen's disclosed work style; AUTO remains a
      neutral opt-in baseline so identity matters without constant micromanagement.
- [x] Promotion, secondary credentials, reassignment, and manager roles exchange
      productive time or payroll for authority, access, pace, or risk control.
- [x] Care-first play is strategically viable but consumes cash, capacity, time,
      or farmer favor.
- [x] Surveillance, understaffing, overtime, quota pressure, arrears, and denied
      petitions produce persistent stress, grievance, solidarity, compacts, and
      work-to-rule rather than decorative penalties.

Evidence: `temperament_work_style_test.gd`, `personnel_career_test.gd`,
`manager_roster_economy_test.gd`,
`wellness_*_test.gd`, `training_*_test.gd`, and `flock_petition_test.gd`.

## Facilities and progression

- [x] Purchases physically construct rooms, equipment, perches, rails, archive
      capacity, service rooms, and player-owned satellite parcels.
- [x] Facilities serve records, shell grading/rework, flock care, training,
      Farm Mutual service/negotiation, operations, relations, procurement,
      packing, publicity, dispatch, and campus claim routing.
- [x] Capital Blueprint and Campus Portfolio show prerequisites, exact costs,
      upkeep/payroll, capacity, effects, placement, and blocked reasons.
- [x] Each tier unlocks a handling choice, capacity, service, staffing,
      negotiation, care, procurement, dispatch, or governance responsibility.
- [x] The authored five shifts widen from onboarding to a reliable flock,
      contract pressure, labor/institutional complexity, restructuring, and final
      farmer review.
- [x] Office growth becomes physically impressive while increasing surveillance,
      credit appropriation, payroll, exposure, and moral compromise.
- [x] There are no global subsidiaries or prestige resets. The optional Senior
      file adds authored Board Book decisions after the campaign ending and is
      explicitly presented as optional rather than the core completion target.

Evidence: `EXPANSION_ECONOMY.md`, `opening_experience_progression_test.gd`,
`facility_*_test.gd`, `campus_*_test.gd`, and physical purchase reveal tests.

## Corporate satire and environmental storytelling

- [x] Flockwatch, Peckwork Routing, Egg Yield Bureau, and Farm Mutual form one
      coherent vocabulary across UI, narration, state, and environmental signs.
- [x] Grading, collection, farmer review, closing credit, and the Harvest Credit
      Gallery make credit theft physical and persistent.
- [x] Mounted bulletin notices, room plaques, nameplates, desk props, stamps,
      evidence packets, archive boxes, closure boards, and propaganda replace
      floating exposition.
- [x] Overview and detail cameras preserve the cheerful low-poly diorama and
      suppress sub-pixel copy without erasing physical fixtures.
- [x] The claims floor now repeats claimant correspondence, a denial stamp,
      returned-appeal archives, redacted evidence, and an authoritative claim
      closure board alongside lane folders and the grading system.
- [x] Gallery plaques convert a named hen's frozen contribution into a farmer or
      management achievement.
- [x] Wellness provides real recovery while utilization, attendance, resilience,
      and management reporting expose its capture.
- [x] Every joke that carries a mechanic has a plain-language preview, exact
      effect, receipt, or accessible status.
- [x] Incidents escalate from efficiency theater and credit disputes to
      surveillance, labor cases, claimant harm, restructuring, and systemic
      incentives without treating cruelty as the punchline.

Evidence: `office_storytelling.gd`, `environmental_signage.gd`,
`office_storytelling_test.gd`, `office_signage_test.gd`,
`farmer_relations_gallery_*`, and the live desktop browser pass.

## Interface, input, and onboarding

- [x] Shift state, target, clock, controls, and focused-hen actions remain visible
      without covering the office.
- [x] Flockwatch is collapsible and closes for focused inspection.
- [x] Contracts, personnel actions, claimant paths, and purchases expose exact
      terms before commitment.
- [x] Pause, 1x/3x/10x speed, keyboard, mouse, controller, one-finger pan,
      pinch/explicit zoom, portrait, landscape, and desktop layouts are supported.
- [x] First Clutch teaches inspect, route, peckwork, risk, Priority Peck,
      delivery, farmer collection, reinvestment, and handoff through play.
- [x] Dense planning lives in dossiers, disclosures, Flockwatch pages, and
      inspectors rather than permanent HUD panels.
- [x] Alerts expose priority, reason, action, dismissal or acknowledgement, and a
      bounded history. Transient floor notices persist an All, Priority Only, or
      Shift Record Only preference without deleting the underlying record.
- [x] Corporate copy remains playful while objectives, values, deadlines, blocked
      reasons, and exact effects remain unambiguous.
- [x] Remapping, reduced motion/sensory effects, independent sound controls,
      text scale, color-vision modes, semantic narration, and non-rapid control
      alternatives are available.

Browser evidence: 390x844 portrait, 844x390 landscape, and 1280x720 desktop
showed contained 16:9 canvases and no horizontal overflow; visible mobile controls
were 40px high.

## Audio and presentation

- [x] Sound, golden, and cracked grading; purchase/denial; Feed Party; peckwork;
      collection; incidents; and farmer review use distinct semantic cues.
- [x] Music, office ambience, mechanical pressure, farm sounds, SFX, and UI buses
      preserve the diorama presentation with independent controls.
- [x] Late quota pressure, stress, and overtime raise machinery/alert layers;
      review and calmer conditions create space in the mix.
- [x] Recurring farmer verdict cadences and optimistic announcements become more
      ominous as incentives and consequences accumulate.
- [x] High-value outcomes use bounded lights, particles, trails, receipts, and
      audio pooling rather than unbounded effects.

Evidence: `office_audio_director.gd`, `office_audio_feedback.gd`,
`office_atmosphere.gd`, `audio_feedback_test.gd`, and
`office_audio_director_test.gd`.

## Reliability, saves, and verification

- [x] Finance, contracts, campaign, flock, claim paths, facilities, and campus
      state are deterministic, strictly validated, persisted, and focused-tested.
- [x] Desktop and mobile Web were exercised at the target resolutions above.
- [x] Authored routes and declared facility footprints keep staging collision-free;
      storytelling additions contain no `CollisionObject3D`.
- [x] The deterministic campaign balance matrix passes after the economy and
      claimant-path changes.
- [x] Save/restore coverage spans shift checkpoints, binders, facilities,
      campaign transitions, personnel, claimant paths, and irreversible choices.
- [x] Causal tests connect decisions to work pace/strain, shell risk, grading,
      ledgers/reviews, and later rework, petitions, or named claimant appeals.
- [x] Highest-count staging, hot paths, bounded effect pools, input, readable
      text, and runtime-soak contracts have automated coverage.
- [x] The release gate fails on broken progression, value mismatch, unreadable
      required information, inaccessible input, stale exports, or payload parity.

Release evidence is written to `output/release/core-checklist-beta-release-gate.json`;
the exhaustive isolated Godot result is written under
`output/godot-full-suite-20260725-core-checklist-final/`.

## Deliberate non-goals

- [x] No offline accumulation substitutes for the shift game.
- [x] No paid currency, loot boxes, login streaks, manipulative timers, or
      live-service pressure exists.
- [x] No prestige reset erases campaign consequences.
- [x] Feed procurement, Farmgate dispatch, and campus logistics remain bounded
      claims-bureau responsibilities rather than generic global markets or
      research trees.
- [x] Every expansion adds a decision, obligation, handling capability,
      physical change, or later consequence; a larger number is never its sole
      reward.

## External release activity

Automated tests cover responsive dimensions, synthetic touch paths, software
WebGL, persistence, semantic narration, and deterministic performance contracts.
Representative physical iOS/Android touch feel, screen-reader listening, and
integrated/discrete GPU throughput remain human hardware sign-off items. They are
tracked as external release evidence in `BETA_READINESS.md`, not silently claimed
by the automated gate.
