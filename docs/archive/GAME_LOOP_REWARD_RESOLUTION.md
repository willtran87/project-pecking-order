# Game Loop and Reward Resolution

This is the implementation record for the 35-item intuitiveness, fun, and
reward checklist. “Resolved” means the game now has a concrete player-facing
contract and automated evidence; it does not claim that unrun human playtests
found the game fun. Human comprehension, retention, and delight remain governed
by `USABILITY_PLAYTEST_ACCEPTANCE.md`.

## Readability and first-session loop

| # | Requested outcome | Resolution | Primary evidence |
|---:|---|---|---|
| 1 | One clear objective | The permanent HUD exposes one actionable next-move button. Its visible copy is short; exact rationale stays in tooltip, accessibility narration, and diagnostics. | `Office._next_action_diagnostic_state`, `management_loop_ui_test.gd` |
| 2 | Five consistent verbs | First Clutch teaches **Inspect → Route → Check-in → Peck → Reinvest** using the real controls and authoritative results. | `first_clutch_coach_ui_test.gd`, `first_clutch_reinvestment_ui_test.gd` |
| 3 | Visible cause/effect previews | Policies, incidents, petitions, routes, upgrades, and strategic filings preview exact effects before confirmation and publish compact post-action receipts afterward. | `decision_loop_ui_test.gd`, action-hold/feedback contracts |
| 4 | Simplified HUD | The live rail contains clock/fund, quota, a conditional clean-clutch cue, current policy, and one next action. Complete ledgers remain in Flockwatch. | `management_loop_ui_test.gd`, `flockwatch_today_density_test.gd` |
| 5 | Progressive disclosure | First Clutch, contextual Flockwatch filings, and management surfaces reveal mechanics only when authoritative state makes them relevant. | onboarding, management, and campaign UI contracts |
| 6 | First successful egg | A named hen’s first file is followed through routing, Priority Peck, grading, physical delivery, cash credit, and one reinvestment decision. | First Clutch economy/UI/integration contracts |
| 7 | Fast-forward to the next moment | **NEXT [4]** / D-pad Up temporarily seeks at 10× and stops safely at a decision, shift review, or open Priority Peck window. It is reversible, remappable, diagnostic, and restores the prior pace rather than leaking 10× beyond the moment. | `office_action_catalog_test.gd`, `management_loop_ui_test.gd` |

## Reward cadence and tactile play

| # | Requested outcome | Resolution | Primary evidence |
|---:|---|---|---|
| 8 | Three-level reward cadence | Immediate egg receipts feed shift reviews, which feed probation rank, ending, commendations, and career archive. The live clean-clutch ladder now names **Steady (2)**, **Rolling (4)**, and **Golden Run (8)** while retaining exact existing cents. | `Office._clutch_reward_ladder_snapshot`, review/campaign contracts |
| 9 | Compact shift ending | Farmer Review opens as a four-tile result glance; accounting and causal detail are disclosed on demand. | `management_loop_ui_test.gd` |
| 10 | Tease the next reward | Clean clutch shows its next milestone, reviews show the next blocker/reward, capital filings tease only the next relevant facility, and mastery cards state their next exact stamp. | management/campus tests, `final_hearing_and_replay_structure_test.gd` |
| 11 | Clutch milestones | Streak thresholds are visible, celebratory, semantic, and derived from the existing capped streak-credit economy. No duplicate reward currency was introduced. | `management_loop_ui_test.gd`, egg grading feedback |
| 12 | Tactile routing | Files move through physical trays, desk queues, folders, quality grading, collection rails, and farmer presentation with route acknowledgements and reversible assignment. | routing and egg-journey integration contracts |
| 13 | Distinct lane identity | Lane colors, shapes, icons, trays, specialty fit, and accessibility labels remain redundant rather than color-only. | routing UI, color-vision, and signage contracts |
| 14 | Priority Peck variants | The single learned Peck input already supports missed, strong, and perfect timing, chain growth, risk changes, delivery-gated recharge, and precision slowdown. Variance lives in timing outcomes, not extra buttons. | Priority Peck economy/UI/focus contracts |
| 15 | Visible comeback | Broken routing momentum exposes a recoverable next action and celebrates recovery; failed filings preserve exact safe recovery paths. | adaptive routing recovery and action-hold contracts |

## Character, incident, and office life

| # | Requested outcome | Resolution | Primary evidence |
|---:|---|---|---|
| 16 | Rare events | Authored docket rotations, petitions, scenario climaxes, Final Hearing, predator pressure, labor disputes, credit disputes, and facility-specific beats provide bounded variety. | incident docket/character arc/final hearing contracts |
| 17 | Physical office reactions | Egg transit, grading, commendations, charter plaques, scenario props, facility state, staffing, breakroom use, and career dressing all react to authority. | Office storytelling and facility visual contracts |
| 18 | Expressive chatter | Sixteen named speakers have authored contextual voice pools plus snapshot-driven production, pressure, review, internship, and return beats. | character dialogue catalog/UI contracts |
| 19 | Spotlight hen | First Clutch, selected dossier, incident subject, frozen shift story, restructuring, and Final Hearing witness keep named hens legible. | hen highlight, character arc, and campaign ending contracts |
| 20 | Relationship callbacks | Trust, grievances, check-ins, case memory, flock petitions, incident pivots, and ending epilogues retain named consequences. | incident follow-through and flock-relations contracts |
| 21 | Celebrations and disappointment | Sound, animation, light, status receipts, hen beats, reviews, milestones, and ending treatments differentiate success, warning, miss, and failure. | feedback orchestra, audio, atmosphere, and ending contracts |
| 22 | Team chemistry | Specialty routing, shared momentum, flock compact, work-to-rule, petitions, morale/stress, collective decisions, and named relationships affect play and presentation. | simulation, routing team-lift, and flock-relations contracts |
| 23 | Personalized advancement | Named hens retain career level, specialty, secondary credentials, sponsorship, physical badges, wage consequences, and ending memory. | personnel career and Career Sponsorship contracts |

## Mastery, progression, and replay

| # | Requested outcome | Resolution | Primary evidence |
|---:|---|---|---|
| 24 | Scenario mastery stamps | Every archived scenario derives three stable stamps: **Clear**, **Flock Safe** (pass with welfare ≥60), and **Gold File** (pass with score ≥80). The final receipt and physical office plaque show progress and the next exact target. | `CareerRunArchive.scenario_mastery`, final hearing and trophy shelf tests |
| 25 | Physical legacy shelf | The twelve-slot commendation cabinet, permanent Final Hearing charter, management-identity color, scenario mastery plaque, and career count make legacy visible in the office. | `career_trophy_shelf_test.gd`, final hearing structure test |
| 26 | Automation by mastery | AUTO routing and staffed facilities remove mastered routine work while manual routes remain explicit overrides and consequential decisions remain player-owned. | routing mastery, IT Coop, and facility contracts |
| 27 | Strategic upgrade bundles | Capital plans, campus parcels, facility chains, Board Books, service binders, and doctrine choices group upgrades around readable strategic identities rather than isolated stat bumps. | capital/campus/Farm Mutual/Senior contracts |
| 28 | Rival beats | Each authored scenario has a deterministic disclosed rival benchmark; reports and endings compare the player without opaque online pressure. | campaign ending and replay structure contracts |
| 29 | Seeded challenge files | Baseline plus six authored scenario seeds and three permanent difficulty contracts provide reproducible alternate openings and climaxes. | career portfolio and campaign balance matrix |
| 30 | Co-op identity | Three persistent local identities now each communicate a promise, ritual, emblem, color, and unique physical signature: living nest plant, brass clutch seal, or joined-perch flags. Identity remains cosmetic and cannot alter economy authority. | `career_portfolio_and_identity_test.gd`, `career_trophy_shelf_test.gd` |

## Friction removal and return play

| # | Requested outcome | Resolution | Primary evidence |
|---:|---|---|---|
| 31 | Adaptive help | First Clutch, next-action diagnostics, missed-route recovery, Priority Peck holds, exact economic holds, and resume guidance respond to current authority and prior mistakes. | first-session, interaction-safety, and action-hold contracts |
| 32 | Icon-first receipts | Stable semantic icons and shapes lead quota, policy, routes, score, egg quality, cash, risk, care, and filing receipts; exact prose remains available semantically. | management UI, notification preferences, and color-vision contracts |
| 33 | One-click returns | Guidance focuses the next safe control, routing remembers its originating goal, Escape returns through owned surfaces, and contextual actions reopen the relevant filing. | management/routing/interaction-safety contracts |
| 34 | Automatic low-value work | AUTO routing, management assignment, facility staffing, dispatch, and presentation coalescing automate routine throughput while preserving meaningful interventions. | routing mastery, campus portfolio, and runtime contracts |
| 35 | Resume recap | Continue restores the authoritative checkpoint and publishes a compact return recap, next safe action, elapsed-time context, and any off-screen delivery recovery without simulating hidden progress. | campaign return recap and checkpoint recovery contracts |

## Authority and validation boundary

- Next Moment changes only requested clock speed and always yields to existing
  decision, review, focus-loss, character-dialogue, and Priority Peck pause owners.
- Clutch milestones are presentation derived from the existing clean-credit
  formula; they create no new payout or save field.
- Scenario stamps are derived from bounded archived run receipts and therefore
  require no save migration.
- Co-op identity remains cosmetic and independent of campaign scoring/economy.
- Automated checks can prove contracts, containment, determinism, persistence,
  and error-free execution. Only the external playtest protocol can prove human
  comprehension, delight, and retention.
