# Visual, design and gameplay refinement — 2026-09-13

This is the implementation/evidence ledger for the thirty-area review. It distinguishes changes made now from existing systems retained and from acceptance work that still needs players. It is not a claim that thirty new systems were added, or that automated checks prove fun.

## Implemented in this pass

| Review areas | Changes |
| --- | --- |
| 1. Camera composition | Steeper, shared overview/inspection angle exposes desk surfaces; closer hen framing; a safe area reserves space for the HUD and dossier. Furniture and simulation coordinates do not move. |
| 2. Status hierarchy | Activity markers are approximately 21–25% smaller, raised clear of the head, with a smaller selection halo. Urgent shapes retain stronger size/opacity than background activity. |
| 3–4. Art coherence and contrast | Cubicle back/wing planes share a matte, muted textile material. Authored geometry, mounting points, and navigation remain unchanged. This is a material pass, not a replacement of the imported furniture models. |
| 7. Organic interaction | Hens must finish turning toward their breakroom fixture before collection, drinking, browsing or lounging starts. Existing approach/reach/sip/lower/return sequences remain authoritative to their routes. |
| 8. Readable work states | Actual fatigue creates a seated slouch; actual stress creates a restrained head tilt. Reduced-motion mode retains a static need cue. Contact timing and the connected character rig are preserved. |
| 11. Compact-screen controls | Care actions reflow into two columns. Canvas CSS dimensions are sampled at 2 Hz because browser scaling does not necessarily change Godot's design resolution. The dossier compensates fonts and targets, including enlarged-text preferences. |
| 12–13. HUD and dossier | The redundant policy/harvest badge is inspect-only. Compact selected-hen cards have capped widths, quieter borders and larger buttons. Expanded cards use a stable full-width layout with a reserved contract slot to avoid shifting as evidence changes. |
| 14–16. Language and emphasis | Review recommendations consistently use Faster eggs, Safer shells and Happier hens. The main cue says “Choose a shift plan.” Existing semantic icons retain labels; the dossier frame no longer competes with the highlighted action. |
| 18. Review accounting | Concrete output/net/bottleneck captions; the bottleneck label changes between shell quality, late files and rework. Net explanation lists actual credit, operating cost and contract penalty amounts, separately from discretionary purchases/care. A hen needing care is recognized as such rather than presented only as an egg count. |
| 22. Visible strategy habits | Fast desks fan their incoming papers; safe desks align an inspection stack and lift the current inspection sheet. Static arrangements remain distinct with reduced motion. These visuals do not award output or bypass work. |
| 24. Personal care | Accepted check-ins trigger short hen reactions based on prior strain, preference and action. Pressure gets an appropriately reluctant response rather than a success celebration. Failed actions trigger no positive reaction. |
| 25. Breathing room | Resolved incidents now use the same payoff quiet period as routes, care, purchases and plan choices. Optional prompts/ambient chatter yield; urgent rescue/decision handling remains available. |
| 26, 29. Recovery and next-shift motivation | Cracked/late-file recap details give concrete recovery advice. Plan recommendations explain tradeoffs using the same names as the purchase-free choices. Accepted personal goals and named-hen attribution remain intact while browsing alternatives. |
| 30. Audio hierarchy | Important confirmations temporarily reduce lower-priority physical voices by 8 dB for a 450 ms result window. Work remains audible, alerts are not discarded, the eight-player pool is reused, and saved volume settings are untouched. |

## Existing foundations retained, not replaced with duplicate systems

| Review areas | Existing implementation and verification focus |
| --- | --- |
| 5–6. Room identity and personal desks | The baseline breakroom already contains a bound rug, kitchen, mugs, seating, reading material and wall fixtures. Desks retain deterministic photos, stationery, plants/snacks and nameplates. Verify physical staging and clear routes rather than fill circulation space with more props. |
| 9, 27. Visible, distinct investments | Tools, shell lamp and nest cushion retain attached upgrade models, physical install receipts and separate output/reliability/comfort effects. Existing automation/staffing purchases remain distinct. Reinvestment and economy regressions protect price/effect authority. |
| 10. Identity and office persistence | Roster uniqueness, paused routes, fixed desk coordinates and stable presentation roots remain covered by lifecycle, staging and persistence checks. No worker spawn or furniture-layout authority was added. |
| 17. Action previews | Existing plan, equipment and care previews continue to expose real prices, remaining funds, disabled reasons and effect tradeoffs. This pass changes layout/presentation, not costs or authorization. |
| 19. Accessibility | Retain keyboard focus restoration, semantic names, shape-based state cues, independent audio settings and reduced motion. Add physical care-target assertions and large-text regression coverage. Whole-game assistive-technology acceptance still needs users. |
| 20, 23. Core loop and routing mastery | Keep route-first guidance, specialty matching, old-file pressure, Priority Peck, undo and physical delivery. Existing native/browser checks protect actual actions and rewards; no click-spam bonus or extra resource was introduced. |
| 28. Scenarios and finale | Keep scenario rules, physical storytelling, seeded incidents, persistent relationships and the final hearing. Existing scenario/campaign regressions remain in the release gate. |

## Acceptance boundaries and remaining work

- **21 — watch/act rhythm and enjoyment:** automated progression is not a substitute for observing unfamiliar players. Run the five-person protocol in `FIRST_SHIFT_PLAYTEST_CARD.md`; measure first independent action, confused pauses, perceived downtime, and desire to play another shift. Balance changes should follow those observations.
- **3 — deeper art pass:** this delivery improves material coherence and composition, but does not remodel every angular furnishing. A full geometry/art-direction replacement remains separate work; do not describe the material change as that replacement.
- **19 — accessibility acceptance:** verify the complete campaign with actual keyboard-only/assistive-technology users, muted audio, enlarged text and reduced motion. Automated layout and settings checks establish contracts, not complete usability.
- **11 — global compact HUD:** the dossier/care controls now compensate for CSS scaling. The rest of the dense desktop HUD has not been comprehensively converted to a compact layout; it remains a follow-up rather than being called resolved by the care audit.
- **22/27/28 — strategic feel:** distinct rules, effects and presentation exist. Whether strategies, purchases and scenarios feel sufficiently different over repeated shifts still requires player evidence. No new balance claims are made here.

## Evidence

- New native regression: `tests/visual_design_refinement_test.gd` checks two-column care, enlarged text/targets, consistent plan names, factual accounting, fixture-facing gates and bounded audio mixing.
- Updated `tests/first_clutch_coach_ui_test.gd` preserves disclosure/focus behavior with the care grid.
- Updated `tests/complete_game_loop_test.gd` checks concrete report captions instead of the superseded generic labels.
- Browser care audit now asserts **physical CSS-pixel** target sizes, not just internal canvas rectangles. It exercises Later, reopen, a real paid check-in and return using actual controls.
- Targeted lifecycle, physical staging, presentation and office-layout checks passed after the interaction changes. Targeted camera, reinvestment, audio and core-loop checks also passed during implementation.
- Final release gate passed **80/80 checks** in 908.84 seconds. High-resolution care/review browser audits passed, as did the prescribed 1280x720 client and 900x800 care audit. Inspected original-size captures; compact care targets measured 44 CSS pixels tall. Review narration correctly identifies cracked shells instead of treating them as Feed Fund money. These checks do not replace human playtesting.
- An additional legacy `management_loop_ui_test.gd` run exposed seven failures that also reproduce on the untouched `def059f` baseline (old plan-control/badge expectations and review-height assertions). Two additional expectations introduced by making the policy badge inspect-only were updated to the new contract. The legacy suite is not being represented as green or silently weakened to conceal baseline failures.

## Follow-up implementation — 2026-09-22

The later twenty-area review focused on compact readability, feedback and the day-to-day loop. This follow-up completes the actionable layout/feedback gaps in that review and verifies the existing foundations rather than layering another currency or subsystem over them.

- **Compact HUD and chrome (areas 1, 10–13):** Measure the rendered canvas in CSS pixels, not only Godot's fixed 1280×720 design space. At narrow physical sizes, use a two-row goal/clock HUD, a single pace menu, larger primary controls and text, and suppress secondary status strips. Move routing, Flockwatch and the campaign badge below the actual compact HUD; hide redundant wrapper controls except on coarse-pointer devices. The shift report now widens independently, enlarges all report labels and buttons, and preserves 44 CSS-pixel primary targets at the audited 900×800 viewport. Desktop layout is restored when the canvas grows.
- **Hen visibility (area 2):** Inspection now cuts away only the selected hen's front cubicle partitions. The partitions return when inspection ends; furniture, desk assignment, navigation and simulation state stay fixed. A transparent-material-only attempt was rejected after the browser capture showed the imported wall still obscured the hen.
- **Work, strategy and consequence (areas 3–5, 14–20):** The prior pass's plan-specific desk motions, direct routes, named-hen reactions, recovery advice, personal-goal controls and distinct upgrade/room models remain the playable mechanics. This follow-up makes the review's credit-minus-costs net explicit, labels the next egg quota, and restores a saved routing-record cue ahead of an unchosen plan prompt. The cue still focuses an intake tray without filing a route; the player makes the assignment. There is no invented payout for a personal goal.
- **Room and character identity (areas 6–9):** Preserve the already-authored breakroom fixtures, desk props, deterministic furniture placement, physical investment installs and chicken need postures. The camera/cubicle pass above improves their readability without adding decorative obstacles to routes. A full replacement of all imported furniture geometry was not performed here.

The compact care and report browser audits pass using real buttons. The report audit uses an **authored preview fixture**, not a completed human shift. Native core-loop, opening progression, camera/navigation, physical staging, visual refinement and routing-recap checks pass; the first-clutch and lifecycle mechanics were not replaced. Five unfamiliar-player sessions and assistive-technology acceptance remain pending as specified in `FIRST_SHIFT_PLAYTEST_CARD.md`. Do not infer that automated checks prove fun, addiction, or comprehension.

No commit, push, or Pages publication is implied by this local implementation request.

## Twenty-one-area product follow-up — 2026-09-22

This ledger maps the latest visual/design/gameplay list to concrete work or an existing authoritative system. A check here means the implementation and stated automated evidence exist, not that unfamiliar players have endorsed the feel of the game.

| Area | Product disposition |
| --- | --- |
| 1. Distinct rooms | The baseline breakroom now has a warmer, bound rug and an overview-visible BREAK ROOM header integrated with its corkboard; the cooler, kitchen, sofa, mugs, reading table and organic destinations remain. Other departments retain their own authored furnishings. |
| 2. Unobstructed focus | The selected cubicle's back, wing and top trim cut away. The overhead egg row and the selected desk's lift tube also leave the isometric sightline during inspection, then return in overview. Neighboring desks are not dismantled. |
| 3. State through motion | Existing fatigue/strain postures, work cycles, break approaches, turning and contact gestures remain. Reduced motion retains a static need cue. |
| 4. Visible production | Existing actual claim delivery, desk work, egg lift, grading, basket and credit beats remain; the first route-to-physical-reward browser audit was replayed at high resolution. |
| 5. Transformative purchases | Existing physical workstation installations, investment reveals and first-use effects remain tied to authoritative upgrades. No duplicate upgrade economy was added. |
| 6. Coherent art | The prior matte cubicle-material pass and this warmer breakroom accent improve consistency. A full replacement of imported furnishing geometry is **not** claimed. |
| 7. One primary action | First-shift route guidance and compact goal HUD already spotlight one action. The playbook menu now opens at the scene edge instead of covering the hen, and the compact dossier's `PICK ROUTE` cue fits without truncation. |
| 8. Less default text | Existing compact four-field hen card and details-on-demand tabs remain; expanded care and claimant text appears only when relevant. |
| 9. Protect focal scene | Selected-hen line-of-sight cutaway and left-edge playbook popup are the new direct fixes, visually checked at 2560×1600. |
| 10. Shared previews | Existing plan, equipment and care options continue to state benefits, cost and risk from their actual definitions; the three plan modifiers were compared in regression. |
| 11. Surprising results | When net is negative and itemized report costs exist, the review names the largest recorded cost and one next action below the actual credit-minus-cost equation. It invents no category when only a total is available. |
| 12. Small screens | The prior physical-canvas-aware HUD/report reflow remains. Portrait touch devices now get an explicit, dismissible landscape recommendation with a 44 CSS-pixel action. This is honest guidance, **not** a claimed native portrait redesign. |
| 13. Accessible play | Existing focus, semantic labels, large text, muted-audio and reduced-motion options remain; the new portrait action and compact care/report controls have physical target checks. Complete assistive-technology acceptance requires users. |
| 14. First cause and effect | The route-and-start browser run followed real work through egg presentation to a reinvestment choice. No reward was injected into the simulation to make the audit pass. |
| 15. Distinct shift plans | Fast, safe and flock plans already have separate pace, shell, strain and cash consequences plus desk rhythms/ambient accents; the new comparison regression protects those differences. |
| 16. Watch/act cadence | Existing pulse director, optional-feedback quiet periods, rescue precedence and shift phases remain. Enjoyment and waiting tolerance still need unfamiliar-player evidence. |
| 17. Recoverable setbacks | Existing late-file, shell-quality, care and cash recovery choices remain. Report wording points to a next move rather than treating a loss as unexplained failure. |
| 18. Hen arcs | Existing preferred actions, trust/grievance, bonds, career and named-hen review callbacks remain checkpointed. |
| 19. Five-shift shape | The authored probation milestones, changing quotas, personal goals and final hearing remain; campaign playthrough regressions protect the trajectory. |
| 20. Replay priorities | Existing scenario rules and replay pressures remain distinct from the opening book; scenario/replay regressions protect their rules. |
| 21. Reward balance | Native economy and campaign-balance checks protect deterministic payouts and progression. Whether every choice feels rewarding or any strategy dominates in human play remains an empirical question. |

The five unfamiliar-player sessions and assistive-technology acceptance in `FIRST_SHIFT_PLAYTEST_CARD.md` are still required before making comprehension, accessibility or enjoyment claims. The implementation request did not authorize a commit, push or Pages publication.

## Twenty-area follow-up — 2026-09-23

The latest twenty-area request led to a focused play-surface and accessibility pass. It builds on the authoritative systems mapped above; it does not add a second route, economy, roster, or reward system.

| Areas | Concrete result |
| --- | --- |
| 1, 2, 7, 8 — scene space and the next action | Focused desktop play can expand to 2560 CSS pixels. The selected hen's monitor screen and its visual trim now join the cubicle cutaway, restoring in overview; a browser capture exposed that hiding the imported monitor mesh alone left its separate screen obstructing Mabel. The first-route dossier is capped at 980 design pixels on desktop, shortens its coached height, and omits a duplicate route headline while retaining all route choices. |
| 3–6 — art, rooms, production and purchases | Preserve the existing matte cubicle finish, breakroom identity, deterministic desk dressing, physical file/egg journey, and installed upgrade props. These are already coupled to actual simulation state; this pass changes the sightline, not the furniture or production authority. The imported furniture has not been fully remodeled. |
| 9, 10 — previews and explanations | Existing actual-cost/effect previews and itemized review explanations remain. The enlarged stage and smaller coached dossier give the hen and these decisions more room without deleting their detail. |
| 11, 12 — small screens and keyboard | Portrait guidance now offers both a full-screen/landscape attempt and an honest continue-at-small-size choice, each at least 44 CSS pixels tall. It is still a landscape-first game, not a native portrait redesign. Tab retains in-game hen cycling, while Shift+Tab explicitly focuses the page controls so browser/assistive users can leave the canvas. |
| 13–19 — opening, rhythm, strategy, setbacks, hen arcs and shifts | The physical first route-to-egg/reward browser audit, first-clutch and core-loop native contracts, and the existing plan, care, recovery, campaign and economy regressions protect the current mechanisms. No artificial early payout or claim of a newly balanced five-shift campaign is made. |
| 20 — comprehension and enjoyment | The first-shift observation card remains the acceptance protocol. Automated checks can verify target sizes and progression, but cannot establish intuitive play, enjoyment or a non-dominant strategy for unfamiliar people. |

The 2560×1600 route-to-physical-reward audit passed after the final cutaway and dossier adjustment. A 900×800 real-control care audit, 390×844 portrait guidance audit, and 2560×1600 Tab/Shift+Tab focus audit also passed. The prescribed web-game client loaded and rendered the opening. Full release-gate results and process cleanup are recorded in `progress.md`. Five unfamiliar-player sessions and assistive-technology acceptance remain necessary; those findings may prompt further changes.
