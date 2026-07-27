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
9. **Strategy differentiation:** manual/AUTO routing, specialty and accreditation, temperament-specific work styles, claimant resolution paths, directives, check-ins, facilities, contracts, procurement, credit policy, manager postures, and case pivots expose distinct short- and long-term tradeoffs.
10. **Authored ending plus optional mastery:** the five-shift probation file contains the authored campaign ending. A successful file may optionally continue into four-quarter Senior management records with annual Board Books, policy stakes, Roost Marks, cross-training, commendations, mastery-aware offers, and prior-year recovery guidance; none of that delays or replaces the ending.

## Production quality

11. **Audio:** separate music, ambience, SFX, and UI buses support independent volume/mute controls, reduced sensory motion, semantic cue pooling, focus-safe pause/resume, and adaptive office momentum.
12. **Performance:** optional office wings load lazily, static fixtures are batched, imported animation is sampled manually, hidden hens skip visual rewrites while completing routes, contacts allocate no per-hit nodes/tweens, and runtime diagnostics report node/orphan counts.
13. **Device behavior:** mouse, keyboard, controller, one-finger pan, pinch zoom, explicit zoom buttons, remapping, focus loss, portrait, landscape, 390px phone, standard desktop, and 2560x1600 layouts have automated coverage.
14. **Accessibility:** semantic actions, keyboard/controller focus restoration, reduced motion, color-vision-safe cues, remapping, bounded sanitized live narration, exact 16:9 canvas containment, and no-horizontal-overflow checks are release contracts.
15. **Playtestability:** deterministic seeds, challenge contracts, full-probation routes, multi-year matrices, runtime soaks, rendered Office fixtures, and the official browser client make regressions reproducible. Qualitative human playtests remain a release activity, not a code claim.
16. **Balance:** integer-cent accounting, exact effect previews/receipts, authored route matrices, failure controls, atomic rejection, bounded queues/capacity, and deterministic campaign playthroughs protect solvency and strategic viability.
17. **Release safeguards:** verified campaign backup/restore, strict save migrations, direct Pages preference bridging, production serving of the complete Godot payload, synchronized `docs/` and `web/public/game/` payloads, the local beta release gate, and CI Web/parity checks prevent stale, inaccessible, or mismatched deployments.

## Gate commands

Run the complete local gate from the repository root:

```powershell
./tools/verify_beta_release.ps1
```

The gate requires Node 22.13 or newer. When more than one Node installation is present, pass its folder with `-NodeDirectory`. The gate writes a machine-readable report to `output/release/beta-release-gate.json`. The full isolated Godot suite remains available through `tools/run_godot_full_suite.ps1` for release candidates.

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
