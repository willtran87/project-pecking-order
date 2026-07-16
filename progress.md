Original prompt: The performance visibility menu is blocking some of the screen, make the Claims Division language more farm-like, and add more office detail.

## Current work

- Recompose the HUD so management metrics do not obscure the playable office.
- Replace insurance-heavy labels with a coherent farm-corporate vocabulary.
- Add readable environmental storytelling while preserving chicken navigation routes.
- Re-export and verify the web build at high-resolution desktop, standard desktop, and mobile widths.

## Implemented

- Added a default-collapsed `Flockwatch Ledger` drawer with `V`/button toggle and automatic close during focused inspections.
- Replaced the visible Claims Division vocabulary with Egg Yield Bureau farm-office language across Godot and the web wrapper.
- Added farm panoramas behind all windows, personalized desk props, route-floor wear/markings, wall propaganda, and egg intake equipment without changing movement routes.
- Added regression checks for the collapsed drawer and new environmental story clusters.

## Verification

- All five Godot smoke/layout/presentation/visual test scripts pass.
- Godot Web export and production frontend build pass.
- Automated controls verified: `V` drawer toggle, `Tab` inspection/auto-close, and `Esc` overview.
- Visually checked at 2560×1600, 1440×1000, and 390×844 with no horizontal overflow.

## Follow-up ideas

- Add subtle feather/dust ambience only if the current clean low-poly scene needs more motion.
- Consider moving the Flockwatch drawer into a separate management screen if the metric set grows substantially.

## Egg seating invariant

- Added authoritative workstation-presence tracking between `ChickenView`, `Office`, and `DepartmentSimulation`.
- Morning arrival, wellness travel, and feed-party travel now pause claim pickup, peckwork progress, and laying countdowns until the hen is seated again.
- Egg visuals now originate from the animated Blender `EggSocket` beneath the correct hen instead of a hard-coded chair coordinate.
- Added a fail-closed office guard plus `egg_seating_regression_test.gd` covering morning entry, feed-party departure, paused laying, and seated completion.
- All six Godot regression/smoke tests pass; the Web export, production frontend build, and browser action pass complete without console errors.

## Full visual production pass

- Completed: one-piece watertight puffy chicken torso, grounded feet, feather layering, enlarged manager comb, and tuned organic materials.
- Completed: authored Lay animation, nonlinear peck, blended sit/stand, chair swivel, personality idles, and seated-only production timing.
- Completed: rooster oversight loft, live Flockwatch monitors, visible egg collection/sorting rail, office zone markers, archive wall, intake logistics, and farm-bureau satire.
- Completed: live desk paperwork/stress notices, bounded dust and feather particles, conservative zone lights, quota/overtime alert bars, farmer spotlight, event bursts, and cinematic golden-egg framing.
- Eight Godot smoke/regression tests pass, including collision-free staging and bounded atmosphere checks.
- Completed: final Web export and high-resolution verification at 2560x1600, 1440x1000, and 390x844 with no horizontal overflow; desktop inspection confirms the collection rail clears the hens and the duplicate intake label is removed.

## Environmental signage integration pass

- Replaced camera-facing office copy with 23 physical sign fixtures that share one transform across frame, printable/screen surface, and text.
- Established distinct bureau plaque, paper notice, desk nameplate, machine label, and live screen treatments with restrained outlines and real depth testing.
- Removed floating floor-zone and collection-chain captions; machinery, floor corners, lamps, and props now communicate those systems visually.
- Moved hen state/progress into the screen-space inspection ticker and removed world-space captions from hens, the rooster, and the farmer.
- Added `office_signage_test.gd` to enforce mounted backplates, non-billboarded text, physical scale, hierarchy metadata, and zero raw floating labels.
- Verified the Web build at 2560x1600, 1440x1000, and 390x844 with no horizontal overflow.

## Management gameplay loop pass

- Added an always-visible `ShiftQuotaProgress` objective and `CLEAN CLUTCH` streak readout to the top HUD. Sound and golden eggs grow the streak, award a capped per-egg Feed Fund bonus, and trigger audiovisual feedback; cracked eggs reset it.
- Changed the opening flow to begin paused with contextual `START HERE` guidance so the player can understand the target, inspect the flock, and deliberately start at 1×, 3×, or 10×.
- Added three permanent, five-level Coop Requisitions with rising costs and authoritative simulation effects:
  - **Beak-Friendly Keycaps:** +8% peckwork speed per level.
  - **Shell Integrity Lamp:** -2.5 percentage points of crack risk per level.
  - **Ergonomic Nest Pad:** -10% stress and fatigue gain per level.
- Connected every requisition to physical office feedback at all six workstations: purchased keycap levels appear on the keyboard, QA lamps appear and brighten, and nest pads appear and change color as comfort investment rises.
- Made the Feed Party a guarded once-per-shift event. Repeat purchases are denied without charging the fund, the button communicates availability, and the simulation pauses during synchronized trough attendance before restoring the prior speed.
- Clarified the overtime decision in the interface and simulation: +22% throughput is exchanged for sharply higher fatigue, stress, morale loss, and crack risk, and overtime resets automatically for the next shift.
- Added a modal farmer workday review that pauses the next shift, reports quota performance and egg quality, itemizes quota and quality bonuses plus feed cost, applies a bounded next-quota adjustment, and offers either immediate requisitions or the next shift.
- Added `OfficeAudioFeedback`, an eight-voice pooled procedural SFX system with reusable cues for sound, cracked, and golden eggs, streak pitch lift, approved requisitions, Feed Parties, UI input, and the farmer's review stamp.

## Gameplay loop verification

- Added `progression_system_test.gd` for upgrade transactions and level caps, causal productivity/comfort/quality effects, the once-per-shift Feed Party guard, overtime reset, and workday rewards.
- Added `management_loop_ui_test.gd` for the opening pause, visible real quota, three requisition paths, physical workstation upgrades, paused farmer review, and result/reward copy.
- Added `audio_feedback_test.gd` for the fixed eight-voice pool, procedural cue assignment, and dedicated `SFX` bus routing.
- All three new gameplay-loop tests pass in Godot 4.7 headless mode.

## Final gameplay-loop browser pass

- Corrected the live shift ticker so resuming at 1×/3×/10× immediately replaces the paused message with the real running state; workday review now has its own accounting prompt.
- Clarified the recurring $18 coop charge as `Daily feed` in the farmer review, distinct from the optional once-per-shift $20 Feed Party.
- Reordered and shortened Coop Requisition copy so all three permanent upgrades are visible at the top of Flockwatch without horizontal clipping.
- Enabled initial canvas focus in the web wrapper and added explicit first-shift, speed, and Flockwatch/upgrade instructions.
- Godot 4.7 headless suite passes 12/12 with no warnings; Web export and the Vinext production build both pass.
- Browser-verified the opening prompt, 1× resume, Flockwatch/upgrades, quota/streak feedback, and farmer review at 2560×1600; also checked 1440×1000 and 390×844 with no horizontal overflow.
- The independent web-game client produced and visually validated a clean 1280×720 WebGL canvas capture. Its software-renderer process did not exit before the harness timeout, but the artifact was successfully written and contained no error report.

## Environmental typography and prop-language pass

- Replaced the universal chunky sign template with six physical mounting families: bureau plaque, pinned paper notice, enamel machine plate, clipped cubicle nameplate, suspended notice, and recessed live screen.
- Added typographic hierarchy for two-line notices, plate-authoritative text fitting that can shrink long copy, and dynamic refitting for the live yield and intake screens.
- Consolidated three scattered policy jokes into a framed cork bulletin board, moved the wellness notice flush to the left wall, shortened overview-scale copy, and removed duplicate presentation/safety backplates.
- Added physical details that communicate context without more copy: paper index tabs and pins, screen scanlines/status lamps, machine brackets, partition clips, hanging rods, letterpress depth, and a bureau egg seal.
- Added focused back-wall and left-wall art captures for signage review; the close views confirm readable copy, correct perspective, and attachment to the surrounding architecture.
- Expanded `office_signage_test.gd` to enforce every mounting family, dynamic screen refitting, bulletin-board clustering, wall attachment, and absence of duplicate backing geometry.
- Full Godot 4.7 regression suite passes 14/14; Web export, Node 22 frontend build, and lint all pass.
- The required independent WebGL client produced a clean boot capture with no error artifact; interactive browser checks selected a policy, ran through an incident, and returned to a paused office with no console errors.
- Responsive browser verification passes at 2560×1600, 1440×1000, and 390×844 with zero horizontal overflow; the normal-size game tab is left paused on the unobstructed office view.

## Policy, incident, and environmental-text pass

- Replaced the passive first-shift start with a required morning briefing: Record Harvest, Shell Assurance, and Sustainable Flock each create a distinct throughput, quality, welfare, and feed-cost strategy.
- Added two rotating, auto-pausing office incidents per shift with atomic Feed Fund costs, explicit consequence previews, resume/stay-paused controls, and satirical outcomes.
- Centralized the lifecycle as briefing → running shift → incident → running shift → farmer review → next briefing, including clock guards so time cannot advance behind a decision.
- Added a reusable full-screen decision card, full-screen farmer-review scrim, active-policy HUD badge, contextual guidance, disabled behind-modal shortcuts, and three new procedural decision cues.
- Rebuilt environmental text fixtures with fitted world-scale type, recessed mounts, layered frames, header rules, fasteners, screen lamps, and machine brackets so copy shares the office's material and perspective language.
- Updated the web onboarding to teach policy selection and confirmation before speed controls, then explain incident auto-pauses and the 5:00 PM credit harvest.
- Added pure simulation and Office integration decision tests and updated existing lifecycle tests; the full Godot 4.7 headless suite passes 14/14.
- Web export, the Node 22 Vinext build, and native 1280×720 policy/incident/review captures pass.
- Browser interaction confirms card selection, consequence preview, authorization, 1× start, and the persistent policy badge; the independent WebGL capture completed with no console-error report.
- Responsive verification passes at 2560×1600, 1440×1000, and 390×844 with no horizontal overflow; desktop coaching wraps inside the terminal and portrait mobile now directs players to full-screen landscape play.

## Peckwork routing and physical-credit pass

- Replaced the undifferentiated claim counter with three authoritative queues: Nest Damage, Predator Loss, and Appeals. Claims carry exact values, deadlines, overdue state, and deterministic rework consequences.
- Gave every hen a specialty and persistent AUTO/manual assignment. Matched work moves faster and cracks less often; mismatched emergency routing is slower and riskier, turning staffing into a real management choice.
- Added an always-visible queue strip and a selected-hen dossier with specialty, current file, progress, value, deadline, and estimated crack risk. Desks echo their active lane through restrained screen and tray color.
- Staged egg value through the physical sorter and presentation rail. The sorter now grades the egg, pulses the matching quality lamp, prints a mounted receipt, and withholds Feed Fund credit until the farmer actually receives it.
- Expanded the farmer review with lane throughput, overdue peckwork, and rework accounting so operational shortcuts survive into the shift report.
- Added focused routing and grading captures plus `claim_routing_test.gd`, `claim_routing_ui_test.gd`, and `egg_grading_feedback_test.gd`. The complete Godot 4.7 suite passes 17/17; Web export, frontend tests, lint, and production build pass under Node 22.
- Browser-verified policy selection, a live shift, incident resolution, paused office presentation, and responsive containment at 2560×1600, 1440×1000, and 390×844 with no horizontal overflow or console errors.

## Five-shift probation campaign and persistence pass

- Converted the endless vertical slice into a deterministic five-shift probation campaign with New/Continue intake, three authored orders per shift, a 0-100 cumulative score, five ranks, early termination, and an explicit final pass/fail review.
- Preserved the detailed farmer accounting screen, then added a second strategic report for cumulative flock welfare, coop obedience, farmer favor, next-shift orders, and campaign rank.
- Added a mandatory specialization after shift two: Padded Perches permanently reduce strain, Shell Quality Lab permanently lowers crack risk, or Farmer Credit Line adds value to every credited egg.
- Added a compact `DAY x / 5` probation badge and a `PROBATION ORDERS` section in Flockwatch so short-term work and long-term stakes remain visible during play.
- Added versioned JSON campaign persistence with validation, temporary-file verification, known-good backup recovery, and migration support. Saves include exact simulation RNG state, active claims, worker progress, decisions, upgrades, campaign unlocks, review stage, and cumulative campaign history.
- Added automatic checkpoints after consequential decisions, routing assignments, upgrades, Feed Parties, overtime changes, credited eggs, workday completion, milestone selection, and next-shift planning.
- Added a passing `Senior Roost` continuation and a clean retry path for failed probation files.
- Updated the browser wrapper to teach the five-shift file, daily orders, autosave/Continue, shift-two specialization, and final review without displacing the existing routing tutorial.
- Added campaign state, save-store, simulation round-trip, unlock-effect, and standalone campaign-UI regression coverage; updated the decision-loop UI test for the new two-stage review flow.
- Full Godot 4.7 regression suite passes 23/23. The campaign UI harness covers 1280x720, 2560x1600, 1440x1000, and 390x844; the Office integration test exercises two real shifts, exact-once recording, milestone gating, causal unlock application, primitive JSON round-trip, and isolated save cleanup.
- Godot Web export, Node 22 production build, 2/2 rendered-wrapper tests, and lint all pass. The required independent WebGL client produced a clean live policy-card artifact without an error report; its SwiftShader process exceeded the harness timeout only after writing the artifact.
- Browser-verified New Campaign, policy selection/authorization, exact live-state autosave, reload/Continue restoration, a clean console, and responsive containment at 2560x1600, 1440x1000, and 390x844 with no horizontal overflow. The normal game tab is left open at the restored paused office.

The next major systems milestone is persistent worker relationships and individual career arcs, followed by hiring/firing and office expansion. Those systems remain intentionally unclaimed.

## Environmental typography integration correction

- Replaced the oversized framed slogan card with a shallow architectural `EGG YIELD BUREAU` fascia, bureau seal, department line, and restrained motto so permanent identity now belongs to the back-wall trim.
- Added a shared environmental house-type system using cached font variations: condensed institutional display type, compact live-data type, document headings, and utility labels no longer reuse the HUD's unmodified default appearance.
- Added host-integrated headers for the yield pipeline, Hen of the Month frame, and rooster department beam. These inherit their existing physical object instead of placing a second framed card over it.
- Rebuilt policy and safety notices as millimetre-thin pinned sheets with registration tabs, rules, seals, readable headlines, varied paper angles, and lower-contrast fine print.
- Moved wall copy onto the actual wall plane, replaced the unsupported rooster/feed hanging signs, added a real support stand to the intake ledger, thinned desk plaques, and limited personal desk color to a small accent tab.
- Restyled the transient grading readout with the same machine/screen typography and removed its heavy HUD-like outline.
- Expanded `office_signage_test.gd` to enforce house typography, physical-host declarations, thin paper, architectural identity, supported screens, and the absence of disconnected suspension rods; updated office-detail coverage for the new identity fixture.

## Environmental typography verification

- Native close views confirm the bureau fascia, rooster header, live screens, pipeline heading, pinned bulletin documents, safety/wellness notices, desk plaque, and grading readout all share the office's perspective and material language.
- Full Godot 4.7 regression suite passes 23/23; focused signage/detail/storytelling/visual/presentation/layout tests all pass.
- Godot Web export, Node 22 production build, 2/2 rendered-wrapper tests, and lint pass.
- Live in-app WebGL verification completed from New Campaign through policy authorization into the running office; the browser console is clean and the updated game tab is left open.
- The independent SwiftShader client stalled before writing its usual artifact, so its result was not counted; native rendered captures and the live Chromium WebGL canvas were inspected directly instead.

## Follow-up

- Preserve the new overview hierarchy: only bureau identity and zone headers should be high contrast; exact metrics and policy consequences belong in management UI or close-focus screens.
- The next gameplay systems milestone remains persistent worker relationships and individual career arcs, followed by hiring/firing and office expansion.

## Persistent hen careers and relationships

- Added deterministic career profiles for all six hens: Credit Conscious, Advancement Minded, and Quota Conditioned. Every worker now persists career XP, title, manager trust, grievance, and her last personnel action.
- Added four visible career tiers from Junior Claims Hen through Principal Shell Adjuster. Completed work awards quality-weighted XP; promotions improve throughput and shell quality while higher titles also carry a small strain burden.
- Added one flock-wide personnel check-in per shift through the selected-hen dossier: share basket credit, fund perch-side coaching, or authorize a stretch clutch. Profile matches are visible and improve the corresponding outcome.
- Made all three choices causal: credit improves the relationship but costs Feed Fund and farmer favor; coaching exchanges current speed for XP and safer shells; quota pressure produces an immediate speed/favor gain while creating lasting grievance, strain, and crack risk.
- Existing policy choices, incident responses, Feed Parties, and worked overtime now alter trust and grievances, so the flock remembers the broader management style instead of only the explicit check-in.
- Expanded the dossier and farmer review with career, profile, trust, grievance, check-in state, and the filed personnel outcome without increasing the dossier's 112-pixel footprint.
- Bumped the nested simulation checkpoint to v2. Legacy v1 saves migrate deterministically, and mid-shift saves preserve the global one-action guard and exact individual career state.
- Full Godot 4.7 regression suite passes 24/24, including deterministic profile/career causality, atomic one-per-shift personnel actions, v1-to-v2 migration, exact persistence, authoritative dossier routing, and the two-shift campaign integration path.
- Godot Web release export, the Node 22 Vinext production build, 2/2 rendered-wrapper tests, and lint all pass without warnings or errors.
- Live in-app WebGL verification completed from New Campaign through policy authorization and incident handling into a selected-hen dossier. Filing Mabel's profile-matched Share Credit check-in visibly raised XP and trust, recorded `FILED / MABEL`, and disabled the remaining personnel actions; the browser console is clean and the game is left paused on that result.

## Roost staffing, capacity, and operating reserves

- Converted the fixed six-hen opening into a four-hen probation roster with two persistent applicants and six stable career files/desks.
- Added review-only capacity authorization from four to six perches, exact hire/release costs, one staffing action per planning day, a three-hen minimum, release cooldowns, and persistent career/relationship history across employment changes.
- Added daily payroll, capacity-dependent facility costs, active-roster feed costs, protected spendable Feed Fund, carried wage arrears, and exact trust/morale/grievance consequences when wages are not fully paid.
- Added the compact `ROOST STAFFING` dossier inside Flockwatch with headcount/capacity, reserved obligations, spendable funds, applicants, wages, authoritative disabled reasons, capacity purchase, hire, and release controls.
- Added physical pending-perch staging, capacity-gated desk visibility, dynamic occupant/vacancy nameplates, hired-hen arrival/spawn, and released-hen routed departure/removal.
- Bumped nested simulation persistence to v3 with chained v1→v2→v3 migration and strict employment/capacity/desk validation. Legacy six-hen saves remain grandfathered.
- Added staffing economy, persistence, and Office UI regression coverage, including exact reserves/costs, applicant isolation, arrears, capacity reveal, dynamic spawn, and staffing checkpoints.

## Environmental signage fit correction

- Recast the bureau identity as the room's sole gold landmark and demoted Flockwatch to a dark equipment header so two competing sign bands no longer read like HUD panels.
- Rebuilt environmental type at a 64-pixel glyph raster while preserving world scale, then used real font metrics and role-based face fill to keep copy crisp and contained.
- Removed fake offset drop-shadow slabs. Paper is now 2.5 mm thick, pinned close to its host, subtly varied and rotated; laminate room plaques, enamel equipment plates, cubicle clips, hosted headers, and live screens each use distinct physical mounting.
- Reduced text-to-surface gaps to 2–4 mm, kept non-screen copy physically shaded and depth-tested, and added hierarchy-based distance fading so small utility copy recedes at the office-wide view.
- Simplified body copy to sentence case, made the bulletin layout less symmetric, turned Wellness Roost into a compact wall plaque, and replaced dark desk tags with smaller light-laminate nameplates.
- Kept development captures out of the Web export with `captures/.gdignore`.

## Staffing and signage verification

- Full Godot 4.7 regression suite passes 26/26, including mounted-signage, office-storytelling, management-loop, staffing-economy, staffing-persistence, and staffing-UI coverage.
- Godot Web release export, Node 22 Vinext production build, 2/2 rendered-wrapper tests, and lint all pass.
- Native overview and focused left/back-wall captures confirm that signs share furniture/wall perspective and materials while secondary copy recedes.
- Live WebGL verification passed at 2560x1600, 1440x900, and 768x1024 with exact 16:9 canvas geometry, no horizontal overflow, and a clean browser console. The normal 1280x720 game tab is left open on the current build.

## Signage regression audit

- Re-ran the focused mounted-signage, office-detail, office-storytelling, visual-systems, presentation, and circulation suites; all six pass on the current tree.
- Inspected the current back- and left-wall native captures. They expose a perceptual gap not covered by the structural tests: much of the copy is still too small and low-contrast at gameplay distance, and the left wall reads as a cluster of paper rectangles before it reads as part of the room.
- Existing tests cover physical mounting, depth, type families, dynamic screen fitting, and the absence of floating labels, but do not cover projected gameplay-distance legibility, static-copy fitting, sign-density budgets, or relative overview hierarchy.
- Follow-up visual verification should include the default overview, both existing wall close views, a new intake/right-wall close view, a workstation/nameplate close view, and the Feed Social event sign at desktop and portrait browser sizes.

## Environmental text perceptual-fit pass

- Rebuilt the back-wall identity as a larger high-contrast teal-and-brass architectural fascia, shortened its department line, and turned the center fixture into a visibly supported picture light.
- Added an orthographic-camera detail hierarchy: the wide office view shows landmarks, room headers, and live equipment only; document body copy and utility labels appear during focused inspection instead of collapsing into sub-pixel noise.
- Corrected the shared left-aligned `Label3D` origin so paper and screen copy now begins at the printable/glass inset rather than occupying only the right half of its prop.
- Gave hosted headers a dark silk-screen band, strengthened the Flockwatch beam and live ledger, and increased type weight/face fill without using billboards or screen-space sizing.
- Changed repeated desk labels to dark engraved partition plates. Their lettering hides at overview and becomes readable on hen focus.
- Moved pending-perch copy onto enamel plates attached directly to the boxed-perch crates, replacing the unsupported paper notices.
- Mounted the bulletin board closer to the wall, narrowed it to preserve blank wall between the Wellness Roost and Yield Pipeline clusters, and tightened the notice copy.
- Added dedicated native capture hooks for desk/nameplate and intake/right-wall review alongside the existing overview, back-wall, and left-wall views.

## Environmental text verification

- Full Godot 4.7 regression suite passes 28/28, including new signage assertions for overview/focus detail visibility, title hierarchy, screen alignment, hosted material bands, bulletin spacing, picture-light support, and attached capacity plates.
- Godot Web release export, Node 22 frontend tests (2/2), lint, and production build all pass.
- Native captures inspected: `vertical_slice.png`, `signage_back.png`, `signage_left.png`, `signage_desk.png`, and `signage_intake.png`.
- Live WebGL verified through New Campaign, policy authorization, running overview, incident resolution, hen focus, and return to overview. Checks pass at 2560x1600, 1440x900, and 768x1024 with no horizontal overflow or browser console warnings/errors.
- The independent SwiftShader harness produced a clean 1280x720 boot artifact plus `render_game_to_text` state and no error file. Its longer input choreography still exceeds the software-renderer timeout, so interaction coverage comes from the live browser pass.

## Follow-up ideas

- If environmental inspection becomes a dedicated feature, add clickable wall hotspots that focus the bulletin board and live ledgers; the current hierarchy intentionally keeps their fine print nonessential.
- A future authored-font asset pass could further distinguish institutional headings, paper forms, and mono equipment screens, but it is no longer required to make the signage feel physically integrated.

## Priority Peck and campaign-climax pass

- Added three authoritative Priority Pecks per shift. Only a seated, employed hen working a real active claim can receive one; the timing score comes from authoritative claim progress and one claim cannot be stamped twice.
- Added a gold timing window to the selected-hen dossier, semantic `E`/gamepad input, overview recommendation, connected three-peck character feedback, desk/screen pulses, synthesized audio, streak guidance, and clean-credit chain rewards.
- Priority Peck progress caps below completion, so the intervention cannot bypass laying, physical egg grading, or farmer collection. Its quality modifier remains attached to the exact claim and is persisted in schema v5.
- Corrected discretionary affordability to use protected spendable funds in the personnel, requisition, and Feed Party interfaces.
- Added the guaranteed Day-4 Flock Restructuring dossier. It freezes the Pecking Order, nominates the lowest-ranked hen, and exposes specialty, career, trust, grievance, fatigue, stress, and management context omitted by the ranking.
- Implemented three causal resolutions: nominate the hen as the variance, fund redeployment into her specialty, or contest the ranking collectively. Separation/replacement behavior, flock consequences, funds, quota, favor, compliance, and solidarity are authoritative and persisted.
- Added branch-specific final records and endings: `FARMER'S FAVORITE`, `BENEVOLENT ROOSTER`, `THE FLOCK HAS A VOICE`, plus a distinct failed-probation coda. Final titles wrap safely in a 390x844 portrait viewport.
- Kept office copy in its established physical hierarchy: permanent dimensional bureau identity, mounted room/equipment plaques, clustered pinned notices, engraved desk plates, and recessed live data screens. No camera-facing world labels were reintroduced.

## Priority Peck and climax verification

- Full Godot 4.7 headless suite passes 32/32, including new Priority Peck simulation/UI, Flock Restructuring simulation/persistence, and campaign-ending UI coverage.
- Native 1280x720 captures inspected for the gold Peck window, Flock Restructuring dossier, branch-specific final review, overview, back wall, left wall, desk signage, and intake signage.
- Godot Web release export, Node 22 Vinext build, 2/2 rendered-wrapper tests, and lint all pass.
- Live in-app Chromium verification confirms the 1280x720 Godot canvas loads through WebGL 2, the page has no horizontal overflow, the updated `E` guidance is present, and the browser console has no warnings or errors.

## Causal shift-report retention loop

- Refactored campaign scoring around five authoritative component groups: probation orders, daily clutch, shell quality, queue control, and flock safeguards. The same helper now powers both score application and the player-facing receipt, eliminating a second score formula.
- Added derived per-shift receipts with exact score-before, raw delta, applied delta, score-cap reconciliation, score-after, rank, and a separately itemized shift-two specialization bonus. Receipts are reconstructed from validated campaign records, so no save-schema duplication or migration was required.
- Added one deterministic hen highlight to every completed workday. The priority ladder preserves pressured cracked work, golden deliverables, visible strain, invisible labor, then the closing ledger leader; tie-breaks are stable and every payload is primitive-only JSON data.
- Captured highlights after payroll consequences but before worker stats reset and overnight recovery. The resulting hen file freezes the same shift's identity, career, relationship, output, quality, credit, and strain instead of narrating reset values.
- Rebuilt the probation report header around an exact signed `SHIFT SCORE`, compact receipt summary, and full breakdown tooltip. The filed management memo and hen file share one balanced story row on desktop and stack at 260 pixels in portrait layouts.
- Reports now open at the causal summary with intentional keyboard focus and scroll position. Missing or legacy data degrades cleanly; old checkpoints can derive a factual leader card from their persisted closing Pecking Order.

## Causal report verification

- Full Godot 4.7 headless suite passes 34/34, including focused score receipt, hen highlight, campaign UI, and Office-to-report integration coverage.
- Native 1280x720 campaign-report capture confirms the receipt, management memo, hen file, cumulative ledgers, objective, and actions fit in one readable hierarchy.
- Godot Web release export, Node 22 Vinext build, 2/2 rendered-wrapper tests, and lint all pass.
- Live in-app Chromium verification started a new campaign, authorized a policy, and reached the running WebGL 2 office with no warning or error logs; the playable tab remains open at `http://localhost:3000/`.
- The independent SwiftShader canvas client was invoked as required but timed out before producing a screenshot or state artifact, so it is not counted as evidence. Native rendering and live Chromium provide the visual/runtime checks for this pass.

## Environmental signage integration regression

- Expanded `office_signage_test.gd` to enforce integrated/printed surface metadata, valid tier and mounting families, and a 0.5-10 mm local gap between every environmental label and its printable face.
- Added an exact-one primary bureau landmark contract, explicit host relationships for the pipeline, Hen of the Month, and Flockwatch headers, and spatial-focus coverage that reveals nearby fine print while keeping remote paper and desk detail hidden.
- Preserved the legacy unanchored all-detail call contract. The focused Godot 4.7 test passes with 29 current signage fixtures.

## Environmental text fit and final verification

- Reworked office text as part of its physical host surfaces: engraved desk plates, inset equipment screens, taped and shadowed paper forms, registration marks, rules, and restrained surface-aware ink instead of luminous floating labels.
- Added spatial detail levels so overview cameras retain only architectural identity and essential live data, while nearby desk and paper copy becomes readable when a hen or workstation is focused.
- Simplified duplicate and over-dense copy, removed the redundant runtime Feed Social sign, raised the Flockwatch display clear of the rooster, and shortened intake and grading language.
- Rebuilt grading feedback as a cream paper docket physically connected to the sorter, and enlarged desk nameplates with their accent stripes contained inside the plate fixture.
- The complete Godot 4.7 suite passes 37/37. The Web release export, Node 22 production build, 2/2 frontend tests, and lint all pass.
- Native captures and the live WebGL campaign flow were visually inspected through policy authorization, office overview, and focused workstation detail with no browser warning or error logs.

## Guided opening and tactile feedback pass

- Slowed normal-speed simulation pacing from a 67.5-second workday to 202.5 seconds while preserving deliberate 3x and 10x fast-forward controls.
- New Day-1 campaigns now authorize policy into a paused floor orientation. First Clutch teaches inspection before resumption, exposes an explicit 1x handoff, restores the named induction hen after lost focus, follows her assisted egg to the physical sorter, and ends by pointing to the three live probation orders.
- Replaced the ambiguous active probation badge with `SCORE n / 100`, documented the 60-point threshold and four safeguards, and added an explicit closing-file 1/3 -> 2/3 -> 3/3 review sequence.
- Probation orders now project their exact live metrics as `ON TRACK` or `NEEDS ACTION` without awarding score early; volatile closing measures remain visibly provisional.
- Priority Peck now emits three deterministic animation-contact markers. The authored lay clip emits its true release marker, and pooled procedural cues are available for peck contact, nest release, sorter grade, basket landing, and Feed Fund payout without runtime node growth.
- Focused Godot regressions pass for campaign projection, First Clutch induction/coaching, generic decision behavior, timing-marker determinism, probation UI, and the original presentation smoke path.

## Worker agency and complete feedback pass

- Added named Flock Petitions on Days 2 and 4. Specialty respect, safe pace, and written credit now emerge from a hen's recorded working conditions instead of appearing as detached random events.
- Added three legible management responses, exact next-shift compact tests, fulfillment and breach receipts, sponsor continuity, and a solidarity-driven one-shift work-to-rule with slower output and safer shells.
- Kept active promises visible in the sponsor dossier, top policy badge, Flockwatch ledger, closing review, saved simulation snapshot, and schema-v6 persistence.
- Reordered Flockwatch around the live probation orders and Flock Voice before rankings, and shortened the three live objective rows so status, measure, threshold, and score fit at gameplay distance.
- Synchronized Priority Peck contact, egg release, sorter grading, basket landing, and payout confirmation with their authored visual moments through a fixed-size procedural audio pool.
- Added a Web diagnostic bridge for exact campaign, speed, First Clutch, objective, focus, labor, and clutch state, plus a repeatable responsive audit harness.

## Final verification

- The complete Godot 4.7 suite passes 41/41. After the final Flockwatch copy/layout adjustment, the probation integration, petition UI, management-loop UI, and First Clutch induction regressions were rerun and all passed.
- The Godot Web release export passes. With Node 22.22.0, frontend lint, production build, and the 2/2 rendered-wrapper tests pass.
- The required software-rendered game client produced a clean load screenshot and `render_game_to_text` state with no error artifact. Its longer input choreography exceeded the software-renderer timeout; the same interaction path was completed in live Chromium.
- Live Chromium verification completed New Campaign, Shell Assurance authorization, paused First Clutch inspection, specialty routing, a profile-matched check-in, deliberate 1x resumption, Priority Peck, physical egg grading, farmer payout, and the Flockwatch objective handoff.
- Responsive browser captures pass at 2560x1600, 1440x900, and 390x844. Every canvas remains 16:9, no breakpoint has horizontal overflow, the mobile rotation guidance remains readable, and no browser warning or error was recorded.

## Authored environmental typography pass

- Replaced the single Godot fallback face used by every world prop with an authored, licensed type palette: Barlow Condensed for institutional/engraved copy, IBM Plex Mono for live ledgers, and Courier Prime for paper forms and receipts. The raw font bytes are cached once at runtime and explicitly included in Web exports.
- Split the previously repeated hosted-header treatment into three prop-specific families: ink printed into the Yield Pipeline board, a paper-and-foil Hen of the Month masthead, and raised brass Flockwatch beam lettering.
- Rebuilt all workstation identity plates as warm laminate/brass furniture with separate employee-name and career-role lines. Dynamic hiring, vacancy, and capacity-hold updates refit both lines.
- Added short focus fades for nearby fine print so desk and paper detail no longer pops into existence like a HUD layer; overview still retains only architectural landmarks and essential live equipment.
- Rebalanced the main bureau identity, management beam, wall-chart title, award masthead, and mono screen density against their physical host dimensions.
- Replaced the oversized floating grading card with a compact paper receipt feeding from a fixed printer body and slot attached to the sorting gate. Exact quality, value, clean-clutch, queue, and timing behavior remains intact.

## Environmental typography verification in progress

- Native art captures inspected at the back wall, left wall, desk field, intake station, and grading chain.
- Focused Godot regressions pass for signage integration, office detail, office storytelling, grading feedback, staffing/nameplate updates, management UI, and the feedback orchestra.

## Environmental typography verification complete

- The complete Godot 4.7 suite passes 41/41. A fresh Web release export succeeds with all six authored font binaries in the pack; excluding audit output reduced the shipped PCK to 3,631,552 bytes.
- Node 22 frontend lint, production build, and the 2/2 rendered-wrapper tests pass. Fullscreen permission denial is now handled without placing an unhandled-rejection overlay over the playable office.
- Live in-app Chromium verification completed New Campaign, Shell Assurance authorization, office overview, and a focused Mabel dossier. Hosted type remained attached and readable through the camera transition; the page had no horizontal overflow and produced no new warning or error after the final reload.
- The required software-rendered client now waits for Godot and maps authored canvas coordinates to CSS pixels before acting. It reached the paused First Clutch office, produced matching `render_game_to_text` state (`shift_phase: 1`, `first_clutch.visible: true`), and produced no error artifact.
- Responsive browser captures pass at 2560x1600, 1440x900, and 390x844 with a 16:9 canvas, no horizontal overflow, and no browser errors. Native 2560x1440 back-wall and desk-field captures confirm the bureau beam, mono Flockwatch ledger, and laminate/brass workstation plates at high detail.

## Durable First Clutch orders handoff

- Split the transient 5.5-second completion receipt from a persisted `orders_handoff_acknowledged` state. Once the receipt retires, the top guidance and a compact `OPEN TODAY'S 3 ORDERS [V]` Flockwatch cue remain until the player explicitly opens the ledger.
- Programmatic ledger openings do not acknowledge the tutorial. Continue restores an unacknowledged handoff without resurrecting the large coach card, and a player-opened ledger writes an immediate `first_clutch_orders_opened` checkpoint.
- Extended the focused induction regression for post-receipt durability, Continue persistence, explicit acknowledgment, restored close-ledger affordances, and in-flight completion recovery. `first_clutch_induction_test.gd` and the adjacent `management_loop_ui_test.gd` pass after the final tooltip refresh.
- Godot's Web release export passes. The required software-rendered web-game client loads the refreshed bundle, reports both `orders_handoff_pending` and `orders_handoff_acknowledged` through `render_game_to_text`, produces a clean settled title/intake capture, and records no browser error artifact. The complete handoff sequence remains covered by the focused production-scene induction regression.

## Senior Roost career progression

- Replaced the old post-probation boolean/endless-shift handoff with a separate versioned `SeniorRoostState`. Probation remains an immutable five-shift record; Senior Roost owns uncapped three-shift quarters, four-quarter years, annual pass/fail records, bounded history, persistent Roost Marks, and five promotion titles.
- Added three exact quarterly capital policies to the authoritative economy. Merit Grants concentrate $12 and career progress on the top employed hen; the $24 Flock Dividend trades cash and farmer favor for flock stability; Executive Harvest Forecast books $24 immediately while increasing quota, stress, grievance, and trust debt. Protected operating reserves and review/credit gates reject invalid filings atomically.
- Added a deterministic 100-point quarter score across quota reliability, shell integrity, overdue queues, welfare, compliance, farmer favor, and wage solvency. Four quarters open an authored annual review; passing adds three marks and +1 next-year quota, while failure continues into a performance-improvement year with +2 quota and -5 farmer favor.
- Generalized the existing campaign report into a Senior career surface with authored vocabulary, Roost Mark/title metrics, exact policy cards, disabled underfunded choices, explicit annual actions, keyboard focus, and 390x844 containment. Flockwatch, guidance, Feed Party lockout, badge, and web diagnostics all switch to Senior language/state.
- Checkpoints now include the separate strict Senior payload alongside campaign, simulation, and session state without changing the outer save schema. Continue restores quarter and annual gates exactly; old boolean-only Senior saves migrate to a safe first-quarter policy filing.
- Added focused state, economy, UI, save-recovery, and production-Office integration regressions. The integration path proves final probation review -> policy filing -> exact simulation consequence -> active office -> three exact-once records -> scored quarter -> saved/restored next-quarter gate.

## Environment-integrated office text

- Replaced the repeated dark-framed gold utility plaques with object-specific treatments: slotted paper inserts on cubicle partitions, glued labels on capacity cartons, direct paint on wood and equipment, and one restrained matte enamel asset plate.
- Utility type now uses lower contrast and smaller optical sizes. Letterpress shadows are reserved for actual dimensional identity marks instead of appearing on every machine and desk caption.
- Added whole-fixture detail LOD for removable desk, carton, and room labels. The overview no longer leaves bright blank cards after microcopy recedes; inspecting a nearby hen reveals only the relevant workstation insert within a 2.75 m detail radius.
- Reduced the aisle-safety sheet to plausible office-paper scale and moved the Flockwatch beam above its live monitor so the title is no longer occluded.
- Expanded `office_signage_test.gd` to enforce the new partition, adhesive-label, surface-stencil, and slim-enamel families, including physical print gaps, absence of UI-like frames, and whole-fixture overview suppression.

## Environment-text verification

- Nine related Godot 4.7 suites pass: signage, detail, storytelling, visual systems, presentation, staffing UI, living-clutch storytelling, egg grading, and office layout.
- Native 2560x1440 overview and focused desk, intake, back-wall, and left-wall captures were inspected. The overview is quiet; close inspection reveals locally mounted copy; equipment text follows its host material.
- Fresh Godot Web export passes. The required scripted client produced `shot-0.png` plus matching loaded state with no error artifact before its software-renderer process exceeded the harness timeout.
- Live in-app Chromium completed New Campaign, policy authorization, office overview, and Tab focus on Mabel. The nearby name insert appeared during inspection, the canvas retained focus, and the console remained free of warnings and errors.
- Responsive browser verification passes at 2560x1600, 1440x900, and 390x844 with a 16:9 canvas and zero horizontal overflow.

## Roost-Mark Career Sponsorship

- Turned Senior Roost promotion currency into a consequential long-term choice. At a closed-quarter or annual gate, management may bank lifetime Roost Marks or invest exactly three available marks plus $12 of protected Feed Fund in one employed Accredited Layer.
- Added one permanent alternate claim specialty per hen. The sponsored hen must make real claim progress in that lane during her next worked shift; training reduces only her throughput by 15%, and absence or an idle desk cannot complete the credential.
- Completed training grants the existing specialist speed and shell-risk treatment in the alternate lane plus a permanent $1 daily wage increase. AUTO routing remains primary-first so cross-training expands deliberate manual routing instead of erasing hen identity.
- Added a compact, keyboard-accessible Senior report form with exact costs, candidate and lane selectors, disabled-state explanations, one-filing-per-gate protection, and a visible bank-versus-invest choice. Cross-trained hens receive a chest-attached credential that remains connected through walking, sitting, pecking, and laying.
- Versioned both authoritative ledgers: Senior Roost now tracks lifetime, invested, and available marks separately, while simulation persistence retains pending training, actual worked-shift evidence, the permanent secondary specialty, and wage effects. The Office transaction preflights both ledgers, charges once, checkpoints once, and restores idempotently.

## Career Sponsorship verification

- The complete Godot 4.7 regression suite passes 50/50 after the final UI and capture changes. Focused coverage proves pure preflight, exact two-ledger charging, repeat-click rejection, actual-work completion, absence deferral, secondary-lane affinity, AUTO primary preference, save migration, checkpoint recovery, UI filtering, keyboard access, and the attached credential.
- Native 1280x720 capture of the authentic closed-quarter Senior report was inspected at original resolution; the policy cards, sponsorship form, exact terms, bank/invest copy, selectors, action, and report footer remain legible in one scrolled report surface.
- Godot Web release export succeeds. Node 22 frontend lint and production build pass, and the rendered-wrapper suite passes 2/2.
- The required software-rendered client produced a loaded interaction screenshot and matching `render_game_to_text` state with no error artifact before its wrapper timeout. Live in-app Chromium then completed New Campaign and Shell Assurance authorization into the paused First Clutch office with WebGL 2 and no warning or error logs.
- Responsive browser captures pass at 2560x1600, 1440x900, and 390x844. Every canvas remains 16:9, the page has no horizontal overflow, and the mobile full-screen/landscape guidance remains readable.

## Prop-anchored environmental text pass

- Reparented the most visibly detached copy to its real host geometry: the farmer-credit stencil now inherits the basket slat, capacity labels inherit each rotated shipping carton, the suggestion-box stencil inherits the box, the archive title sits on a new shelf header beam, the grading caption inherits the sorter gate without overlapping its status lamps, and the surplus counter is painted directly onto its collection cart.
- Replaced the oversized opaque paper shadow slab with a tight non-shadow-casting contact cue. Paper rules and registration marks no longer cast duplicate geometry shadows.
- Moved live-screen rails and scanlines behind the glyph plane so depth testing cannot slice through ledger text. Printed pigment now fades through substrate color rather than translucent alpha.
- Preserved fractional metallic values for brass and foil instead of quantizing them to plastic or full metal, improving the way mount hardware responds to office lighting.
- Reduced overview competition: the bureau fascia remains the sole architectural landmark, while Yield Pipeline and Hen of the Month copy wait for close focus. Flockwatch is now restrained branding integrated into the monitor housing instead of a second large gold banner.
- Strengthened department-level painted headings, changed the bureau department line to `LAYING & CREDIT HARVEST`, and added optional camera sizing plus clean UI-free signage capture framing.
- Expanded `office_signage_test.gd` to enforce direct host parenting, rotated-carton inheritance, tight paper contact shadows, screen decoration behind glyphs, and nuanced metal response.

## Prop-anchored text verification

- Eight focused Godot 4.7 suites pass: signage, office detail, office storytelling, living-clutch storytelling, egg grading, visual systems, presentation smoke, and office layout. The complete current-tree regression also passes 50/50 after the final cart-host attachment.
- Clean native 1280x720 and 2560x1440 back-wall, left-wall, desk, and intake captures were inspected without HUD or actor occlusion. The primary fascia, paper forms, cubicle insert, and live ledger now read as parts of their props.
- Fresh Godot Web release export and the Node 22 production/frontend test pass succeed; rendered-wrapper tests pass 2/2.
- Live in-app Chromium completed New Campaign, Mabel's file, Shell Assurance authorization, Appeals routing, profile-matched check-in, 1x resumption, and overview return. The console remained free of warnings and errors, and the updated playable tab is left open.
- The required software-rendered client produced `output/web-game/environment-text-hosted-v2-boot/shot-0.png` plus matching loaded `render_game_to_text` state and no error artifact. Its full interaction choreography exceeded the SwiftShader timeout, so interaction evidence comes from the completed live Chromium path.

## Dimensional office-text integration

- Rebuilt the Egg Yield Bureau landmark and Flockwatch header as shallow low-poly letter geometry that shares the office lighting and casts real contact shadows instead of reading as luminous world-space UI.
- Replaced the monumental subtitle with a riveted department strip, softened the fascia into aged enamel and laminate, and moved its picture-light structure behind the sign face.
- Reparented workstation names, Farmer Intake, Yield Pipeline, Hen of the Month, Shell QA, QA Service, and Rework copy directly to their actual partition, inset, card, apron, plate, or tray geometry. Sign dimensions now fit those host faces.
- Removed panel-sized backing geometry from direct-painted stencils, slimmed cubicle memo channels, kept physical mounts present at every camera distance, and restricted detail LOD to glyph layers so labels no longer pop in as cards.
- Simplified the live Flockwatch ledger to compact `YIELD`, queue, and clock readouts and increased fitted type occupancy for screens, inserts, stencils, and enamel plates.
- Added a reusable environmental-text fit regression plus host-face containment and print-gap checks, and added a compact browser interaction route for the software WebGL smoke pass.

## Dimensional text verification

- The complete Godot 4.7 regression suite passes 54/54. Focused signage checks report 32 mounted fixtures, zero floating fixtures, 47 environmental labels, and 45 fitted text surfaces.
- Native 2560x1440 overview, bureau-wall, workstation, intake, wellness-wall, and Shell QA captures were inspected at original resolution.
- Fresh Godot Web release export succeeds. Node 24 frontend lint, production build, and rendered-wrapper tests pass 2/2.
- The software-rendered browser route reaches Mabel's paused First Clutch office with matching diagnostic state and no browser error artifact.
- Responsive browser audits pass at 2560x1600, 1440x900, and 390x844 with exact 16:9 canvas geometry, no horizontal overflow, and no console or page errors.

## External Packing Annex and reserve-safe expansion economy

- Closed the recurring-obligation reserve loophole. Capacity purchases now protect their added $2/day workstation overhead; hires protect added feed plus the applicant's exact wage; unresolved closing credit blocks staffing and capital changes. Catalogs, receipts, rejection reasons, and browser diagnostics all use the same raw projected-spendable preflight.
- Generalized facilities from one terminal purchase to multi-level schedules. The schema-v9 catalog now exposes installed/maxed state, current and next tier, next capital, total upkeep, upkeep delta, required spendable cash, projected reserve, benefits, tradeoffs, and exact action copy.
- Added the three-level Farmer Brand Packing Annex after two completed shifts: $60/$95/$140 capital, $3/$5/$8 total daily upkeep, +4% sound/golden graded value per tier, and a $3 × tier contract settlement for every six good eggs. Cracked output neither receives the premium nor advances the carton.
- Persisted annex tier, live carton progress, daily/lifetime cartons, percentage premiums, and carton settlements. Schema v8 migrates neutrally to an unowned annex with no invented output; corrupt levels, progress, totals, gates, and unowned production fail closed.
- Built a detailed 6.4m × 5.8m external east annex with a locked lease boundary, surveyed foundation, connected shell, manual and automated packing lines, carton rack, label printer, weighing head, status tower, premium dispatch, vault, loading hatch, pallet jack, and authoritative six-slot meter. Tiers rise into place cumulatively; the sixth good egg holds all six slots lit before settling to the next carton.
- Expanded the default isometric overview and added purchase focus for the annex without moving any chicken route. Route tests now protect both declared facility footprints; commissioned meshes remain inside the annex envelope and contain no collision objects or decorative egg stand-ins.
- Reworked Flockwatch's facility section into `CAPITAL EXPANSIONS`. Level 1/3 and 2/3 facilities remain upgradeable; only maxed modules become terminal. Cards show capital, upkeep delta, next reserve, benefits, tradeoffs, and the authoritative hold reason.
- Added a compact live carton readout to the top clean-clutch HUD, itemized packing value and contract credit in the farmer review, announced the Day-3 capital unlock, and expanded Web diagnostic state with funds, obligations, focused claim/assist, upgrades, facilities, and packing-contract state.
- Focused Godot 4.7 verification passes for staffing economy/UI, facility economy/UI/Office integration, Packing Annex economy/Office integration, office storytelling, office layout, schema persistence, petitions, restructuring, credit allocation, Priority Peck, and Career Sponsorship persistence. Native 2560×1440 level-three annex art was captured and inspected.
- Final native regression passes 56/56 after the dimensional alphabet update. The environmental fit audit reports 66 labels, 62 fitted surfaces, 49 mounted fixtures, and zero floating fixtures; `git diff --check` is clean.
- Fresh Godot Web export, frontend lint/build, and rendered-wrapper tests pass. The independent WebGL client reaches First Clutch with matching economy/facility diagnostics and no error artifact; responsive audits pass at 2560×1600, 1440×900, and 390×844 with no horizontal overflow. Live Chromium completed policy authorization, Mabel routing/check-in, accelerated claim work, grading, and an incident with no warnings or errors.

### Next high-impact economy/fun slice

- Add the audited First Clutch Reinvestment moment after Mabel's first farmer-collected egg: show exact created value and spendable reserve, offer at most two genuinely affordable visible requisitions plus `Bank the Fund`, make any orientation procurement credit transparent and exact-once, animate the installation at her desk, and persist the choice transactionally. This is the next priority after full native/Web regression of the annex slice.

## Environment-native office signage

- Replaced the shared 5x7 voxel alphabet on the Bureau, Flockwatch, Lease Option, and Farmer Brand identities with smooth Barlow lettering, shallow letterpress depth, and restrained aged-brass pigment. The Bureau landmark now sits on one dark barn-green architectural fascia with the quieter `CLUTCH INTAKE & CREDIT` department line.
- Consolidated office copy into four physical families: architectural fascia, compact enamel department plates, paper/personnel inserts, and machine readouts. Utility copy no longer reuses the same clean UI-card silhouette or glow treatment across unrelated props.
- Rebuilt the bulletin notices as slightly rotated paper forms with tape, a tack, and dog-eared corners; reduced the Wellness Roost to a mounted directional plate; and turned workstation names into clipped partition inserts with a clear name and role hierarchy.
- Rebuilt the farmer intake ledger as a compact CRT/register assembly with a hood, base, shorter supports, and screen-only emission. `FARMER COLLECTION` now sits beneath the desk hardware, while the carton meter uses a separate amber mechanical palette.
- Standardized the farm-bureau vocabulary around `CLUTCH FLOW`, `FARMER COLLECTION`, `WELLNESS ROOST`, `FREE-RANGE PASS`, and `NEST STATUS`, keeping satire legible without making every background prop compete at overview distance.
- Expanded the signage contracts to reject floating fixtures and visible stroke-mesh lettering, require attached host geometry and shallow letterpress depth, and continue enforcing text-fit, surface-gap, and close-detail behavior.

## Environment-native signage verification

- The complete Godot 4.7 regression passes 59/59. Focused signage checks report 49 mounted fixtures, zero floating fixtures, 77 environmental text layers, 72 fitted surfaces, and five deliberately shallow letterpress layers.
- Native 2560x1440 overview plus bureau-wall, bulletin-wall, workstation, farmer-collection, and Packing Annex captures were inspected at original resolution. Architectural copy now establishes the overview landmark while personnel, paper, and machine copy stays subordinate until close inspection.
- A fresh Godot Web release export passes. Frontend lint is clean under Node 20; production build and the rendered-wrapper suite pass under Node 24, with 2/2 wrapper tests passing. Vinext's current `node:fs/promises.glob` dependency makes Node 24 the reliable build runtime.
- The required independent software-rendered game client loaded the refreshed WebGL bundle, emitted a matching `render_game_to_text` state and screenshot, and produced no browser-error artifact. Its longer office choreography exceeded the SwiftShader timeout, so the completed interaction evidence comes from live Chromium.
- Live Chromium completed New Campaign, opened Mabel's file, authorized Shell Assurance, and returned to the office overview at 2560x1600. Responsive checks at 1440x900 and 390x844 preserve the exact 16:9 game canvas, WebGL 2, and zero horizontal overflow; browser console and page-error checks are clean.

## Laying Records Annex and investable intake capacity

- Replaced the silent fixed 18-file ceiling with an authoritative live-file capacity economy. Incoming demand is now rolled even when the archive is full; rejected files and their estimated base value are recorded in daily and lifetime ledgers without ever crediting the Feed Fund.
- Added the three-level `records_annex` expansion after two completed shifts. Rolling Records Floor costs $70 with $4 total daily upkeep, Pneumatic Triage costs $105 and raises total upkeep to $7, and Permanent Retention Vault costs $155 and raises total upkeep to $11. Each tier adds six file roosts, growing capacity through 18 / 24 / 30 / 36.
- Preserved the dark operational tradeoff: storage captures more work but creates no throughput. A larger retained book can become a larger overdue liability when staffing, workstation capacity, routing, or flock welfare lag behind expansion.
- Added exact reserve preflights, tier receipts, facility effects, workday reporting, farmer-review intake accounting, Flockwatch live-file diagnostics, and Web diagnostic fields. The closing ledger explicitly identifies turned-away volume and estimated missed file value as opportunity cost rather than income.
- Advanced simulation persistence to schema v11. Schema-v10 saves strictly validate their old two-facility ledger, then migrate with an unowned Records Annex and zero invented rejection history; current restores validate facility-dependent capacity and all four intake ledgers before mutating the session.
- Built a cumulative snapshot-driven east-parcel room with a connected floor and back wall, rolling shelf banks, 36 authoritative lane-colored folder slots, transfer cart, mechanical capacity meter, pneumatic triage tubes, powered file rail, retention vault/carousel, overdue beacon, and rejected-intake overflow bin. All text is attached to real machine or wall hosts, and the simplified frame keeps the camera-facing floor visually open.
- Declared and enforced the exact `6.4m × 5.8m` footprint at `x = 12.0–18.4`, `z = -2.9–2.9`, with a clear copier-aligned service strip, a 3.55m opaque-height cap, no collisions, and no overlap with Shell QA, the Packing Annex, or any of the 18 worker routes.
- Added Records Annex purchase focus plus native art-review captures for the level-three room and the all-facilities office overview. The overview now proves three independently readable capital modules can coexist without clipping the expanded office or its circulation.

## Records Annex verification

- The complete Godot 4.7 regression passes 61/61. Focused tests prove day-three unlock, all tier costs and upkeep deltas, one-cent reserve rejection, 18→36 capacity, rejected-intake accounting without cash minting, v10→v11 migration, UI-to-world tier purchases, cumulative geometry, exact folder occupancy, overdue and overflow reactions, route clearance, and terminal idempotence.
- Environmental-signage verification reports 61 mounted fixtures and zero floating fixtures after bringing the new machine plates inside the host-face fit and surface-gap contracts. `git diff --check` is clean.
- Native 2560×1440 close and all-expansion overview captures were inspected at original resolution. The Records Annex reads as a coherent archive/triage room at inspection distance and as a distinct, subordinate east-parcel module in the office overview.
- Fresh Godot Web release export succeeds. Node 24 frontend lint and Vinext production build pass; rendered-wrapper tests pass 2/2.
- The required independent software-rendered web-game client completed a New Campaign interaction, produced a clean loaded office screenshot and matching state, and exposed the three-facility catalog plus live capacity/rejection diagnostics with no error artifact.
- Responsive browser audits pass at 2560×1600, 1440×900, and 390×844. Every canvas remains 16:9, the page has zero horizontal overflow, and console/page errors are empty.

### Next high-impact economy/fun slice

- Build the audited Farm Mutual Contract Board as a demand-side planning choice: three deterministic next-shift folders with disclosed lane mix, rush timing, premium, success condition, and breach charge. Signing should use the existing planning window; forecasted folders should arrive physically without pausing production. This will make the Records Annex, staffing, routing, and future facilities compete around visible market strategy instead of isolated percentage upgrades.

## Farm Mutual Contract Board and outside-peckwork economy

- Added the Day-3 Farm Mutual planning gate with three deterministic next-shift books. Homestead Stability reserves five slots at 18-file capacity and pays $10 or breaches for $5; Predator Watch reserves six at 24 capacity and pays $16 or breaches for $8; Exceptions Retention reserves six at 30 capacity and pays $24 or breaches for $12. Every folder's lane, scheduled arrival, rush flag, deadline, and clean/on-time target is disclosed before signing.
- Made signing transactional and reserve-safe. The complete folder count and authored breach clause must fit before acceptance; signing does not debit the Feed Fund, repeat signing cannot duplicate work, and an explicit `D` standard-book receipt prevents a planning deadlock when management declines outside work.
- Contract folders arrive at their authored times during the next live shift without opening a modal or stopping the clock. Queue and active-file surfaces identify `MUTUAL BINDER` and `CONTRACT RUSH` work with its deadline. Cracked or late folders cannot satisfy the binder even if completed.
- Settled the contract exactly once in the farmer review. Fulfillment premium and breach indemnity have their own ledger line, base flock production excludes the premium, net operating result includes the settlement once, and the closing Feed Fund remains authoritative.
- Advanced simulation persistence to schema v12. Review, explicit decline, running schedules, reserved IDs, completed/late quality sets, and settled results round-trip strictly; schema-v11 saves migrate to a neutral contract state, while malformed schedules, receipts, outcomes, and cross-ledger claim IDs fail atomically.
- Built a snapshot-driven left-wall physical fixture with wood frame, enamel header, three client folders, lane tokens, rush tabs, premium coins, binding clips, a lock shutter, active summary, and fulfillment/breach stamps. All 23 attached text layers now sit exactly 8 mm off their real host faces; the board is a secondary department landmark and adds no collision or navigation geometry.
- Added a responsive scrollable planning surface with full terms, `1`-`3` folder selection, exact Enter-to-sign intent, explicit decline, and receipt-gated `C` continuation. The campaign, probation, Senior, checkpoint, and accessible web status flows all use the same authoritative contract snapshot.
- Updated the web briefing and hidden live-status narration to explain Records Annex capacity, timed arrivals, premium versus breach exposure, and the complete planning controls. Removed the remaining malformed runtime punctuation and refreshed both Web release packages.

## Farm Mutual verification

- The complete Godot 4.7 regression suite passes 67/67. Focused coverage proves the Day-3/capacity gates, exact reserve edge, three authored schedules, timed non-modal arrivals, clean/on-time quality, success/breach idempotence, explicit-decline persistence, schema-v11 migration, corruption rejection, real Office Board-to-sign-to-briefing wiring, responsive UI, farmer accounting, routing badges, and campaign/Senior continuation.
- Environmental verification reports 84 mounted fixtures, zero floating fixtures, one primary office identity, an exact 8 mm host clearance for the Farm Mutual copy, 18 clear chicken routes, and zero contract-board collisions.
- Native 2560x1440 physical-board and contract-planning captures were inspected at original resolution. The physical fixture reads as part of the office wall, while the full terms remain legible in the dedicated planning layer.
- Fresh Godot Web release exports succeed. Node 24 frontend lint and Vinext production build pass; the rendered-wrapper suite passes 2/2 with Contract Board accessibility and control coverage.
- The required independent software-rendered browser client loads the final bundle at `http://localhost:3000/`, publishes the new `contract_board` diagnostic state, and produces a matching screenshot/state pair with no console or page-error artifact.

### Next high-impact economy/fun slice

- Turn Farm Mutual into a longer reputation market: let clean binder streaks unlock visually distinct client seals, seasonal books, and negotiated clauses, while breaches tighten reserves or remove offers. Pair each market tier with a physical archive/dispatch upgrade so reputation, staffing, throughput, and office growth remain one visible strategic loop.

## Farm Mutual standing and Service Coop capital loop

- Added persistent client standing derived from settled work: each fulfilled binder contributes two points, each breached binder removes one, and the displayed total never falls below zero. Unlisted, Bronze, Silver, and Gold ranks unlock at 0 / 2 / 6 / 12 points; clean fulfillment streaks and the best streak are preserved, while a breach resets the current streak and places only that binder on a one-planning-day cooldown.
- Added the three-level `farm_mutual_service_coop` expansion. Bronze requires standing 2, 24 live-file capacity, and four active hens; Silver requires 6 / 30 / 5; Gold requires 12 / 36 / 6. Capital costs are $75 / $120 / $180 and total daily upkeep rises to $3 / $6 / $9.
- Made accreditation a real contract economy. Each installed tier adds 50% of the authored base premium on successful Farm Mutual binders only. The signing receipt freezes base value, installed tier, Service Coop bonus, and total, so later construction cannot rewrite an active agreement. Breaches never receive the bonus, and purchased tiers never demote when standing falls.
- Built a cumulative northeast-parcel facility with a Bronze seal counter and press, Silver dispatch tubes and courier hardware, and a Gold accreditation arch, standing totem, settlement vault, success light, and breach shutter. Its authoritative readouts, packets, seals, and settlement tray react to simulation snapshots without adding collision or navigation geometry.
- Expanded Flockwatch and the Farm Mutual planning surface with exact standing progress, three earned seals, current and best clean streaks, capacity/staffing shortfalls, tier economics, cooldown reasons, and itemized `BASE + COOP BONUS = TOTAL` receipts. Farmer review and live guidance now expose the same frozen terms and next useful action.
- Advanced persistence to schema v13 with strict validation, neutral v12 migration, exact active/result freezing, and atomic rejection of corrupt standing, streak, facility, and premium records. Legacy contracts migrate with no invented accreditation or bonus.
- Updated the accessible web status to distinguish client standing from facility accreditation, announce exact premium math and seals, and identify the next arrival, deadline, or completion threshold for a running binder.

## Service Coop verification

- The complete deterministic Godot 4.7 regression passes 71/71 in fresh headless processes. Focused coverage proves standing math, half-cent premium rounding, tier gates, exact costs and upkeep, success/breach/decline behavior, same-binder cooldowns, non-demotion, schema-v12 migration, corruption rejection, UI-driven purchases, cumulative construction, settlement state, route clearance, and idempotence.
- Environmental verification reports 93 mounted fixtures and zero floating labels. The final three Service Coop machine readouts were tightened to remain within the 12 mm host-face clearance contract.
- Native 2560x1440 Service Coop, requisition, Contract Board, and complete expansion captures were inspected at original resolution. All four facilities remain readable as distinct modules while the new client-service hardware stays inside its declared 6.4m x 5.8m parcel.
- Fresh Godot Web release exports for both distribution targets succeed. Node 24 frontend lint and production build pass; the rendered accessibility/status suite passes 3/3.
- The independent WebGL client loads the refreshed live page, publishes the four-facility catalog plus schema-v13 standing and accreditation diagnostics, and produces a matching screenshot/state pair with no console or page-error artifact.

### Next high-impact economy/fun slice

- Add seasonal Farm Mutual books and negotiated clauses that trade premium multipliers against rush density, lane concentration, welfare guarantees, and breach exposure. Let Gold standing unlock a physical negotiation room so the next expansion creates a new decision surface instead of another passive percentage bonus.

## Integrated environmental typography and office hierarchy

- Reorganized environmental copy into three visual bands: permanent architectural identity and department destinations, live data restricted to real screens, and lower-contrast operational detail that appears only near the inspected prop. Lease, parcel, stencil, insert, paper, and machine copy no longer competes with room identity in the office overview.
- Rebuilt Egg Yield Bureau, Flockwatch, Farmer Brand, Records Annex, and Farm Mutual Service Coop headings as shallow Barlow TextMesh geometry. The letters inherit their actual beam or fascia transform, room lighting, depth occlusion, and contact shadows; hidden Label3D proxies preserve authored text for diagnostics without drawing duplicate copy.
- Removed duplicate panel-sized beds from host-attached beam lettering, reduced text face fill and contrast by physical medium, blended printed pigment toward its substrate, and promoted only completed departments to overview landmarks. Secondary parcel lettering now dissolves in and out with the printed detail hierarchy, including while the simulation is paused.
- Corrected destination mounting so Flockwatch is owned by its header beam, and changed the Packing and Records identities to dark sage type on their existing warm-beige beams. Service Coop uses cream dimensional type on its green beam. Fine subtitles remain restrained close-reading marks.
- Rebuilt the Feed Party asset with the same bundled Barlow office face for `FEED PARTY`, `ATTENDANCE REQUIRED`, and sack markings. The verifier now requires both main title objects; reduced curve tessellation keeps the final GLB at about 1.69 MB and the Blender source at about 697 KB.
- Added `environmental_signage_hierarchy_test.gd` to protect the five landmarks, three subordinate parcels, four representative utility surfaces, modeled/proxy copy parity, required destination lines, host attachment, substrate hierarchy, and animated dimensional-copy transitions.

## Environmental typography verification

- Final Godot 4.7 native regression passes 72/72 in fresh headless processes. Focused results report 93 mounted signage fixtures, zero floating fixtures, five modeled landmarks, three subordinate parcels, 126 environmental Label3D layers, and 117 fitted surfaces. Office storytelling retains 18 clear chicken routes and zero contract-board collisions.
- The Feed Party Blender build and asset verifier pass with a 3.420 m footprint. Native overview and focused Bureau, Flockwatch, Farmer Brand, Records Annex, Service Coop, Contract Board, and Feed Party captures were inspected; the hierarchy reads as architecture at overview distance and physical detail at inspection distance.
- Final dual Godot Web exports are byte-identical at 4,053,280 bytes with SHA-256 `804A6B772FAB075D46EF77F493FA3C2F7556DED800E6FBF232D2A96F48D39C7F`. Node 24 lint, production build, and rendered-wrapper tests pass 3/3.
- The independent WebGL client loads the playable First Clutch office with matching state and no error artifact. Responsive browser checks pass at 2560x1600, 1440x900, and 390x844 with exact 16:9 canvases, zero overflow, no console/page/request errors, and clear mobile landscape guidance. `localhost:3000` serves the exact final exported PCK.

## Seasonal Farm Mutual market and Gold Council Room

- Turned Farm Mutual into a deterministic three-day market beginning on Day 6. Spring Hatch Surge, Summer Predator Migration, Autumn Retention Audit, and Winter Feed-Fund Squeeze each publish a different lane-demand book, exact signed premium adjustment, and breach-reserve adjustment before management commits.
- Added one negotiated rider per binder behind the permanent Gold Farm Mutual Negotiation Room. Expedited Hatch compresses service windows and adds rush work; Specialist Roost concentrates the entire book in its dominant lane; Rested Flock adds a welfare-at-settlement safeguard; Standard Terms remains the safe default.
- Added the one-tier `farm_mutual_negotiation_room` capital project at $240 plus $12 daily upkeep. It requires Day 6, Gold standing, and Service Coop level 3 to commission, then remains owned if standing later falls. Save data advances to strict schema v14 with a neutral v13 migration that invents neither a season nor a rider.
- Froze every signed binder as exact `AUTHORED + SEASON + RIDER + COOP = TOTAL` terms. The Service Coop bonus still applies only to authored base premium; signed schedules, authored lanes, rush flags, claim IDs, terminal outcomes, welfare gates, premium, and breach ledgers now restore and settle exactly once.
- Built a physical north-parcel Council Room with a walnut-and-felt underwriting table, six flock chairs, an intentionally oversized empty farmer-credit chair, folios, rider slip, settlement trays, signing press, reeded glass, warm pendant, season medallion, and hosted signage. A low dado and wide camera-facing cutaway keep the room legible instead of hiding it behind an opaque wall.
- Reworked the contract-planning surface into a compact master/detail negotiation desk with a fixed action rail, season and accreditation strip, selected-rider diagnostics, and exact effective terms. `N` opens riders, `Space` selects, `R` restores Standard Terms, `Enter` authorizes, and all mouse, keyboard, campaign, Senior, checkpoint, Web status, and farmer-review paths consume the same authoritative snapshot.
- Expanded the playable Web shell with the same seasonal/rider explanation, controls, accessible narration, running-contract state, and exact premium composition. The office overview now accommodates five distinct external facilities without collision or navigation geometry crossing any of the 18 chicken routes.

## Seasonal market verification

- The complete Godot 4.7 regression passes 77/77 in fresh isolated processes. Focused coverage proves season rotation, signed integer pricing, all rider transformations, welfare settlement, reserve edges, room gates and permanence, schema-v13 migration, corruption rejection, exact-once terminal ledgers, UI-to-world signing, six-facility layout footprints, 18 clear routes, and zero room collision/navigation geometry.
- Environmental checks report 106 mounted fixtures with zero floating fixtures, six primary landmarks, three subordinate parcels, four representative utility surfaces, 141 environmental text layers, and 130 fitted surfaces. The physical Contract Board hosts exactly one rider slip only when negotiated terms are active.
- Native 2560x1440 Council Room, negotiated Contract Board, and full expansion-overview captures were inspected at original resolution. The new cutaway preserves the room's furniture hierarchy while all five capital modules remain visually distinct across the enlarged campus.
- Fresh Godot Web releases are byte-identical at 4,226,804 bytes with SHA-256 `20A3056116A6156BDA62B44E8EB4A2396594A0EB72147F97AE6B033F5BFFA8F8`. Node 24 lint and production build pass, and the rendered accessibility/status suite passes 4/4.
- The required independent browser client loads the final exported office and publishes the full schema-v14 economy, seasonal book, fifth-facility catalog, available riders, planning state, and control map without an error artifact. Responsive audits pass at 2560x1600, 1440x900, 390x844, and 844x390 with exact 16:9 canvases, zero overflow, and no console or page errors. `localhost:3000` serves the exact release PCK.

### Next high-impact economy/fun slice

- Add an investable Wellness Nest and Training Roost loop: equipment and rooms should visibly change recovery, morale, specialization, and cross-training while creating payroll, capacity, and upkeep tradeoffs. This would connect flock care to the new welfare rider and turn the existing career system into another legible campus-expansion decision rather than a detached menu statistic.

## Wellness Nest and Training Roost UI/Web integration

- Added one compact `FLOCK CARE & TRAINING` block before the Flockwatch facility catalog. It reports current Rested Flock welfare, occupied recovery perches, exact strain/recovery effects, active training files, effective sponsorship terms, and the next care capital action from the authoritative `flock_care` snapshot.
- Care facility cards now show exact current-to-next Wellness or Training effects. Training Roost cards also disclose the matching Wellness Nest gate. Live snapshot rebuilds preserve the ledger scroll position and keyboard focus on the same facility action.
- Career Sponsorship and the selected-hen dossier no longer hardcode a 15 percent training penalty. They consume authoritative effective cost, work multiplier, coaching XP, and permanent wage terms; the dossier also identifies physical Wellness recovery and compact morale/stress/fatigue readings.
- The Web diagnostic bridge now publishes `flock_care`. Accessible status announces Rested Flock threshold risk, Farmer Review care capacity and next requisition, Senior sponsorship economics, and active recovery/training without adding another shortcut or briefing card.
- Focused verification passes: `facilities_ui_test.gd`, `career_sponsorship_ui_test.gd`, `claim_routing_ui_test.gd`, and `career_sponsorship_integration_test.gd`. Node 24 Vinext build and rendered accessibility suite pass 5/5; ESLint passes. Final Godot export and combined browser walkthrough remain with the parent integration pass.

## Wellness Nest and Training Roost capital loop

- Advanced the authoritative simulation to strict schema v15 and expanded the capital catalog to seven durable facilities. Schema-v14 saves migrate with neutral care levels; the exact seven-key ownership ledger, Wellness-to-Training dependencies, signed contract evidence, and permanent purchased ownership validate fail-closed.
- Added three Wellness Nest tiers at $70 / $115 / $175 with total daily upkeep of $5 / $9 / $14. The tiers reduce real pecking fatigue and stress, improve break and overnight recovery, add recovery capacity, and raise the next-shift clutch target by exactly one file per commissioned tier. They never fabricate a flat welfare, egg-value, or crack-rate bonus.
- Added three Training Roost tiers at $85 / $135 / $210 with total daily upkeep of $6 / $10 / $16. Each tier requires the matching Wellness tier plus increasing career, staffing, capacity, and day gates; installed terminals reduce sponsorship cost from $12 toward $6, improve pending-training output from 85% toward 100%, and add coaching XP while completed credentials retain their real $1 daily wage liability.
- Added one authoritative `flock_care` snapshot shared by Flockwatch, hen dossiers, sponsorship, Senior planning, browser diagnostics, and accessibility narration. It exposes the Rested Flock threshold and margin, occupied recovery perches, active training files, exact recovery/training terms, facility status, and the next useful care purchase without duplicating economy math in the interface.
- Built a connected east-campus spine with a three-tier Wellness Nest and Training Roost. Wellness grows from two to four to six joined cubbies; Training grows from one to two to three practice terminals and shows only credentials actually earned by the flock. Both 6.4 m x 5.8 m rooms remain inside their surveyed parcels, preserve all 18 chicken routes, and add no collision or navigation geometry.
- Integrated the office typography pass into both rooms: dimensional Barlow identities inherit their header beams, live data stays on modeled consoles, and small operational copy remains close-reading detail. The whole office now reports 122 mounted fixtures, zero floating fixtures, 163 environmental labels, 150 fitted physical surfaces, eight landmarks, five subordinate parcels, and six representative utility surfaces.

## Flock-care campus verification

- The complete Godot 4.7 suite emits all 81 explicit pass markers in fresh isolated processes with zero timeouts under a 90-second per-file guard. The broad First Clutch induction path was separately audited twice at 50.365 and 59.147 seconds; its former timeout was the old 50-second harness limit, not a game regression.
- Focused economy and persistence coverage proves all six tier purchases, exact reserve edges, upkeep, real worker recovery, derived training terms, one-file quota evidence, strict dependencies, permanent ownership, neutral v14 migration, and atomic rejection of malformed ledgers. Visual coverage proves locked/survey/level 1/2/3 construction, cumulative equipment, authoritative credentials, parcel bounds, route clearance, and zero collisions.
- Native 2560x1440 captures of `wellness_nest_level3.png`, `training_roost_level3.png`, and `care_campus.png` were inspected at original resolution. The rooms read as a coherent care campus, with environmental identities recessed into their architecture and dynamic values confined to real equipment.
- Fresh Godot Web releases are byte-identical at 4,308,472 bytes with SHA-256 `25AA5718808B8C9821AB22D1065DC7BF98A680F17B2E5BEF575590F6B3EE25BB`. `localhost:3000` serves that exact PCK.
- Node 24 frontend lint and Vinext production build pass; the rendered accessibility/status suite passes 5/5. The required independent browser client loads the final bundle, publishes all seven facilities plus `flock_care`, and creates a matching state/screenshot pair with no error artifact.
- Responsive browser verification passes at 2560x1600, 1440x900, 390x844, and 844x390 with exact 16:9 game canvases, zero horizontal overflow, and no console, page, or request errors.

### Next high-impact economy/fun slice

- Add a Rooster Operations Office and IT Coop as an explicit automation-versus-overhead choice. Physical scheduling boards, repaired terminals, and supervisor desks should reduce routing friction or unlock delegation while increasing payroll, maintenance, surveillance, and labor-grievance exposure, keeping office growth legible and satirically costly.

## Rooster Operations Office and IT Coop capital loop

- Advanced the authoritative simulation to strict schema v16 and exactly nine facility keys. Neutral v15 migration appends the two operations facilities without inventing ownership, pressure, automation, payroll, or incident history; current saves reject malformed facility dependencies, action ledgers, and impossible shift/decision tuples atomically.
- Added three Rooster Operations Office tiers at $100 / $160 / $240, with room upkeep of $4 / $7 / $11 and separate supervisor payroll of $5 / $8 / $12. The tiers expand the flock-wide daily check-in allowance from one to two, three, then four while each hen remains limited to one check-in. Morning directives apply exact once-per-shift surveillance stress, grievance, and solidarity pressure to every employed hen.
- Made personnel actions chronology-safe and reserve-safe. Every accepted action receives a persistent serial; multi-action ledgers preserve filing order through save/restore and farmer review. Promotion-producing actions preflight the new recurring wage as well as their one-time cost, while a genuinely zero-cost action that creates no new obligation remains available to an already insolvent office.
- Added three IT Coop tiers at $130 / $200 / $300 with total systems upkeep of $10 / $17 / $26. IT improves only employed, seated, AUTO-routed peckwork to 103% / 106% / 110%, progressively tightens deadline dispatch, and recognizes earned secondary credentials from level one. Manual trays remain explicit overrides; automation never bypasses claim assignment, workstation presence, laying, grading, delivery, or revenue authority.
- Paired IT benefits with exact once-per-shift compliance exposure and increasingly costly Ledger Molt incidents. Patch, spreadsheet-compliance, and crack-risk terms are integer-authored and published through the same canonical `operations` snapshot used by Flockwatch, dossiers, farmer review, Web diagnostics, and accessible narration.
- Built a connected north operations campus with cumulative one/two/three-station Rooster and IT rooms, each inside a 6.4 m by 5.8 m surveyed parcel. The office retains all 18 chicken routes and ten collision-free facility footprints. Room identities are modeled lettering attached to structural beams; changing directive, routing, pressure, speed, and incident values remain hosted on physical boards, terminals, machine panels, or invoice clips.
- Completed the environment-native typography pass across the expanded office. Validation now reports 144 mounted signage fixtures with zero floating fixtures, ten architectural landmarks, seven subordinate parcels, eight representative utilities, 191 environmental text layers, 176 fitted physical surfaces, and one intentional letterpress layer.

## Operations-campus verification

- The complete Godot 4.7 suite passes 85/85 scripts in fresh isolated processes with explicit pass markers, zero 90-second watchdog failures, and zero parser, script, or runtime error lines. The authoritative logs are in `output/godot-full-suite-20260714-222233`.
- Focused regression coverage proves all six facility tiers, exact capital/upkeep/payroll schedules, reserve edges, promotion wage liability, partial supervisor-payroll arrears, action chronology, strict save causality, exact-once shift pressure, seated AUTO authority, Ledger Molt outcomes, room bounds, cumulative equipment, route clearance, and zero collisions.
- Native 1280x720 captures of `rooster_operations_office_level3.png`, `it_coop_level3.png`, and `operations_campus.png` were inspected at original resolution. Warm supervision and cool systems materials remain distinct, structural lettering sits flush to its beams, live copy is confined to equipment, and the joined campus remains legible from overview.
- Fresh Godot Web exports are byte-identical in both distribution targets. The 4,423,612-byte PCK has SHA-256 `911D276A1E35E1F37D1F3C66DFC17B420999E0581D7931B02580D0AC0C8571EF`; the WebAssembly runtime and loader also match byte-for-byte. `localhost:3000` serves that exact PCK.
- Node 24.18 frontend lint and Vinext production build pass; the rendered accessibility/status suite passes 6/6. The required independent WebGL client completes three interactive captures with matching diagnostic states and no console/page-error artifact.
- Responsive browser verification passes at 2560x1600, 1440x900, 390x844, and 844x390 with a live diagnostic bridge, zero horizontal overflow, and zero browser errors. Portrait mobile preserves a usable shell and clear full-screen landscape guidance for dense campaign cards.

## Flock Relations expansion in progress

- Froze the next interactive expansion as a west-side Flock Relations Office rather than another passive percentage room. Its three cumulative tiers add named-hen case intake, mediation/PIP review, and mandatory arbitration; unresolved files carry real compliance, solidarity, and grievance pressure.
- Added the compact Flockwatch case-file surface with canonical named cases, exact action prices and effect previews, review-limit and backlog disclosure, tier-gated Remedy/Mediation/PIP/Arbitration buttons, a permanent last-resolution receipt, and a truthful empty state. The focused UI test passes both the standalone surface and its embedded staffing-ledger signal path.
- Raised the management camera's safe campus framing ceiling from 11.0 to 14.5 so authored care and governance-campus views are no longer silently cropped.

## Senior Career Forecast

- Made one pure Senior Roost score breakdown authoritative for live projection, quarter close, and exact Roost Mark thresholds at 45 / 60 / 80. The forecast is non-mutating, JSON-safe, and identifies the largest recoverable scoring component with a factual cause and deterministic tie handling.
- Reused the existing compact Flockwatch objective surface for an active-quarter `IF FILED NOW` score, projected marks, next threshold, and highest-value recovery cue. It hides outside active Senior play and before closing/review so an in-progress shift is never counted twice.
- Published `career_forecast` through office diagnostics and accessible Web narration without adding a modal, shortcut, or lower-page section. Focused Godot state/UI/integration tests pass, including threshold parity, projection-to-close parity, save compatibility, nonmutation, responsive containment, and active-only visibility.
- Node 24.18 lint, production build, and the rendered accessibility suite pass 7/7. The Godot 4.7 Web export loads through the independent browser client with a matching diagnostic state, `career_forecast.visible: false` outside Senior Roost, and no console or page errors.

## Flock Relations Office and Career Forecast completion

- Advanced the authoritative simulation to strict schema v17 and exactly ten facility keys. Neutral schema-v16 migration adds an unowned Flock Relations Office with no invented case, settlement, denial, or receipt history; malformed dependencies, open cases, action records, and facility ledgers reject atomically.
- Completed the three-tier Flock Relations economy at $110 / $175 / $260 capital and $5 / $9 / $15 total upkeep. Matching Rooster Operations and Wellness Nest tiers gate one/two/three open-case slots and review authorizations. Deterministic named-hen cases derive from documented grievance, stress, fatigue, trust, arrears, surveillance, and IT-compliance evidence rather than random flavor.
- Added four consequential review actions with exact costs and bounded effects: Fund Remedy, Mediate, coercive PIP, and tier-three Arbitration. Unresolved files carry compliance loss, solidarity, and subject grievance exactly once per closing; accepted actions debit once, mutate only the named case subject and shared ledgers they disclose, and persist a single permanent resolution receipt.
- Integrated the complete case desk into Flockwatch with canonical dockets, evidence summaries, capacity and review-limit disclosure, honest empty states, exact action previews, dependency gates, settlement reserve checks, keyboard/mouse activation, checkpoint saves, and a stable last-resolution receipt. Farmer review, office diagnostics, and accessible Web narration consume the same authoritative projection.
- Built the mirrored west-campus Flock Relations Office as a cumulative intake, mediation/PIP, and arbitration room with a mulberry/oatmeal/brass palette, smoked-glass clerestory, structural room identity, case pigeonholes, waiting perches, outcome lamps, settlement hardware, an exact east bridge, and a 1.10-meter clear internal aisle. Physical case folders appear only for authoritative `open_cases`; resolution hardware appears only for `last_resolution`.
- Completed the Senior Career Forecast with one pure score breakdown shared by live projection and quarter close. During active Senior play, Flockwatch reports `IF FILED NOW`, projected marks at exact 45 / 60 / 80 thresholds, the next threshold, and the largest recoverable cause; it remains hidden outside the active quarter and never mutates the career file.
- Updated the responsive Web shell and diagnostic bridge to teach and announce the case-settlement reserve, named-hen review loop, autosaved case capital, and live Career Forecast without adding a new modal, shortcut, or lower-page feature card.

## Flock Relations final verification

- The final Godot 4.7 tree passes all 93/93 `tests/*.gd` scripts in fresh isolated processes across three shards, with explicit pass markers, zero 90-second watchdog failures, and no parser, script, or engine error signatures. The slowest broad induction test completes in 65.729 seconds. Focused end-to-end coverage proves real dependency purchases, deterministic severity-three filing, atomic mid-shift rejection, actual button-to-Office resolution, exact $20 remedy debit, unrelated-hen isolation, reactive physical folders, and two idempotent save/restore cycles.
- Office validation reports 11 collision-free facility footprints, 18 storytelling roots, all 18 chicken routes preserved, 151 mounted signage fixtures with zero floating fixtures, 11 primary landmarks, eight subordinate parcels, nine representative utilities, 201 environmental labels, 185 fitted physical surfaces, and one intentional letterpress layer.
- Native `flock_relations_office_level3.png` and `governance_campus.png` captures were rendered and inspected at 2560x1440. The room identity is attached to its architecture, dynamic copy remains on physical screens/folders/receipts, the glazed clerestory visually connects its roof frame, and the west branch remains legible across the governance-campus overview.
- Fresh Godot Web releases are byte-identical in both distribution targets. The 4,560,852-byte PCK has SHA-256 `1165615962092D393EA51570A2BA9AF8FBD81995B40C9D34BB58EA05B97C44F2`; `localhost:3000` serves the current release.
- Node 24 frontend lint, Vinext production build, and the rendered accessibility/status suite pass 8/8. The required independent Web game client loads the final export with ten facilities and the canonical `flock_relations` projection. Final audits at 2560x1600, 1440x900, 390x844, and 844x390 retain exact 16:9 canvases, zero horizontal overflow, and no console or page errors.

## Flock Provisions Co-op: seasonal feed working capital

- Advanced the authoritative simulation to strict schema v18 and exactly eleven stable facility keys. Neutral schema-v17 migration appends an unowned Flock Provisions Co-op with no invented lots, spend, consumption, or spoilage; current saves validate facility dependencies, finite capacity, FIFO lot identity, acquisition value, expiry, ration terms, daily/lifetime ledgers, and permanent receipts before mutating live state.
- Replaced the flat feed bill with a non-blocking supply chain. Daily demand is three scoops plus one per active hen, existing directive/incident adjustments retain the exact `$2 = one scoop` conversion, and uncovered demand always settles automatically at the deterministic Spring/Summer/Autumn/Winter spot quote. There is no hunger meter or procurement deadlock.
- Added three visible capital tiers at $80 / $140 / $220 and total upkeep of $4 / $8 / $13. Receiving Hopper, Dry Grain Reserve, and Feed Futures Desk tiers store 18 / 36 / 54 scoops and unlock Local Whole Grain, discounted Inspirational Bulk Mash, and Fixed Future Reserve offers with exact prepaid quotes, two-to-four-shift shelf life, FIFO use, ration effects, and real spoilage risk.
- Integrated one review-time procurement authorization directly into Flockwatch without another modal or hotkey. The same canonical projection drives season quote, stock/capacity, demand, coverage, spot obligation, active ration, all three offer cards and hold reasons, plus last delivery, consumption, and spoilage receipts. Farmer review separates prepaid inventory value from automatic spot cost so no scoop is debited twice.
- Built the cumulative southwest governance room with an exact east bridge and 1.10-meter clear aisle. The physical buying desk, scale, hoppers, auger, reserve silo, climate cabinet, futures board, sack lots, fill gauges, quote/expiry screens, and spoilage lamps respond only to authoritative procurement state. High-resolution inspection raised its camera target from 1.05m to 1.50m so the complete strategic silo remains framed during purchases and deliveries.
- Removed redundant live-shift work discovered by the broad induction guard. Flockwatch now retains only the small procurement projection instead of cloning the full Office snapshot, and the room rebuilds labels, materials, binders, and sacks only when its own projection changes. The isolated First Clutch path recovered from the 90-second wall to 66.095 seconds without reducing coverage.

## Flock Provisions final verification

- The finalized Godot 4.7 tree covers all 99/99 `tests/*.gd` scripts in fresh isolated processes with explicit pass markers, zero failures, zero final watchdog misses, and no parser, script, or engine error signatures. Shards 0 and 1 pass 33/33 each; the CPU-heavy third shard passes 33/33 serially under the unchanged 90-second guard. The combined artifact is `output/godot-full-suite-20260715-provisions-final/full-suite-summary.json`.
- Office validation reports 12 collision-free facility footprints, all 18 chicken routes preserved, 19 storytelling roots, 161 mounted signage fixtures with zero floating fixtures, 12 primary landmarks, 214 environmental labels, 197 fitted physical surfaces, and one intentional letterpress layer.
- Native `flock_provisions_coop_level3.png` and the expanded `governance_campus.png` were rendered and inspected at 2560x1440. The Co-op has a coherent teal/wheat/galvanized material identity, architecture-mounted copy, complete unclipped silhouette, readable state screens, and a visually clear connection to the governance spine.
- Generated browser captures and test logs are excluded from Godot resource scanning through `output/.gdignore`; the PCK contains no validation-artifact paths. Final Web releases are byte-identical in both distribution targets. The 5,115,452-byte PCK has SHA-256 `25B4BA4999BEDE9415E5209FD5B2DCA6F2D2055C0764D857C40F03294B991206`, and `localhost:3000` serves that exact file.
- Node 24.18 lint and the Vinext production/rendered suite pass, including all 9/9 accessibility/status cases. The required independent browser client loads the exact final export with eleven facilities and canonical seven-scoop baseline demand, producing a state/screenshot pair with no error artifact. Final audits at 2560x1600, 1440x900, 390x844, and 844x390 retain exact 16:9 canvases, zero horizontal overflow, and no console, page, or request errors.

## Farmer Relations Gallery UI and Web integration

- Added a compact post-credit Farmer Relations Gallery surface inside the existing Flockwatch ledger. It presents authoritative public standing, frozen shift evidence, closing attribution, all three exact campaign offers, explicit authorization holds, and a permanent last-campaign receipt without adding a modal, hotkey, or footer shortcut.
- Reused the existing campaign-review Continue action for an explicit skip path, while campaign publication remains an intent-only Gallery action resolved by the authoritative simulation. The flow keeps Flockwatch open, preserves its scroll position, moves keyboard focus to Continue after resolution, checkpoints accepted decisions, and rejects duplicate filing.
- Published the compact `farmer_relations_gallery` projection through the Office diagnostic bridge and accessible Web status narration. Node 24.18 lint, Vinext production build, and all 10/10 rendered accessibility/status cases pass; focused Godot UI and Office integration tests pass the credit-to-Gallery-to-report and explicit-skip paths.

## Harvest Credit economy, persistence, and world completion

- Advanced the authoritative DepartmentSimulation checkpoint to strict schema v19 and exactly twelve stable facility keys. Neutral schema-v18 migration appends an unowned Harvest Credit Gallery with no invented evidence, standing, attribution, campaign, skip, or receipt history; malformed chronology, facility dependencies, frozen evidence, attribution, and payout ledgers reject before live state mutates.
- Completed the three-tier Gallery economy at $90 / $150 / $240 capital and $5 / $9 / $15 total upkeep. Days 5/9/13, matching Packing Annex tiers, four/five/six authorized desks, and four/five/six active hens gate the cumulative Basket Profile Plinth, Clutch Press Backdrop, and Attribution Archive.
- Added one optional campaign gate after the real closing-credit decision. Layer Profile, Clutch Results Board, and Farmer Method quote directly from frozen sound eggs, golden eggs, quota result, installed tier, and prior standing; standing contributes 0.5% per point to payout up to 25%, and reach adds authored choice value, tier, quota success, and at most two golden-egg points. Explicit skip is permanent and valid, while duplicate or out-of-phase filing is atomic and rejected.
- Made relationship consequences causal. Layer Profile recognizes the named top layer and adds career XP; Clutch Results recognizes every employed hen; Farmer Method raises farmer confidence and standing fastest while lowering trust/compliance, raising grievance/stress, and adding one next-shift quota file. Every accepted choice credits its exact integer payout once and leaves a canonical attribution receipt.
- Built the exact west care-campus parcel, east bridge, and protected 1.10-meter aisle as a cumulative cutaway publicity pavilion. The room now has a modeled walnut-and-brass destination fascia, a plinth-mounted standing screen, separate press-results display, connected basket and wall-light hardware, framed low-alpha glass, connected structural headers, distinct hen/farmer portrait silhouettes, and canonical receipt/attribution surfaces. No visual creates collision or navigation geometry, and no prop or copy enters the protected aisle.
- Added deterministic native Gallery and expanded governance-campus captures. The art path closes a real simulated shift and files a real Gallery campaign without contaminating the unrelated probation record; high-resolution visual inspection drove the final screen separation, fixture attachment, glass, portrait, material, and framing corrections.

## Harvest Credit Godot verification

- The combined Godot 4.7 release artifact covers all 105/105 discovered `tests/*.gd` scripts with explicit pass markers, zero failures, and zero watchdog timeouts at `output/godot-full-suite-20260715-gallery-final/full-suite-summary.json`. The CPU-heavy third shard was rerun serially to avoid two independent processes sharing a temporary campaign-save probe.
- Focused post-polish verification passes `harvest_credit_state_test.gd`, `harvest_credit_economy_test.gd`, `harvest_credit_persistence_test.gd`, `farmer_relations_gallery_ui_test.gd`, `farmer_relations_gallery_visual_test.gd`, `farmer_relations_gallery_office_integration_test.gd`, `office_layout_test.gd`, `office_signage_test.gd`, `environmental_text_fit_test.gd`, `environmental_signage_hierarchy_test.gd`, and `presentation_smoke_test.gd`; the final editor parse is clean.

## Harvest Credit final visual and Web verification

- Native 2560x1440 inspection passes both `harvest_credit_gallery_level3.png` and the expanded `governance_campus.png`. Destination copy is built into walnut-and-brass fascias, operational copy is framed or plinth-mounted, light and sign hardware is visibly attached, primary/secondary/tertiary hierarchy remains legible, full room silhouettes are unclipped, and the Gallery entrance plus exterior aisle remain visually clear.
- The final post-polish focused rerun reports 169 mounted signage fixtures with zero floating fixtures, 227 environmental labels with 209 fitted physical surfaces and one intentional letterpress layer, 12 primary landmarks, 18 preserved chicken routes, 13 collision-free facility footprints, and the exact 1.10-meter Gallery aisle. The editor parser and the authoritative credit-to-Gallery-to-report integration are clean.
- Fresh Godot 4.7 Web release exports are byte-identical across all nine payload files in `docs/` and `web/public/game/`. The 5,193,940-byte PCK has SHA-256 `490C9DD046BF6D5BAF8A99C42C66AEC90989087C258E24C706E6842F6ACACAD5`, and the Node 24 localhost server serves that exact file without stderr output.
- The required independent browser client loads schema v19, all twelve facility keys, the Harvest Credit Gallery, and all three canonical campaign offers without an error artifact. Fresh responsive audits at 2560x1600, 1440x900, 390x844, and 844x390 preserve the exact 16:9 canvas, report zero horizontal overflow, and produce no console, page, or request errors; all four screenshots were inspected clean.

## Farmgate Dispatch and Capital Blueprint completion

- Advanced the authoritative DepartmentSimulation checkpoint to strict schema v20 and exactly thirteen stable facility keys. Neutral schema-v19 migration appends an unowned Farmgate Dispatch Depot plus empty finished-goods, mandate, settlement, pinned-plan, last-commissioning, and commissioning-history ledgers without reclassifying prior egg cash or changing the saved Feed Fund.
- Completed the three-tier Depot economy at $120 / $200 / $320 capital and $7 / $13 / $22 total cold-chain upkeep. Days 6/10/14, four/five/six desks and active hens, matching Packing Annex and Harvest Credit Gallery tiers, and public standing 5/12/25 gate 12/24/42-egg storage, two/three/four-shift shelf life, and 8/16/24-egg county dispatch.
- Deferred sound and golden egg revenue into immutable, named-worker FIFO lots whenever the Depot is commissioned. Farmer Pickup safely clears all eligible lots at recorded value; County Auction freezes the seasonal quote and charges 5% commission; level-three Regional Showcase selects up to six golden-first lots at the standing-adjusted premium and charges a $3 listing fee; Hold the Basket carries stock only when protected obligations remain funded. Overflow sells at 90%, retained eggs cost $0.20, expired eggs cost $0.25 to dispose of, and one exact settlement receipt reconciles every lot and cent.
- Built the exact east distribution parcel as locked, surveyed, Roadside Loading Shed, Chilled County Dock, and Regional Route Fleet states. Its low canopy, sawtooth cold shed, barn-red tower, 42 physical rack cells, connected scale/conveyor/manifest hardware, and Farmer Brand refrigerated truck accumulate by tier while the exact entrance bridge, protected 1.10-meter pedestrian aisle, separate vehicle lane, and all existing chicken routes remain clear. Stock, aging, route terms, overflow, spoilage, and the last manifest mirror only authoritative state.
- Replaced the long default facility scroll with a full-screen Capital Blueprint covering all thirteen Production, Flock, and Governance parcels. Ready/blocked/owned filters and the exact WHY NOW / YOU GET / YOU OWE / AFTER BUILD / GATES inspector use the existing canonical facility preflight; the inline catalog remains available behind an explicit fallback toggle.
- Added a persistent pinned capital plan and strict commissioning receipts. Every accepted tier freezes its facility and level, day, cost, Fund/spendable/reserve/upkeep before and after, upkeep delta, and copied installed effects; rejected purchases append nothing. The Office focuses the real constructed parcel and holds the exact receipt until Continue or Return to Blueprint, while maxing the pinned facility clears that plan and all other pins survive save/restore.
- Integrated Farmgate mandate filing, inventory and settlement narration, the pinned-plan summary, Capital Blueprint entry, commissioning reveal, camera restoration, checkpointing, and accessible Web diagnostics into the existing Flockwatch/farmer-review flow. Good and golden eggs now create visible stock rather than immediate Feed Fund chips, while cracked and storage-overflow cash remain factually distinct.

## Farmgate focused verification

- Focused Godot 4.7 checks pass `farmgate_dispatch_state_test.gd`, `farmgate_dispatch_economy_test.gd`, `farmgate_dispatch_persistence_test.gd`, `capital_plan_commissioning_test.gd`, `farmgate_dispatch_depot_visual_test.gd`, `farmgate_dispatch_ui_contract_test.gd`, and `farmgate_capital_office_flow_test.gd`. The real Office flow proves all thirteen Blueprint parcels, purchase-to-focused-reveal behavior, mandate authorization, deferred good-egg revenue, and immediate cracked-egg accounting.
- Targeted regressions pass `facilities_ui_test.gd`, `facility_office_integration_test.gd`, `office_storytelling_test.gd`, `presentation_smoke_test.gd`, `simulation_persistence_test.gd`, and `staffing_ui_test.gd`; the Godot editor parse is clean. The final isolated-process Godot 4.7 suite discovers, selects, and completes all 115/115 scripts with 115 passes, zero failures, and zero 90-second watchdog timeouts at `output/godot-full-suite-20260715-farmgate-pass/full-suite-summary.json`.
- Native `farmgate_dispatch_locked.png`, `farmgate_dispatch_survey.png`, `farmgate_dispatch_level1.png`, `farmgate_dispatch_level2.png`, `farmgate_dispatch_level3.png`, `dispatch_campus.png`, `capital_blueprint.png`, `farmgate_commissioning_reveal.png`, and `expansion_overview.png` were rendered and inspected at 2560x1440. Locked and surveyed parcel copy now uses attached modeled lettering; five authoritative stored lots visibly fill five warm kraft rack cells; the cumulative silhouette, road connection, route fleet, spatial Blueprint, and player-held receipt remain coherent and unclipped.
- Fresh Godot Web releases are byte-identical across all nine deployable payloads in `docs/` and `web/public/game/`. The 5,354,068-byte PCK has SHA-256 `707961B3BD034C55A5676789B464DE7F00F0A26125436871DFB24AA4A6407C3B`, and `localhost:3000` serves that exact payload. Node 24 frontend lint and production build pass; the rendered accessibility/status suite passes all 12/12 cases, including authoritative Farmgate inventory/settlement and Blueprint/commissioning narration.
- The required independent browser client passes both the raw export and the complete Web wrapper. It advances beyond the title, records a live `godot_canvas` diagnostic with all thirteen facilities and the Farmgate Depot, and produces no console/page-error artifact. The final responsive audit at 2560x1600, 1440x900, 390x844, and 844x390 preserves the 16:9 canvas, reports zero horizontal overflow and zero browser errors, and all four screenshots were inspected clean.

## North Meadow: first player-expandable campus parcel

- Advanced the authoritative simulation to strict schema v21 while preserving exactly thirteen fixed facility keys. A separately validated `campus_expansion` ledger now owns North Meadow's deed, circulation/power/cold-chain services, Egg Routing Pod placement, recurring cost, capital history, receipt identity, and neutral schema-v20 migration.
- Added a reserve-safe campus economy with exact integer-cent quotes: $85 land plus $3/day, $28 circulation plus $1.50/day, $35 power plus $2.25/day, $60 cold-chain plus $4/day, $75 routing pod plus $5/day, and optional $18 relocation. The full build is $283 and $15.75/day; one relocation makes lifetime capital $301 without duplicating upkeep.
- Gated deed access behind either Farmgate Dispatch Depot level one or legitimate Bronze Farm Mutual standing. Every accepted action replays through an immutable receipt; rejected, unaffordable, dependency-invalid, route-blocking, stale-relocation, and corrupted-save actions remain atomic and cannot drive the Feed Fund below zero.
- Made physical commissioning economically causal. The pod adds six live-file slots only after land, placement, circulation, and power are all live. Cold-chain adds six real Farmgate storage positions only with an operational pod, including a persisted level-three ceiling of 48 lots and a 49th-lot 90-percent overflow sale.
- Built the exact `12.80m x 11.80m` North Meadow 20 cm north of Farmgate with a protected 2.10-meter circulation/service spine, Meadow West and Meadow East legal pads, and a visibly barred Service Spine socket. Deed, site-work, utility, pod, operational, and cold-chain stages use attached low-poly hardware, readable fences, trench/conduit/meter detail, route markings, and a movable Egg Routing Pod without adding collision or runtime navigation nodes.
- Integrated the parcel into the full-screen Capital Blueprint and a responsive, hidden-by-default land-and-utilities planner. The planner publishes only player intent; Office routes every request through the simulation, keeps exact blocked reasons and costs beside the selected socket, focuses accepted construction, stamps one receipt, checkpoints the campaign, and returns cleanly to the still-held Blueprint.
- Derived overview camera bounds and the reserved navigation footprint from the installed parcel. Unowned land changes neither. The visual, planner, Office diagnostic bridge, Web narration, autosave, and commissioning history all consume the same canonical snapshot.
- Tightened the new environmental copy after the broad signage audit: North Meadow owns one primary destination landmark, the pod fascia remains subordinate machine detail, and every new panel or meter label now sits 10 mm from its modeled host instead of floating in screen space.

## North Meadow final verification

- The clean Godot 4.7 isolated-process suite discovers and passes all 123/123 `tests/*.gd` scripts across three shards, with zero failures and zero 90-second watchdog timeouts at `output/godot-full-suite-20260715-campus-pass/full-suite-summary.json`. Coverage includes the real Blueprint-to-deed-to-services-to-placement-to-relocation Office path, exact $301 lifetime capital, exact $15.75/day upkeep, route rejection, derived camera/navigation bounds, strict v20 migration, 48-lot Farmgate persistence, and corruption atomicity.
- The final office-signage audit reports 191 modeled fixtures, zero floating fixtures, and a mounted hierarchy. The deterministic `campus_expansion_operational.png` capture was rendered and inspected at 2560x1440; its 647,015-byte PNG has SHA-256 `685F942C0114A96DB5619C37B25486319ADCE13E52C7F756DB61CFC1426D23A3`.
- Fresh Godot Web releases are byte-identical across all nine deployable payloads in `docs/` and `web/public/game/`. The 5,461,504-byte PCK has SHA-256 `499FEB1E18E2BB6965A60C8A684762F49A269E9B44DDDA6925EA8FCC238B897B`, and `localhost:3000` serves that exact payload.
- Node 24 frontend lint and Vinext production build pass; the rendered accessibility/status suite passes 13/13 cases, including North Meadow access, service, route, placement, recurring-cost, and operational-benefit narration. The required independent browser client loads the current raw export and complete wrapper with a live canonical `campus_expansion` diagnostic and no console or page-error artifacts.
- Final responsive audits at 2560x1600, 1440x900, 390x844, and 844x390 retain the exact 16:9 canvas, zero horizontal overflow, and zero browser errors. The 844-pixel landscape briefing now stacks at a readable width instead of squeezing the long economy explanation into three narrow columns; all four final screenshots were inspected.

## Next unmet full-economy milestone

- Turn the single-parcel proof into a multi-parcel construction portfolio. The next milestone should add second and third deeds, several simultaneous module types, real construction duration and contractor capacity, shared power/cold-chain throughput, runtime path-graph updates around installed footprints, named chickens who commute into and staff placed modules, and collection-rail topology that grows with the campus. It also needs quota, coordination, payroll, and rooster-span scaling plus a strict schema-v21-to-v22 migration that preserves every existing parcel, desk, worker, receipt, and route.

## Environmental text integration pass

- The latest request supersedes the pending portfolio milestone for this pass: make office text feel native to the low-poly environment.
- Baseline browser inspection at `output/web-game/shot-0.png` and the native signage/campus captures found two concrete offenders: every live operational screen is treated as an overview landmark, and several large destination/socket panels have weak or invisible physical support. This leaves bright hairline glyphs and dark rectangles competing with the chunky room geometry.
- The implementation target is intentionally visual-only: retain exact authored gameplay copy and accessibility narration, keep physical monitors/plaques present, reserve detailed glyphs for local camera focus, integrate major signs into visible beams/posts/rails, and preserve all collision/navigation geometry.

## Environmental text integration completion

- Rebuilt the shared signage hierarchy so only permanent identity and destination landmarks stay legible in the management overview. Operational monitor glyphs, permits, utility notices, and other detail copy now reveal at local camera focus while their modeled screens, frames, paper, and substrates remain visible. Added an explicit critical-readout opt-in and a dynamic-copy refit path instead of treating every screen as a landmark.
- Integrated the five newest room identities into their architecture: Wellness Nest uses a framed recovery lintel, Training Roost a clamped lesson rail, Rooster Operations a bracketed structural lintel, IT Coop an equipment-rack bay, and Flock Relations a smoked-glass transom. North Meadow now uses a post-supported timber gate, deed plate, clipped permit, ground-inlaid socket stencils, and an attached Service Spine keep-clear plate.
- Removed the last camera collision between parcels. The oversized Farmgate locked-parcel destination slab is now a compact two-stake boundary permit on the depot's own south lease line, so it no longer appears behind `NORTH MEADOW`. The copy reads as pinned paperwork, recedes outside local focus, and remains inside the exact collision-free parcel.
- The final focused verification passes all 13 signage, text-fit, facility-visual, layout, and presentation tests. The broad audits report 193 modeled fixtures with zero floating fixtures, 12 overview landmarks, 261 environmental labels, 240 fitted surfaces, and one intentional letterpress layer. The complete isolated-process Godot 4.7 suite passes all 123/123 discovered scripts with zero failures and zero watchdog timeouts at `output/godot-full-suite-20260715-environment-signage-final/full-suite-summary.json`.
- Native 2560x1440 captures were inspected for the core signage views, North Meadow, Care Campus, Operations Campus, and Flock Relations. The final North Meadow capture is 638,997 bytes with SHA-256 `194E1EAB0822FC35EC7D3C5C32BF5A243F9B9B6332FCEB55CA1272540307C8B8`; no unsupported or overlapping notice remains in its view.
- Fresh Godot Web payloads are byte-identical across all nine deployable files in `docs/` and `web/public/game/`. The 5,466,816-byte PCK has SHA-256 `3005E5FC6558620092CECB694675FA75161FD2CA1EAF1F2086118A89A31AFE57`. Node 24 lint, Vinext production build, and all 13/13 rendered accessibility/status tests pass.
- The required independent browser client loads the refreshed export, advances into the live office, and produces a screenshot/state pair with no error artifact at `output/web-game/environment-signage-final-direct/`. Responsive audits at 2560x1600, 1440x900, 390x844, and 844x390 report a loaded Godot canvas, zero horizontal overflow, and zero console or page errors; all four screenshots were inspected at original resolution.

## Campus portfolio Web narration

- Integrated the canonical `campus_portfolio` and `campus_portfolio_planner` diagnostics into the browser wrapper. Accessible status now narrates all three deeds, active and queued construction with stage and remaining shifts, Feed Fund/reserve plus contractor/power/cold capacity, and named-hen staffing/operational state.
- Preserved the dedicated North Meadow planner as the higher-priority utility-detail narration and expanded the management briefing with Orchard Row, Creekside Yard, all four portfolio modules, finite shared resources, construction duration, and the staffed-benefit gate.
- Node 24 lint and production build pass; all 14/14 rendered accessibility tests pass. The required independent client captured a loaded live office and diagnostic state with no error artifact at `output/web-game/campus-portfolio-wrapper/`; `shot-0.png` was inspected cleanly. The supplemental 1440-pixel full-page capture confirms all three briefing cards, both North Meadow and portfolio copy, and zero horizontal overflow.

## Multi-parcel Campus Portfolio completion

- Completed the formerly unmet portfolio milestone and advanced DepartmentSimulation to strict schema v22. Neutral v21 migration creates no land, project, staffing, or receipt history; strict v22 restore validates exact deeds, installed-pad identity, FIFO projects, historical prices, named employed staff, utility capacity, and capital totals before committing atomically.
- Added Orchard Row and Creekside Yard as real player-owned deeds beyond North Meadow. Orchard Row costs $125 plus $4.50/day and unlocks on Day 6; Creekside costs $165 plus $5.50/day, unlocks on Day 9, and requires Orchard Row. One-cent-short, dependency, reserve, stale-state, duplicate, and corrupted-history attempts reject without mutating cash or state.
- Added four cumulative placed modules with visible construction: Collection Rail Hub ($140, two shifts, +4 live files and +$0.25 to sound/golden eggs), Grain Recovery Mill ($160, three shifts, +18 feed storage and one-scoop demand reduction), Creekside Chilling Exchange ($200, three shifts, +12 finished eggs and 95% overflow settlement), and Contractor Roost ($130, two shifts, +1 contractor slot). Each adds exact daily upkeep and only becomes economically operational when complete, staffed by an available named hen, powered, and cold-connected where required.
- Construction now reserves finite contractor slots, power units, and cold-chain units, advances active work once per completed shift, and promotes queued work in immutable FIFO order. Contractor Roost can expand the queue from one to two concurrent slots only after its own staffed, powered commissioning; installed modules never duplicate capital or recurring cost.
- Integrated every module benefit into the existing live economy rather than a display-only projection: claim admission, egg settlement value, Feed Provisions capacity/demand, Farmgate storage and overflow, protected operating reserve, facility upkeep, worker release rules, and $1/day named campus-duty premium all reconcile in the shift report and save file.
- Built exact `12.80m x 11.80m` Orchard Row and Creekside parcels with 20 cm seams, four legal module pads, two barred service pads, staged survey/foundation/frame/complete geometry, attached destination gates, module fascias, collection rails, power conduit, cold line, meter hardware, road markings, orchard planting, and creekside reeds/rill. The complete low-poly portfolio has zero collision/navigation nodes and publishes deterministic parcel, pad, cross-route, trunk, and camera contracts.
- Replaced the former North-only Blueprint jump with a responsive three-deed Campus Portfolio. It compares deeds, construction queue, contractor/power/cold capacity, exact capital and recurring costs, installed effects, pad compatibility, and named staffing; North Meadow still drills into its detailed utility planner and both nested surfaces return to the held Blueprint without losing focus.
- Added canonical browser narration for all three deeds, project stage/remaining shifts, finite resources, Feed Fund/reserve, named staffing, and operational state. The wrapper continues to prioritize the detailed North Meadow surface when it is the active nested planner.

## Named campus commute and final verification

- Named staffed hens now physically leave their chairs, clear workstation production immediately, walk the authored desk lane and main aisle, use the connected care/operations spine, round the north/east campus perimeter, and enter the correct Orchard Row or Creekside cross-route. They hold at a module-facing duty socket, ignore office break/feed/staging reroutes, and only regain claim and egg eligibility after the full return trip and visible seated blend.
- The route registry updates from the canonical installed pad and worker assignment, supports unassignment while outbound plus same-hen reassignment without a presence blip, excludes remote hens from predator selection and Feed Party quorum, expands overview bounds to contain the visible commute, and uses a brisk campus-only walk multiplier without skipping a waypoint.
- `campus_portfolio_commute_layout_test.gd` proves all six desks by four pads in both directions: 48 axis-aligned authored routes, zero blocker intersections, zero diagonal corner cuts, a conservative 0.60 m puffy-chicken sweep against a measured 0.571 m maximum silhouette, 0.75 m minimum declared-blocker clearance, and exact duty sockets 1.80 m ahead of module pads. ChickenView and real Office integration tests prove outbound hold, queued reassignment, desk-production exclusion, return-to-chair seating, and existing egg-seat gating.
- The clean isolated-process Godot 4.7 suite discovers and passes all 132/132 `tests/*.gd` scripts across three shards, with zero failures and zero 180-second watchdog timeouts at `output/godot-full-suite-20260715-portfolio-pass/full-suite-summary.json`. The broad signage audit now reports 212 mounted fixtures, zero floating fixtures, and seventeen primary landmarks: one bureau identity plus sixteen destinations including all three campus deeds.
- Fresh native 2560x1440 captures were inspected for the complete world and responsive planner. `campus_portfolio_complete.png` is 1,009,535 bytes with SHA-256 `8192A8F5FF1482059DAD85AE3A7545F5444F2E2C3770106E16A02CB41FC829BE`; `campus_portfolio_ui.png` is 530,312 bytes with SHA-256 `8205D2F0D861BEB83FFC9DF7114DD174E996EEB615BBCDAE480C2A6A7141755A`.
- Fresh Godot Web releases are byte-identical across all nine deployable files in `docs/` and `web/public/game/`. The 5,621,944-byte PCK has SHA-256 `55F1733424F87A05410BAD404C71B09A4E70D46A5854B28F64E23560CB54727D`, and `localhost:3000` serves that exact byte count and hash.
- Node 24 frontend lint, Vinext production build, and all 14/14 rendered accessibility/status tests pass. The independent browser client advances into a loaded `godot_canvas`, exposes canonical portfolio version 1 with three deeds/four modules and no error artifact, and its screenshots were inspected cleanly at `output/web-game/campus-portfolio-final-client/`.
- The final responsive audit at 2560x1600, 1440x900, 390x844, and 844x390 reports a loaded live canvas, exact 16:9 canvas ratio, zero horizontal overflow, and zero console/page errors at `output/web-game/campus-portfolio-final-responsive/audit.json`; all four full-page captures were inspected at high resolution.

## Campus Build Reveal

- Replaced opaque post-purchase planner feedback with a held live-world reveal for every accepted portfolio deed, active/queued project authorization, contractor mobilization/completion, and named-hen staffing action. Office now reconciles the canonical snapshot, closes the portfolio, focuses the exact parcel or module/pad, and exposes the already-changed world behind the receipt.
- Preserved the authoritative raw receipt while adding factual context for parcel, pad, module, worker, cost, daily obligation, capacity use, installed effects, and outcome. Rejected actions still create neither geometry nor reveal, and accepted actions never optimistically disappear behind a short camera animation.
- Added player-held **Continue** and **Return to Portfolio** actions outside the scrolling receipt. Continue consumes one exact reveal and advances through queued shift-boundary receipts; Return and `Esc` restore the planner without undoing the transaction. Keyboard focus, 844x390/390x844 layouts, reduced motion, and Farmer Review origin restoration are covered explicitly.
- Construction boundaries queue behind Farmer Review instead of interrupting the close. Returning to campus planning reveals completion before mobilization in receipt order, with the completed module or next foundation already visible and the temporary world marker cleared after acknowledgement.

## Farm Treasury and Department schema v23

- Advanced DepartmentSimulation to strict schema v23 with a conserving `farm_treasury_state`. Neutral v22 migration preserves only the real Feed Fund and completed-day chronology, inventing no principal, vendor/interest arrears, credit rating, or history; strict restore validates exact keys, integer cents, receipt chronology, deterministic replay, and one-cent tamper rejection before atomic commit.
- Routed categorized production and settlement inflows, feed/facility/campus/Farmgate vendor obligations, current plus carried wages, interest, line draws, principal repayment, and closing cash through one immutable shift-close receipt. Every accepted close proves `opening cash + inflow + credit draw = interest + vendors + labor + principal repaid + closing cash` exactly.
- Preserved labor as an external protected obligation: cash may pay wages only after interest/vendors, automatic credit can pay interest and vendor invoices but never labor, and any shortfall remains explicit wage arrears. Filed Treasury liabilities join protected reserve; debt with exhausted headroom forces spendable capital to zero instead of allowing an unfunded requisition.
- Added the standing/rating line economy: $50 base plus $5 per Farm Mutual standing point to a $150 pre-rating cap; three profitable debt-free closes advance Field File -> Steady Ledger -> Prime Roost; each rating adds $25 capacity and reduces the 5% per-shift rate by one point, to a $200/3% ceiling. Flockwatch exposes rating, line, principal, headroom, rate, vendors, interest, wages, and capital freeze; Farmer Review itemizes the complete conservation receipt.
- Focused `farm_treasury_state_test.gd`, `farm_treasury_department_test.gd`, `staffing_economy_test.gd`, simulation persistence, Farmgate, market, operations, petitions, feed, facilities, campus, and adjacent migration checks pass with exact zero-cash vendor draw, credit-never-wages, conservation, round-trip, and freeze coverage. Stale human-readable Department-schema labels were aligned to v23 while historical v21/v22 migration descriptions remain intact.

## Senior Board Mandates and Senior schema v3

- Advanced the nested Senior Roost ledger to schema v3. Every Senior year now freezes exactly three deterministic annual Board Mandate cards from its opening context before the first quarterly capital policy; Standard Board Book is always the first, free, available fallback, so the new gate cannot deadlock.
- Added seven authored books across four seal tiers. Tier-zero Standard Board, Shell Stewardship, and Flock Continuity risk no marks and award one Board Seal; 1/3/6 lifetime seals unlock 2/4/6-mark Mutual Assurance or Executive Harvest, Rested Flock, and Gold Standard stakes with 2/3/4-seal rewards.
- Recorded one compact authoritative evidence row per accepted Senior shift and exposed twelve-shift progress, quarterly checkpoints, objective actual/target values, next threshold, and largest recoverable blocker in the Senior Career + Board Forecast. Duplicate days and stale-year selections reject without mutating the career file.
- Settled each annual mandate exactly once beside—not instead of—the ordinary Senior annual review. Success returns the exact reserved stake and files seals; failure permanently spends the stake and awards none. Active stakes are excluded from available Roost Marks, preventing the same marks from also funding Career Sponsorship.
- Added neutral schema-v2 migration: an untouched first-year gate receives fresh offers; an already-running year receives a grandfathered no-stake Standard Board Book whose settlement awards and forfeits nothing. Focused mandate, base Senior, sponsorship, and Senior economy state tests pass deterministic offers, twelve-shift evidence, exact settlement, tier unlocks, stake return/forfeiture, JSON round-trip, and atomic tamper rejection.

## Documentation and discoverability reconciliation

- Updated README and the expansion/economy guide to describe current Department schema v23, nested Senior schema v3, all three campus deeds, finite construction resources, staffed-benefit gates, authored commutes, the held Campus Build Reveal, Farm Treasury conservation/credit limits, and annual Board Mandates.
- Documented the player-facing route through the new systems: Flockwatch (`V`) for Treasury liabilities and live Senior/Board forecasts; the existing `1`-`3` plus `Enter` decision flow for annual mandate selection; Capital Blueprint -> Campus Portfolio for deeds/modules/staffing; and Continue/Return/`Esc` for receipt acknowledgement. Historical schema statements remain historical rather than being relabeled as current behavior.

## Full-goal release verification

- The final isolated-process Godot 4.7 suite discovers and passes all 137/137 `tests/*.gd` scripts across three shards with zero failures and zero 120-second watchdog timeouts at `output/godot-full-suite-20260715-goal-final/full-suite-summary.json`. This includes economy conservation, schema migration/tamper rejection, the Senior mandate flow, campus construction/reveals/commutes, egg-seat gating, environmental text fit, presentation, and responsive UI coverage.
- After the final web-diagnostic bridge, Godot editor parsing plus the presentation smoke, Flock Provisions/Treasury UI, and Senior Office integration regressions pass again. The exported live diagnostic now carries the canonical `farm_treasury` snapshot used by the wrapper instead of leaving its Treasury narration fixture-only.
- The Vinext production build and ESLint pass under the compatible workspace runtime; all 18/18 rendered browser narration tests pass for commissioning/campus precedence, annual mandate selection, active blocker progress, mandate settlement economics, and conditional Treasury posture.
- Fresh Web releases are byte-identical across all nine deployable payloads in `docs/` and `web/public/game/`. The final 5,710,928-byte PCK has SHA-256 `8174B5C6B40B19291D089ECBBEAE225293A021FD963FFD11B05B036DBD926516`.
- The required high-resolution browser audit at 2560x1600, 1440x900, 390x844, and 844x390 loads the final Godot canvas and canonical Treasury diagnostic with zero console/page errors and zero horizontal overflow at `output/web-game/goal-final-responsive/audit.json`. All four full-page screenshots were inspected at original resolution; the stage remains centered at maximum width, the ordinary desktop composition is balanced, portrait mobile provides an explicit fullscreen/rotation cue, and landscape retains readable controls without viewport-relative drift.

## Environmental signage integration polish

- Audited the current office at gameplay scale and through the four authored 2560x1440 signage captures. Physical attachment was already sound; the remaining mismatch was visual hierarchy: a large back-wall fascia carried undersized lettering, modeled headings mixed with flat subtitles, and pale cubicle inserts became blank rectangles when overview LOD hid their microcopy.
- Enlarged the architectural title's authored face-height, converted architectural and destination subtitles to shallow modeled lettering with hidden semantic proxies, and retained the existing focus-aware LOD so subordinate copy only appears near the inspected location.
- Reworked cubicle nameplates into dark institutional laminate tags with brass memo rails, a registration tab, and a permanent egg seal. Names remain readable in close focus, while overview now retains purposeful office hardware instead of a pale empty card.
- Added regression contracts for neutral readable-face transforms, fully modeled title/subtitle treatment, stronger primary hierarchy, and non-text desk identity cues. `environmental_signage_hierarchy_test.gd`, `office_signage_test.gd`, and `environmental_text_fit_test.gd` pass after the change.
- Fresh `signage_back.png`, `signage_left.png`, `signage_desk.png`, and `signage_intake.png` captures were inspected at original 2560x1440 resolution. The back-wall bureau wordmark now has a decisive architectural scale, the modeled subtitle remains subordinate, and the desk insert reads as mounted dark laminate rather than a blank UI card.
- Fresh Web releases are byte-identical across all nine deployable payloads in `docs/` and `web/public/game/`. The 5,711,904-byte PCK has SHA-256 `47AF795CD81A2B67DBE8EC64B47569318E9DB43724949123F2271DADE7D01975`.
- The installed independent browser client produced a fresh canvas screenshot plus canonical diagnostic state with no error artifact at `output/web-game/environment-signage-final-client/`. The in-app browser also advanced through orientation and policy selection into the live office with zero warnings or errors.
- Responsive audits at 2560x1600, 1440x900, 390x844, and 844x390 report a loaded 16:9 Godot canvas, zero horizontal overflow, and zero console or page errors at `output/web-game/environment-signage-responsive-final/audit.json`; all four full-page captures were inspected at original resolution. `presentation_smoke_test.gd` and `office_detail_test.gd` pass alongside the three focused signage regressions.

## Environment-native text and materials

- Reworked the shared signage treatment around the office so environmental words inherit the object carrying them instead of reading like detached interface cards. Paper notices now use warm stock and clipped margins, department plaques use aged enamel with rails, lips, screws, and contact shadows, workstation inserts use pale cubicle stationery, host print uses its own substrate, and live screens remain visibly electronic.
- Strengthened the print hierarchy with warmer, heavier pigment, safer protected margins, automatic ink/substrate contrast, a larger Bureau subtitle, and physical mounting cues. Text content and semantic accessibility proxies remain unchanged; only its modeled presentation and hierarchy changed.
- Regenerated and inspected `captures/signage_back.png`, `captures/signage_left.png`, `captures/signage_desk.png`, and `captures/signage_intake.png` at 2560x1440. The focused signage suites pass 212 modeled fixtures with zero floating labels, 286 environmental labels with 252 fitted surfaces, and the hierarchy, office-detail, storytelling, layout, visual-systems, and presentation contracts.

## Comfort, control, audio, and safety pass

- Added a persistent F10 Comfort + Controls surface with independent Master, SFX, UI, and Music levels; reduced motion; high contrast; UI scale; quality and timing assistance; eleven semantic keyboard/gamepad actions; conflict-safe rebinding; reset controls; dynamic binding hints; and focus-safe pause/return behavior.
- Added routed UI, SFX, ambience, and music buses plus an adaptive office audio director. Preferences publish immediately to the browser accessibility diagnostic, including while the settings surface has paused simulation, so visible controls and assistive narration remain in sync.
- Gated the predator development shortcut behind both a debug build and the exact `--enable-predator-debug` launch argument. Production/web play can no longer trigger it accidentally.
- Added a deterministic seven-profile, four-hen campaign balance harness driven through authoritative ticks, reports, and decisions. The balanced hybrid reaches Trusted Layer through all five shifts with score 66, welfare 49, compliance 82, favor 55, and 19.21% cracks while affording an upgrade on Day 1 and a facility on Day 2; no balance constants required adjustment.

## Final release verification

- The final isolated-process Godot 4.7 suite discovers and passes all 145/145 scripts with zero failures and zero timeouts at `output/godot-full-suite-20260715-production-readiness-final/full-suite-summary.json`. Coverage includes signage/text fit, office clearance, seated-only egg production, campus duties and commutes, settings persistence, audio, presentation, debug gating, and the deterministic campaign playthrough.
- Browser settings persistence passes a visible high-contrast toggle, reload restoration, final reset, all eleven dynamic bindings, compact 844x390 layout, and zero console/page errors at `output/web-game/final-settings-persistence-20260715/audit.json`.
- The Node 22 frontend lint and Vinext production build pass, and all 20/20 rendered accessibility/status tests pass, including responsive canvas backing, Comfort + Controls precedence, and the complete economy/career narration stack.
- Responsive browser audits at 2560x1600, 1440x900, 390x844, and 844x390 retain a centered 16:9 game canvas, zero horizontal overflow, and zero console/page errors at `output/web-game/final-settings-responsive-20260715/audit.json`; all eight settings/responsive captures were inspected at original resolution.
- The required independent game client advances the freshly served raw export into Mabel's live 8:06 AM office with no error artifact. Its final gameplay-scale presentation capture was inspected at `output/web-game/environment-text-final-direct-client/shot-0.png`.
- Fresh Web releases are byte-identical across the served localhost package, `docs/index.pck`, and `web/public/game/index.pck`. The final PCK is 5,786,568 bytes with SHA-256 `0738EF3BB7246CE577F94308B40A9FFCF692BBD3EEE29A69E90D7F6D026B3BF6`.

## Opening experience, organic expansion, and menu audit

- Read-only audit confirms that the detailed 24 m x 18 m core office is worth preserving; the opening sprawl comes from a campus-sized base camera frame, unconditional construction of future facility roots and long circulation spines, Day-1 North Meadow presentation, and locked/empty parcels appearing before they matter.
- The first-clutch view simultaneously exposes the two-row HUD, routing queue, campaign badge, Flockwatch, coach card, selected-hen dossier, route/personnel controls, and ticker. Flockwatch then nests campaign, flock, staffing, Treasury, capital, facilities, applicants, Procurement, Farmgate, labor, directives, and metrics in one narrow scroll.
- Recommended a presentation-only reveal layer with `hidden`, `teased`, `offered`, and `commissioned` states derived from existing authoritative campaign/simulation data. Economy rules, costs, facility IDs, world coordinates, receipts, saves, and shortcuts remain unchanged.
- Recommended a core-office Day-1 camera, visible bounds derived only from discovered/owned content, one future expansion teaser at a time, segment-by-segment circulation growth, and reuse of the existing commissioning reveal for earned physical expansion.
- Recommended a minimal live HUD, one contextual hen drawer, progressive First Clutch controls, and domain-based Flockwatch pages for Today, Flock, Operations, Capital, and later Governance/Records. Full Blueprint, Portfolio, Settings, and review surfaces remain available as focused planning views.
- Proposed verification gates: at least 65-70% unobstructed world at 1280x720 during the first five minutes, no undiscovered parcel geometry in the Day-1 overview, one primary call to action, every current feature reachable once relevant, old-save restoration, unchanged economy receipts, safe keyboard/controller focus, and high-resolution captures at fresh, Day-3, Day-6, Day-9, and Senior milestones.
- No game or frontend source files were changed during this audit.

## Organic opening implementation in progress

- Reframed the default management camera around the occupied 24x18 bureau instead of the mature 39.45x48.20 campus footprint; future discovered/commissioned parcels will expand that frame.
- Changed unused workstation presentation to show only the next authorization bay while preserving all six desks and their progression.
- Converted the permanent bottom ticker into a short-lived, non-blocking status toast while retaining exact legacy message copy and an in-memory history buffer.
- Changed Capital Blueprint to open on authoritative READY projects, fall back to OWNED/ALL only when needed, and keep all thirteen stable facility controls accessible through ALL PLANS.
- `capital_blueprint_ui_test.gd` passes with the new Ready-first disclosure and full facility/action preservation.
- Progressive campus visibility, Flockwatch navigation, and First Clutch contextual disclosure are being integrated next.

## Organic opening implementation integrated

- The office now derives presentation bounds from the occupied core plus only discovered, offered, pinned, or commissioned campus footprints. Future facility roots, distant meadow/portfolio geometry, unused corridor bays, and service trunks stay hidden until they become relevant; later saves reconstruct their earned campus without changing simulation data or coordinates.
- Flockwatch now preserves every existing control and signal across five independent pages: Today, Flock, Operations, Capital, and Governance / Records. First Clutch opens with Today and Flock, authored deep links discover the single relevant page, and `All Filings` remains a permanent escape hatch to the complete feature set.
- Roost Staffing content is separated into Flock, Operations, Capital, and Records presentation roots while retaining one authoritative component. Requisitions, Procurement, Farmgate, facilities, Treasury, applications, care, and governance actions continue to forward through their original signals.
- First Clutch now reveals the hen dossier and controls stage by stage: identity, routing, check-in, Priority Peck, then delivery. Advanced career, care, trust, and grievance detail is available through a compact details control, and skipping or completing induction restores the full management surface.
- Campaign, decision, review, commissioning, settings, and portfolio surfaces now suppress background HUD and routing chrome while active. Flockwatch likewise becomes the focused management surface instead of stacking over the live dossier.
- Focused component coverage passes for progressive campus reveal, Flockwatch page discovery and control reparenting, contextual First Clutch disclosure, Ready-first Blueprint filtering, and paged staffing with next-workstation-only signposting. Downstream capital, procurement, relations, and gallery integrations are being reconciled with the new page locations before export.
- Integration coverage caught and fixed a real composition-order defect: staffing domain roots now move into Flock, Operations, Capital, and Records before the legacy Today scroll is adopted, and `RoostStaffingUI` can safely build its interface before `_ready()`. Capital Blueprint, Farmgate, Flock Provisions, applicant, Flock Relations, and Gallery controls now live on their intended pages.
- The review Continue action is page-independent inside Flockwatch, so Gallery filing and skip flows cannot strand the required next step on Today while the player is reading Records. Identity, signals, visibility, deferred focus, and page-scroll preservation are covered.
- Focused authoritative integrations now pass for the compact opening, campus expansion/commute, complete First Clutch induction, staffing/capacity/hiring, Capital Blueprint commissioning, Farmgate routing, Flock Provisions ordering, Flock Relations disposition, and Farmer Relations Gallery credit. The next gate is a fresh browser export and high-resolution visual inspection.

## Organic opening final verification

- Reframed a fresh campaign around the occupied Egg Yield Bureau instead of the eventual campus footprint. Future facilities, unused service spines, distant parcels, and all but the next inactive desk marker now stay presentation-hidden until an authoritative offer, pin, purchase, or later-save ownership makes them relevant; the overview camera expands from the compact core using only those visible footprints.
- Reorganized Flockwatch into Today, Flock, Operations, Capital, and Records pages without deleting or duplicating any simulation feature. First Clutch begins with only Today and Flock, later context reveals the appropriate pages, `All Filings` exposes the complete registered catalog, every page keeps its own scroll position, and required Continue actions remain page-independent.
- Reduced opening HUD competition with a one-row First Clutch objective treatment, stage-specific routing dossier sections, adaptive routing/coach placement, a short-lived centered status toast plus retained history, and suppression of background controls or campaign badges while a blocking management surface is open.
- Final accessibility review closed five state/focus gaps without changing the presentation: managed shortcuts cannot fire behind any capital or reveal modal, direct Blueprint close returns to its real invoking control, a successful New Campaign restores the Ready-first filter while preserving All Plans, reparented Capital cards keep focus and page scroll through live rebuilds, and First Clutch moves focus before hiding Skip.
- The final isolated-process Godot 4.7 suite discovers and passes all 152/152 `tests/*.gd` scripts across three shards with zero failures and zero 300-second watchdog timeouts at `output/godot-full-suite-20260716-organic-opening-a11y-pass/full-suite-summary.json`. This includes the original economy, staffing, feed procurement, campaigns, Treasury, campus portfolio, save migration, chicken seating, and expansion flows as well as the new campus-presentation, Flockwatch-navigation, opening-progression, modal-input, and focus regressions.
- Frontend ESLint, the Vinext production build, and all 21/21 rendered-page tests pass under the compatible Node 22 workspace runtime. The final four-size browser audit at 2560x1600, 1440x900, 390x844, and 844x390 reports a loaded exact-16:9 Godot canvas, zero horizontal overflow, and zero console/page errors at `output/web-game/organic-opening-final-a11y-responsive/audit.json`; all four captures were inspected at original resolution.
- A final independent live-canvas client advanced the exported game through orientation, campaign start, and opening Flockwatch, then produced the inspected clean capture at `output/web-game/organic-opening-final-a11y-live/shot-0.png`. Today/Flock are the only opening tabs, `All Filings` is reachable, the compact office remains visible beside the panel, and no badge or HUD overlaps its header.
- Fresh Godot Web releases are byte-identical across all nine deployable files in `docs/` and `web/public/game/`. The final 5,854,388-byte PCK has SHA-256 `259ED8E9E580192D4F360C052E872A9C2EEEB2816AD4D15364E1CD68F5218DA7`, and `localhost:3000` serves that exact byte count and hash.

## Input-complete, announced Flockwatch

- Closed the focused-management input gap found during the production audit. Opening Flockwatch now stores the prior keyboard focus, focuses the active page tab, returns the camera to the overview, and suspends camera and peckwork-routing interaction until the drawer closes. `V`, `Back`, `Escape`, and controller Back close the drawer and restore its real opener; modal-to-Flockwatch transitions avoid stealing focus from the next surface.
- Added context-owned keyboard and controller navigation. Tab focus, D-pad left/right, shoulder cycling, and the existing hen-cycle action now move through actual available Flockwatch pages while the drawer is open, without selecting hens, changing speed, or moving the camera. After close, those inputs return to their ordinary office meanings.
- Added a persistent `Latest notice` card fed by the same authoritative status receipts and guidance used elsewhere in the office. It survives transient toast expiry, participates in the Flockwatch accessible summary, and updates the browser diagnostic immediately while visible.
- Extended the web accessibility bridge with a bounded, markup-stripped Flockwatch diagnostic and live-region narration. Visible Flockwatch takes precedence over ordinary gameplay narration, reports its current title and available pages, and deduplicates the latest notice instead of repeating it.
- Added `flockwatch_input_context_test.gd`, which injects real keyboard and controller events and proves open/focus, camera and routing suspension, D-pad/shoulder page navigation without action leakage, live success and denial notices, close/focus restoration, and post-close input ownership. Existing Flockwatch navigation, opening progression, settings, First Clutch, capital, procurement, and relations integrations remain green.
- The final isolated-process Godot 4.7 suite discovers, completes, and passes all 153/153 scripts across three shards with zero failures and zero 300-second watchdog timeouts at `output/godot-full-suite-20260716-flockwatch-input-context/full-suite-summary.json`.
- Node 22 ESLint and the Vinext production build pass; all 23/23 rendered-page accessibility/status tests pass, including Flockwatch precedence, deduplication, markup stripping, bounded copy, and fallback behavior.
- Fresh release exports are byte-identical across all nine payloads in `docs/` and `web/public/game/`. The final PCK is 5,859,332 bytes with SHA-256 `E892F66E553290D8CF28B0BF50C296BDE7DFF54B706191B6D13CFB66D2A0C315`; `localhost:3000` serves the exact same bytes and hash.
- The final responsive browser audit at 2560x1600, 1440x900, 390x844, and 844x390 reports a loaded 16:9 canvas, zero horizontal overflow, and zero console/page errors at `output/web-game/flockwatch-input-context-responsive-final/audit.json`. All four full-page captures were inspected at original resolution; desktop hierarchy remains stable, portrait retains the explicit fullscreen/rotation cue, and landscape keeps the game and controls readable.
- The next two evidence-backed product slices remain intentionally open: replace per-egg synchronous full checkpoints and unconditional web autosave claims with a coalesced, observable durable-checkpoint coordinator; then rebalance probation around several genuinely viable management doctrines instead of one narrow passing hybrid.
