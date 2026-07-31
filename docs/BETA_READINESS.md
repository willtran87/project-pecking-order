# Pecking Order beta-readiness contract

This document turns the beta-hardening backlog into acceptance criteria. It distinguishes missing implementation from hardware-only validation so release decisions are based on evidence rather than menu count.

## Player experience

1. **Case variety:** six standard incidents form three connected pairs. All twelve responses disclose immediate terms, a future counterweight, and adaptive-casework progress. Probation doctrines, challenge contracts, market files, flock petitions, Flock Relations cases, and seven Senior Board Books provide longer-run variation.
2. **Chicken identity:** all six roster hens have a stable temperament, distinct work/break cadence, career profile, specialty, accessories, manager relationship, and a named nearest-perchmate bond. The bond changes with persistent care, grievance, shared strain, and flock solidarity without adding another currency.
3. **Movement and workstations:** authored routes keep hens out of furniture and desk cuts. Production requires the assigned hen to finish the visible seated transition at her workstation; screen contacts and eggs are rejected otherwise.
4. **Organic expansion:** a four-perch opening grows to six authorized desks, cumulative facilities, North Meadow services/modules, and named campus duties. Construction changes the physical office and operating costs instead of revealing a prebuilt sprawl.
5. **First-session clarity:** the optional First Clutch teaches inspect, route, check-in, Priority Peck, delivery, farmer collection, reinvestment, and handoff through the live controls. It checkpoints each meaningful step and exposes a persistent Skip path for experienced players.
6. **Feedback:** claim pull, screen contact, laying release, grading, collection, credit transfer, precedent filing, commendations, purchases, and denials use causal visual/audio receipts. The selected-hen dossier states the route -> screen -> egg loop in the existing footprint.
7. **Manager satire:** one to four paid managers occupy separate office posts. Six recruitable archetypes, targeted assignments, postures, reports, promotions, payroll, conflicting instructions, density drag, surveillance, PIPs, and credit claims make excess management mechanically legible.
8. **Relationships:** persistent trust, grievance, morale, fatigue, stress, solidarity, petitions, compacts, disputes, career check-ins, and the named perchmate bond connect policy to individual hens and the flock.
9. **Strategy differentiation:** manual/AUTO routing, specialty and accreditation, temperament-specific work styles, claimant resolution paths, directives, check-ins, facilities, contracts, procurement, credit policy, manager postures, and case pivots expose distinct short- and long-term tradeoffs. Farm Mutual's premium posture spends claimant trust and closes below 50 sentiment until fulfilled Mutual or Community Access work rebuilds it, preventing the high-margin/low-volume option from becoming a permanent dominant choice.
10. **Authored ending plus optional mastery:** the five-shift probation file contains the authored campaign ending. A successful file may optionally continue into four-quarter Senior management records with annual Board Books, policy stakes, Roost Marks, cross-training, commendations, mastery-aware offers, and prior-year recovery guidance; none of that delays or replaces the ending.
11. **Intern labor satire:** the Bright-Eyed Rotation introduces four named,
    portrait-backed candidates on Day 2. Supervised assignments provide bounded
    temporary operational effects, every term ends in an explicit player review,
    and permanent conversion adds visible junior payroll to costs and reserves.
    Onboarding and term filings cannot consume money protected for feed, wages,
    facilities, debt, or signed-binder exposure.

## Production quality

12. **Audio:** separate master, music, ambience, SFX, UI, warning/decision, and nonverbal character-cutout cue buses support independent volume/mute controls, reduced sensory motion, semantic cue pooling, focus-safe pause/resume, and adaptive office momentum.
13. **Performance:** optional office wings load lazily, static fixtures are batched, imported animation is sampled manually, hidden hens skip visual rewrites while completing routes, contacts allocate no per-hit nodes/tweens, and runtime diagnostics report node/orphan counts.
14. **Device behavior:** mouse, keyboard, controller, one-finger pan, pinch zoom, explicit zoom buttons, remapping, focus loss, portrait, landscape, 390px phone, standard desktop, and 2560x1600 layouts have automated coverage.
15. **Accessibility:** semantic actions, keyboard/controller focus restoration, global reduced motion, independent camera-motion and particle-density levels, bounded camera sensitivity, color-vision-safe cues, remapping, sanitized live narration, exact 16:9 canvas containment, and no-horizontal-overflow checks are release contracts. Settings exposes one of four persisted categories at a time, supports Left/Right category navigation, narrates only the active group, and remains contained at 150% interface scale with moderately expanded English copy across desktop, compact landscape, and portrait fixtures. Flockwatch's Capital page also clears its vertical scrollbar at 150%, keeps every briefing descendant inside the effective reading viewport, and presents cash, cost, and market information as short ledger rows instead of clipped paragraphs. Capital Blueprint, Campus Portfolio, and Campus Expansion independently pass 390x844, 150%, expanded-copy stress with wrapped headings, shrinkable selectors and controls, vertical-only planning, and every fixed economic action still reachable. Probation intake, between-shift reports, and final review pass the same portrait stress with shrinkable actions, a bounded challenge selector, and vertical-only modal reachability. Farm Mutual's Contract Board passes the same stress while preserving binder selection, pricing, accreditation, terms, negotiation state, and reachable fixed Sign/Decline actions. Facility commissioning and campus authorization/construction receipts also preserve their exact economic ledgers and both held actions under that stress through wrapped columns/headings, vertical-only documents, and responsive fixed rails. Character cutouts preserve their approved portrait, speaker identity, complete thought, filing note, and File Away action under the same stress, with equivalent semantic narration and reduced-motion behavior. This resilience contract does not claim localization support.
16. **Playtestability:** deterministic seeds, challenge contracts, full-probation routes, multi-year matrices, runtime soaks, rendered Office fixtures, and the official browser client make regressions reproducible. Qualitative human playtests remain a release activity, not a code claim. The seven-focus playtest protocol separately measures comprehension, friction, pacing, fun, strategic depth, feedback clarity, and long-session fatigue against the exact candidate.
17. **Balance:** integer-cent accounting, exact effect previews/receipts, authored route matrices, failure controls, atomic rejection, bounded queues/capacity, and deterministic campaign playthroughs protect solvency and strategic viability.
18. **Release safeguards:** verified campaign backup/restore, strict save migrations, direct Pages preference bridging, production serving of the complete Godot payload, synchronized `docs/` and `web/public/game/` payloads, the local beta release gate, and CI Web/parity checks prevent stale, inaccessible, or mismatched deployments.

## Gate commands

Run the complete local gate from the repository root:

```powershell
./tools/verify_beta_release.ps1
```

The gate requires Node 22.13 or newer. When more than one Node installation is present, pass its folder with `-NodeDirectory`. The gate writes a machine-readable report to `output/release/beta-release-gate.json`. The full isolated Godot suite remains available through `tools/run_godot_full_suite.ps1` for release candidates.

The current exhaustive candidate proof is
`output/godot-full-suite-20260730-intern-economy-v2/full-suite-summary.json`: all 212
discovered tests were selected, completed, and passed with zero failures,
timeouts, or engine-error signatures. The runner uses a 240-second per-test
budget because the deterministic multi-career balance matrix legitimately takes
about 143 seconds in isolation; process-tree termination still bounds a hung
test. `campaign_intake_safety_test.gd` is also a permanent representative-gate
contract so shelving must preserve authoritative career state, checkpoint the
current interface context, remain resumable, and retain the prior primary as a
verified recovery copy.

The expanded representative report at
`output/release/intern-economy-beta-release-gate.json` passes all 44 checks,
including the intake contract, Web production serving, evidence-validator
adversarial fixtures, and exact artifact parity. It exercises the same
9,249,172-byte PCK (`SHA-256
49675052C2A69E14F576737DF1F8643ABF98FBB46B27B052180915910068E938`)
inspected by the clean official browser proof at
`output/web-game/internship-system-official-client/` and the zero-error
cohort, dialogue, and paid-fellow captures at
`output/web-game/internship-system-visual/`.

### Current public-deployment disposition

The verified candidate is live on
`https://willtran87.github.io/project-pecking-order/`. GitHub Pages is bound to
the `codex/core-loop-polish` branch's `/docs` directory. The current release
handoff uses a cache-bypassed public download and requires it to match local
`docs/index.pck` exactly:

- local and public `index.pck`: 9,298,612 bytes;
- local and public SHA-256:
  `E6A458BA17056A32C43CD6813BF37C681E594EDF86C83B8A8D1802A73D215C96`;
- exact deployed-payload match: **true**.

The public URL is therefore the approved automated-test candidate. Publication
does not manufacture human evidence: the seven physical sessions and seven
separately moderated usability focuses below remain pending until they are
performed against this exact package.

The current automated evidence is the 212/212 exhaustive native report at
`output/godot-full-suite-20260731-farmer-relations-glance-v1/full-suite-summary.json`,
the 44/44 independent release gate at
`output/release/farmer-relations-glance-beta-release-gate.json`, and the exact
production-wrapper capture at `output/farmer-relations-web-client-v1/`.
Fourteen required candidate-bound sessions remain pending: seven physical
touch/screen-reader/listening/GPU sessions and seven separately moderated
usability focuses. No stale result is counted as a pass.

## External-only evidence

The repository can automate touch event paths, responsive layouts, software WebGL, persistence, audio state, and accessibility narration. Final sign-off still requires representative physical iOS/Android touch interaction, screen-reader/listening checks on real hardware, and integrated/discrete GPU throughput. Those checks cannot be honestly replaced by local simulation.

`docs/PHYSICAL_RELEASE_ACCEPTANCE.md` defines the exact seven-session device
matrix, routes, repetitions, thresholds, evidence bundle, and release decision.
Initialize `output/release/physical-release-evidence.json` against the committed,
deployed candidate, complete all seven schema-v2 sessions, and validate it with:

```powershell
./tools/new_physical_release_evidence.ps1 `
  -TestedUrl "https://REPLACE_WITH_DEPLOYED_RELEASE_URL/" `
  -Coordinator "Release owner"
./tools/verify_physical_release_evidence.ps1
```

The physical gate remains failed until every required session and the final
release decision are explicitly recorded as `pass`. Repository-relative
evidence bundles must exist and match their recorded SHA-256; the standard beta
gate also runs the physical validator's valid and adversarial contract fixtures.
Initialization downloads the deployed root's `index.pck` and refuses to create a
session record unless its hash matches both shipped copies.
`new_physical_release_session_kit.ps1` creates a candidate-bound result and
tester brief for each row. `register_physical_release_session.ps1` then
validates the completed result and local recording/log ZIP, hashes the bundle,
rejects reuse or accidental replacement, and updates the record atomically; GPU
bundles additionally require a renderer screenshot. The beta gate exercises
valid kit creation and registration plus duplicate and incomplete-GPU-bundle
rejection.

Qualitative experience sign-off is independently tracked through
`docs/USABILITY_PLAYTEST_ACCEPTANCE.md`. Initialize its exact candidate record
and validate the completed seven-focus matrix with:

```powershell
./tools/new_usability_playtest_evidence.ps1 `
  -TestedUrl "https://REPLACE_WITH_DEPLOYED_RELEASE_URL/" `
  -Coordinator "Research coordinator"
./tools/verify_usability_playtest_evidence.ps1
```

The validator recomputes task totals and completion rates from the task log,
enforces minimum session duration and focus-specific thresholds, requires
unaided critical tasks and four shared recovery/comprehension capabilities,
content-inspects every local evidence ZIP, verifies bundle hashes and chronology,
and rejects duplicate evidence, open blockers, placeholder signatures, or an
approval recorded before the sessions. The automated beta gate runs both the
valid fixture and nine targeted adversarial mutations; it does not fabricate
the seven required human sessions.

`new_usability_playtest_session_kit.ps1` generates the focus-specific task log
and moderator brief with the exact commit/PCK identity. After a session,
`register_usability_playtest_session.ps1` validates the result and recording/log
ZIP, computes its SHA-256, rejects reuse or accidental replacement, and updates
the record atomically. The beta gate exercises valid kit creation and
registration plus duplicate and incomplete-bundle rejection.

### Release-owner usability disposition

On 2026-07-28, the project owner directed that usability be considered
performed for continued release work. This is recorded as an owner attestation
that closes the prioritization blocker; it is not represented as seven
moderated sessions, invented task metrics, or fabricated recordings. The
structured playtest protocol and validator remain intact for any later
evidence-backed study or stricter distribution requirement.

### Staffing and irreversible-action resilience

The between-shift probation report now exposes Roost Requisitions only after
the authoritative closing-credit gate opens staffing planning. The report is
suspended while Flockwatch is foregrounded and restored exactly when the ledger
closes, preventing the staffing economy from being hidden behind an otherwise
terminal report. Automated coverage also verifies the live Flock staffing page
at 150% interface scale with expanded copy and the release confirmation at
390x844, including reachable cancel/confirm actions and confirm-once semantics.

Senior Career Sponsorship now follows the same standard: its complete form
reflows at 390x844 and 150% scale, and its irreversible filing is separated from
routine selection by a bounded confirmation. The confirmation names the hen and
alternate specialty and repeats exact mark, Feed Fund, next-shift throughput,
and permanent wage consequences before any authoritative mutation.

Rooster Operations also passes the compact economic-action contract. Four
manager cards, their assignment and posture controls, and the screened successor
slate remain horizontal-scroll-free at 390x844, 150% scale, and expanded copy.
Candidate terms come from the authoritative simulation projection and state the
exact signing cost, replaced rooster, manager count, before/after payroll, and
zero egg output. Opening the appointment confirmation changes no Feed Fund or
roster state; cancel preserves the incumbent and one confirmation replaces the
newest post exactly once.

The recurring Operations filings now carry the same scale contract. Feed
Procurement and Farmgate Dispatch are tested at their real 282-pixel Flockwatch
width with 150% interface scale and expanded copy. Their title and live quote
each receive a full readable row; shared disclosure controls, route choices, and
fixed actions trim safely without hiding the exact quantity, price, capacity,
quality, availability, or receipt terms shown beside them. The Farmgate GPU
proof confirms the selected route and authorization remain readable end to end.

Flock Relations now treats a labor disposition as an irreversible personnel
filing rather than a routine button. Funded remedies, mediation, coercive PIPs,
and arbitration use full-width compact actions and a confirmation that repeats
the named hen, case, exact cost, trust/grievance/compliance or favor effects,
permanent-record consequence, and irreversibility. Cancel mutates nothing,
confirm traverses the real Office authority once, stale disabled actions fail
closed, and the complete filing remains readable at 282px and 150% scale.

Farmer Relations now applies the same deliberate review to public credit.
Selecting Layer Profile, Clutch Results, or Farmer's Method opens a confirmation
that repeats the named subject, attribution, frozen evidence, exact cost,
payout, net Feed Fund effect, standing change, permanent day record, and
irreversibility before Office receives an intent. Cancel and stale inputs mutate
nothing; one confirmation publishes once. The stacked gallery header, wrapped
records, and clipped full-width campaign actions remain horizontal-scroll-free
at the real 282px filing width and 150% scale with expanded copy, while both
confirmation choices remain reachable at 390x844.

## 2026-07-30 exact First Clutch benefit candidate

The current local candidate contains the benefit-first First Clutch
reinvestment copy, Mabel-specific consequence dialogue, and the Windows
production-wrapper static asset fallback. Its synchronized `index.pck` is
9,251,636 bytes with SHA-256
`D0C4FBDF95C5CF3F96582D6A519ECA21919C24E42E2AA8FE86B3DF64A20A819D`.

Candidate-wide automated evidence is current:

- `output/godot-full-suite-20260730-first-clutch-benefit-safe-v1/full-suite-summary.json`
  discovers, selects, completes, and passes all 212/212 Godot contracts with
  zero failures and zero timeouts using three safe-contention shards.
- An earlier six-shard attempt produced eleven banner-only process failures or
  timeouts under host contention. Every affected contract passed sequentially
  at `output/regression/full-suite-nonpassing-isolated-v1/shard-summary.json`;
  the clean three-shard aggregate is the release evidence.
- `output/release/first-clutch-benefit-beta-release-gate.json` passes all 44
  representative native, Node 24 Web, production-server, validator, and
  artifact-parity checks.
- The corrected production wrapper boots through the independent browser
  client without console or page errors at
  `output/web-game/goal-first-clutch-benefit-official-v3/`.

Commit `f04c50cd3affe7b64b651ce01e102510d9758cba` is now the public release
identity. The GitHub Pages build completed successfully, and a cache-bypassed
download returned the exact tested 9,251,636-byte PCK with SHA-256
`D0C4FBDF95C5CF3F96582D6A519ECA21919C24E42E2AA8FE86B3DF64A20A819D`.

`output/release/objective-completion-audit-f04c50c.json` records the exact
objective, candidate, report, browser, deployment, and evidence identities.
Exact-candidate handoff records and all fourteen session kits are available at
`output/release/physical-release-evidence-f04c50c.json`,
`output/release/usability-playtest-evidence-f04c50c.json`,
`output/release/physical-session-kits-f04c50c/`, and
`output/release/usability-session-kits-f04c50c/`.

Automated implementation gates and release identity are current. Final
production readiness remains open: all seven physical sessions and all seven
independently moderated usability sessions are still pending. No owner
attestation or automated fixture is represented as those fourteen results.

## 2026-07-31 glance-first candidate

The working candidate reduces the highest-density intake, first policy,
Capital, Farm Mutual, recurring incident, core routing, intern staffing,
Flock Relations, Farmer Relations, and end-of-shift result surfaces through progressive disclosure
while preserving their exact economic
rules and complete assistive narration. The first policy now leads with one
action, three scored objective tiles, and three `HELPS / RISKS` cards; exact
effects appear only after a card is selected. Every standard incident now uses
a short action, live cost, and two directional stakes on its choice cards;
selection reveals the exact numeric effects and next-case precedent. Hen routing
now uses the unclipped one-word actions `AUTO`, `NEST`, `PREDATOR`, and
`APPEALS`; full lane names and operational tradeoffs remain in tooltips and
assistive narration. The Bright-Eyed Rotation now exposes seats, production
effects, candidate cost/term, and assignment stakes as compact tokens. Its term
review keeps `EXTEND`, `LETTER`, and `HIRE` visible together with live costs,
while full profiles, filing terms, recurring payroll, and unavailable reasons
remain on demand. The shift result leads with four tiles
(`EGGS / TARGET`, `NET`, `FEED FUND`, and `NEXT TARGET`), one shell-quality
line, one human consequence, and one Continue action; the complete accounting
remains behind `DETAILS`. The repeated Capital-file control now uses the fitted
action `REVIEW/HIDE FILES / <ready>`; total, ready, and completed requisition
counts remain in its tooltip and accessibility copy. Farm Mutual rate choices
now compare `MUTUAL`, `ACCESS`, and `EXECUTIVE` through price, file volume, and
one selected `MARGIN / TRUST / REACH` line; full pricing mechanics and held
reasons remain in tooltips and assistive state. Flock Provisions now leads with
`STOCK`, `NEED`, `AFTER`, and `SPOT` tiles,
then one automatic-buy line and the action `REVIEW/HIDE FEED / <ready>`.
Supplier files use `LOCAL`, `BULK`, and `FUTURE`, compact quantity/cost/life
terms, exact ration tokens, one `READY/HELD` state, and one `BUY` action; full
supplier copy, unit price, expiry, authorization, and history remain in
tooltips and assistive diagnostics. Baseline rations add no zero-value row.
Flock Relations now leads with `OPEN` and `REVIEW` tiles, one unresolved-case
cue, a named hen plus stable case token, and a 2x2 evidence grid. Its 2x2
`REPAIR / MEDIATE / PENALIZE / RULING` actions preserve exact available costs
while complete docket, evidence, effect, held-reason, authority, and
permanent-record terms remain in tooltips, assistive state, confirmation, and
the diagnostic snapshot. Farmer Relations now leads with
`STAND / POINTS / EGGS / SHELL`, one remaining-campaign line, one named-credit
line, and `LAYER / RESULTS / METHOD` strategy cards. Each strategy compares
`COST / NET / STAND` and exposes one short action; full frozen evidence, payout,
authorization, attribution, and permanent-record terms remain in tooltips,
assistive state, confirmation, and diagnostics. Its synchronized `index.pck`
is 9,298,612 bytes with
SHA-256
`E6A458BA17056A32C43CD6813BF37C681E594EDF86C83B8A8D1802A73D215C96`.

Fresh candidate-wide automated evidence is green:

- `output/godot-full-suite-20260731-farmer-relations-glance-v1/full-suite-summary.json`
  discovers, selects, completes, and passes all 212/212 Godot contracts with
  zero failures and zero timeouts using three bounded shards.
- `output/release/farmer-relations-glance-beta-release-gate.json` passes all 44
  representative native, Node 24 Web, temporary production-server,
  evidence-validator, and nine-file artifact-parity checks.
- The actual production wrapper boots and accepts input without a browser error
  artifact at `output/text-density-web-client-verified/`; final native captures
  for intake, Capital, offers, and pricing are under
  `output/text-density-ux-final/`.
- The exact shift-result route is clean in the final production-wrapper capture
  at `output/shift-review-web-client-v2/`. Native 100% and 150% glance captures
  are under `output/shift-review-glance-v2/`, with the expanded bounded ledger
  at `output/shift-review-glance-v1/day_review_details.png`. Inspection of the
  first Web capture exposed missing Unicode glyphs; those marks were replaced
  with portable ASCII labels and the prescribed client rerun is clean.
- The first policy's native default and selected states are clean at
  `output/opening-density-glance-v2/`. The production wrapper reproduces both
  states at `output/opening-policy-web-client-v1/` and
  `output/opening-policy-web-client-v2/`, with clean diagnostic state and no
  browser-error artifact.
- The first incident's native default and selected states are clean at
  `output/incident-glance-v2/`. The prescribed production-wrapper client
  reproduces both states at `output/incident-glance-web-client-v1/` and
  `output/incident-glance-web-client-selected-v1/`; diagnostics retain the full
  labels, exact immediate effects, selected choice, and precedent, with no
  browser-error artifact.
- Native First Clutch and ordinary routing captures are clean at
  `output/routing-actions-glance-v1/`. The prescribed production-wrapper client
  reproduces both states at `output/routing-actions-web-client-v1/` and
  `output/routing-actions-web-client-normal-v1/`; both states are loaded,
  focused on the intended worker, show all four concise actions, and contain no
  browser-error artifact.
- Native intern cohort, term-review, and paid-fellow states are clean under
  `output/internship-glance-v1/` and `output/internship-glance-v3/`. The
  prescribed production-wrapper client reproduces all three at
  `output/internship-glance-web-client-v1/`,
  `output/internship-review-web-client-v1/`, and
  `output/internship-fellow-web-client-v1/`; every state is loaded, expanded,
  exposes four candidates, retains exact assistive economics, and contains no
  browser-error artifact.
- The corrected Capital-file control is clean in the native capture at
  `output/facility-density-v2/facility_requisition.png` and in the exact
  production-wrapper capture at
  `output/facility-density-web-client-v1/shot-0.png`. The browser diagnostic is
  loaded on Capital, no browser-error artifact exists, and the server stderr is
  empty.
- Farm Mutual Mutual-rate and Access-rate comparisons are clean in native
  captures under `output/contract-pricing-glance-v2/` and in exact
  production-wrapper captures at `output/contract-pricing-web-client-v1/` and
  `output/contract-pricing-access-web-client-v1/`. Diagnostics preserve the
  selected posture, exact premium, file count, and margin; both browser runs
  have no error artifact.
- The Capital Economic Briefing now exposes only `REVIEW NUMBERS` and
  `REVIEW PLAN / <issues>` in its collapsed state. Native evidence is clean at
  `output/economic-briefing-glance-v1/economic_briefing.png`; the prescribed
  production-wrapper client reproduces it at
  `output/economic-briefing-web-client-v1/shot-0.png` with loaded Capital state,
  no browser-error artifact, and empty server stderr. Exact cash/cost/market
  scope and exact bottleneck/recovery counts remain in tooltip and accessibility
  metadata.
- The Farm Mutual contract selector now leads with `PICK A CLIENT`. Its three
  cards use the learned lane identities `NESTING`, `PREDATOR`, and `APPEALS`,
  then show only file count, rush count, win, miss, and `PICKED/HELD` state.
  Native evidence is clean under `output/contract-board-glance-v1/`; the exact
  production-wrapper render is
  `output/contract-board-web-client-v1/shot-0.png`, with no browser-error
  artifact and empty server stderr. Formal binder names, exact lane mixes,
  arrivals, success rules, premiums, breach reserves, staffing fit, and held
  reasons remain in tooltips, assistive metadata, and the selected detail pane.
- Flock Provisions is clean at native 282x760 in
  `output/feed-procurement-glance-v1/feed-procurement-282x760.png`. The exact
  production wrapper reproduces the simplified Operations filing at
  `output/feed-procurement-web-client-v2/shot-0.png`; the diagnostic retains
  all three authoritative offers and live inventory, no browser-error artifact
  exists, and server stderr is empty.
- Flock Relations is clean at native 282x760 and 150% interface scale under
  `output/flock-relations-glance-v1/`, including the irreversible confirmation.
  The exact production wrapper reproduces the live Records filing at
  `output/flock-relations-web-client-v3/shot-0.png`; its diagnostic is loaded on
  Records with one authoritative case and four actions, no browser-error
  artifact exists, and server stderr is empty.
- Farmer Relations is clean at native 282x760 and 150% interface scale under
  `output/farmer-relations-glance-v1/`, including its localization-stressed
  confirmation. The full native Records capture is at
  `output/farmer-relations-ui-glance-v1/farmer_relations_ui.png`; the exact
  production wrapper reproduces the real level-three Gallery offer at
  `output/farmer-relations-web-client-v1/shot-0.png`. Its diagnostic is loaded
  on Records with three authoritative offers and an unused one-campaign
  allowance, no browser-error artifact exists, and server stderr is empty.
- Both verification runners exited normally. The post-run audit found zero
  Pecking Order Godot processes, zero project Node processes, and zero
  project-owned listeners; ports 41750 through 41759 are free.

Existing candidate-bound session records do not certify this PCK. Final
production readiness remains open until all seven physical sessions plus all
seven independently moderated usability sessions are completed against the
exact published artifact.
