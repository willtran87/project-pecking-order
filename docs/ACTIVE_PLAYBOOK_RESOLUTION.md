# Active Playbook Resolution

This pass turns the previously read-only reward-loop findings into one bounded, authoritative shift layer. The player opens a single compact `PLAN / PLAY / REWARD` control; the office remains visible, while each menu action states its exact gain, cost, and risk before filing.

## High-impact gameplay items

| # | Finding | Resolution | Authority / evidence |
|---|---|---|---|
| 1 | Give each hen a signature action | The selected hen can execute her real preferred check-in from the Playbook. It uses the existing personnel allowance and effects. | `perform_playbook_action(signature)` delegates to `perform_personnel_action`; `active_playbook_test.gd` |
| 2 | Add optional shift contracts | Pick Clean Pair, Fit Three, or Peck Pair. Missing one has no penalty. | Contract choice and progress are saved simulation state. |
| 3 | Make policies create distinct combos | A three-link fit chain activates Harvest Hustle (+5% pace), Shell Lock (-2% shell risk), or Perch Partners (-10% strain). | Production, error-risk, and strain calculations consume the modifier. |
| 4 | Let players prepare for incidents | Before the first incident, choose Brace Shells, Clear Trays, or Rest Flock. | Effects are causal and expire after the first incident resolves. |
| 5 | Add explicit rival counterplay | After the first egg, choose Defend Lead, Counter Push, or Back the Flock. | Causal pace, shell-risk, or solidarity effect; no hidden catch-up rule. |
| 6 | Turn office strategy into a loadout | Before the first egg, choose Pace, Quality, or Care Floor. | Saved shift choice changes real work, error, or strain calculations. |
| 7 | Let the player author a side goal | Pin one of five visible personal ambitions. | Progress derives from clean clutches, lane throughput, gold, Team Lift, or fund growth; failure removes nothing. |
| 8 | Make relationships actionable | A 60+ named bond unlocks one manual Team Lift. | Both hens gain morale/trust, lose stress, and restore one attention charge. |
| 9 | Make contract rewards a choice | A completed contract pays exactly one of Feed Fund, hen XP, or flock recovery. | Atomic choose-one guard with exact receipt and persistence. |
| 10 | Add comeback plans | Low cash, farmer favor, or flock condition opens Steady Fund, Repair Flock, or Salvage Order. | Each route states and applies a different tradeoff while protecting banked rewards. |
| 11 | Provide consequence-free practice | Practice Peck reads the focused hen's live timing position. | The test compares the complete checkpoint before and after: no authority changes. |
| 12 | Clarify the campaign climax | The final campaign day is identified as a boss file with policy, incident, and credit mechanics. | Derived from the existing scenario/final-hearing authority. |
| 13 | Differentiate opportunities without color | Golden, urgent, teamwork, and contract opportunities expose star, diamond, linked, and stamp shapes. | Published in the Playbook diagnostic and browser accessibility contract. |
| 14 | Keep one visible plan | The control tooltip always shows a three-beat policy → combo → contract plan. | The plan remains in the HUD without opening a full-screen surface. |
| 15 | Explain outcomes at decision time | Every menu item carries `gain`, `cost`, and `risk`; the latest filed result becomes a concise semantic receipt. | Native UI test plus browser audit. |

## Intuitiveness refinements

| # | Finding | Resolution |
|---|---|---|
| 1 | One obvious next interaction | The control changes from `PLAN` to `PLAY`, `SIGNATURE`, or `REWARD` based on the first available action. |
| 2 | Progressive disclosure | The permanent HUD shows one button; choices and exact terms appear only in its menu/tooltips. |
| 3 | Preserve the office as the game board | No new modal, dossier, or screen is introduced. Opening and closing the menu does not change camera or hen focus. |
| 4 | Use icons before prose | Existing flock, shield, route, care, cash, sync, rival, and golden symbols lead every option. |
| 5 | Keep terminology consistent | Policy, contract, combo, loadout, side goal, Team Lift, reward, and recovery use the same labels in simulation, HUD, diagnostics, and review. |
| 6 | Show cause and effect | Playbook modifiers are included in the public `decision_modifiers`, and every accepted action files a receipt. |
| 7 | Protect banked progress | Optional contracts and side goals have zero failure penalty; recovery explicitly preserves earned rewards. |
| 8 | Support keyboard and assistive use | The menu is focusable, items expose full accessible tooltips, and shape metadata does not rely on color. |
| 9 | Keep feedback compact | Filed actions use one icon-led receipt and the existing ticker instead of another explanatory panel. |
| 10 | Make the loop reviewable | The completed-shift report captures the exact Playbook state before daily reset. |

## Verification contract

- `tests/active_playbook_test.gd`: authority, modifiers, atomic practice, choose-one reward, teamwork, persistence, and day rollover.
- `tests/gameplay_pulse_director_test.gd`: read-only projections switch to exact Playbook authority when supplied.
- `tests/management_loop_ui_test.gd`: compact hidden-before-shift control, menu metadata, accessibility, and live authoritative status.
- `tests/simulation_persistence_test.gd`: checkpoint parity includes the Active Playbook.
- `web/tests/gameplay-pulse-audit.mjs`: live WebGL state publishes the three-step plan and gain/cost/risk for every option.
