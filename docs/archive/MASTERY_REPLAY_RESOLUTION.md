# Mastery and Replay Resolution

This pass resolves the thirty remaining intuitiveness, engagement, mastery, and replay findings by surfacing systems the authoritative simulation already owns. `GameplayPulseDirector` remains read-only: it previews, prioritizes, and explains, while the Active Playbook and simulation file every choice.

| # | Finding | Resolved player-facing behavior |
|---:|---|---|
| 1 | Progressive system reveal | Foundation, Strategy, and Mastery tiers reveal only the systems relevant to the current campaign day. |
| 2 | One obvious decision | The live decision stack exposes one primary action and folds unrelated choices into the Active Playbook. |
| 3 | Gain / cost / risk language | Every surfaced plan and contextual play uses the same three-part consequence grammar. |
| 4 | Player-tested first shift | A local, privacy-preserving comprehension funnel and 60-second First Clutch protocol are ready for real-participant evidence; the game never fabricates results. |
| 5 | Automation for mastered work | Teach Auto Fit converts a demonstrated routing pattern into an authoritative automation rule with a visible fallback. |
| 6 | Visible payoff countdown | The Active Playbook now shows the next contract payoff and actions remaining. |
| 7 | Stronger action anticipation | The dominant objective retains its world ghost path and pre-action consequence preview. |
| 8 | Active intervention powers | `Q` opens the contextual Active Playbook power safely; pressing it never files a choice. |
| 9 | Chicken-readable intentions | Intent is projected through the hen’s pose, gaze, prop, reaction, and concise intent marker. |
| 10 | Mechanical personality differences | Each hen’s preferred personnel action becomes her signature ability. |
| 11 | Pair/team synergies | Trusted pairs unlock Team Lift and share a visible world result. |
| 12 | Route combo recipes | Two-step recipes expose progress, the required sequence, and their policy-specific effect. |
| 13 | Incident foreshadowing | Shift rhythm and incident staging warn through shape, motion, audio, and a single urgency pulse. |
| 14 | Interactive breakroom recovery | Breakroom props remain organic recovery destinations and recovery actions remain simulation-owned. |
| 15 | Shift finales | The last push and three-beat finale escalate toward a distinct filed-shift payoff. |
| 16 | Expressive failure | Near misses file a lesson and present a recovery advantage instead of deleting progress. |
| 17 | Authoritative victory styles | Strategy identity and campaign legacy describe how the player won, not only the score. |
| 18 | Choose-one reward drafts | Completed optional contracts offer one of three mutually exclusive rewards. |
| 19 | Strategy build synergies | Pace, Quality, and Care doctrine branches combine with contracts, recipes, and mastery marks. |
| 20 | Player-placed legacy trophies | Three fixed display sockets preserve earned plan, contract, and reward identity without unsafe free placement. |
| 21 | Chicken career milestones | Each hen exposes a short Trusted Layer → Second Lane → Lead Hen mastery journey. |
| 22 | Short unlock ladder | The UI previews only the near reward, next shift hook, and campaign finale. |
| 23 | Animated shift recap | What Worked, Close Call, and What Changed cards reuse the physical receipt language; accounting stays folded. |
| 24 | Instant same-seed remix | Shareable challenge codes and review remix actions preserve deterministic seed/day context. |
| 25 | Authored multi-shift story arcs | Career story, relationship callbacks, and rare office episodes persist across shifts. |
| 26 | Observable rival actions | Rival margin and named counterplay are disclosed; hidden scaling is explicitly prohibited. |
| 27 | Combinatorial incident conditions | The boss file combines policy, incident, and credit mechanics instead of increasing a single number. |
| 28 | Optional challenge files | Challenge modifiers are visible, skippable, and optional. |
| 29 | Personal records/mastery goals | Routing and quality personal bests sit beside strategy and hen mastery goals. |
| 30 | Decisive campaign finale | The Final Hearing consumes the player’s policy, incident, credit, and legacy evidence to produce a decisive ending. |

## Compact interaction contract

- `H` holds a four-chip explanation strip and pauses safely.
- `Q` opens the Active Playbook at the current contextual power; no action is filed until the player explicitly chooses it.
- The top HUD stores the full read-only mastery/replay projection for accessibility and automated verification, but only the next payoff and shortcut are rendered as extra copy.
- The release audit requires all 30 mappings, one major decision, a three-step unlock ladder, same-seed replay, an honest external-playtest boundary, and a decisive finale.

## Verification

- Native: `tests/mastery_replay_completion_test.gd`
- Existing integration: `tests/complete_game_loop_test.gd`, `tests/gameplay_pulse_director_test.gd`, and Active Playbook/UI suites
- Browser: `web/tests/gameplay-pulse-audit.mjs`, including the physical `Q` shortcut and popup state
- Release: `tools/verify_beta_release.ps1`
