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
