# Intuitive engagement completion

This pass resolves the twenty-item intuitiveness, fun, engagement, and reward
follow-up as one extension of the existing Active Playbook. It adds no currency,
permanent HUD panel, FOMO timer, or mandatory chore.

## What changed

| Finding | Resolution |
| --- | --- |
| Interactive ghost-route tutorial | The dominant action carries a short physical path from current file to world target to visible result. Day 1 retains its skippable plan → route → result spotlight. |
| One dominant objective | The Active Playbook selects exactly one currently available objective by stable priority; the ordinary intake route is the fallback. |
| Physical cause and effect | The objective and guidance projections share the existing file → hen → sorter → farmer chain and world consequence preview. |
| Prediction scoring | Every filed plan predicts its bundled contract and scores live as `CALLED IT`, `CLOSE CALL`, `BUILDING`, or `SURPRISE FILED`. |
| Distinct strategy identity | Fast, Safe, and Flock expose their strength, weakness, current mastery marks, and named build tier. |
| Combo recipes | Fast has File Flywheel, Safe has Shell Seal, and Flock has Perch Pact. Each requires two short actions in any order and applies a real pace, shell, or strain bonus. |
| Chicken mastery tracks | The existing Trusted Layer → Second Lane → Lead Hen career track remains the worker authority and feeds the strategy projection. |
| Relationship consequences | The selected hen's named perchmate, bond score, standing, and last relationship move appear as a persistent echo. |
| Better near misses | The plan score distinguishes Close Call from failure; the existing one-shot Show Me recovery stays available unless the player explicitly chooses One Bell. |
| Tactical office interactions | The bounded breakroom/office toy and rare office episode remain optional physical actions with real hen reactions. |
| Shift-specific twists | Three optional modifiers unlock after Shift 1 and must be filed before production. |
| Push-your-luck | The post-quota Bank Clutch / Chase Premium decision remains a disclosed, one-shot rule change. |
| Rivalries | Existing transparent rival margins and one-shot counterplay remain tied to the selected strategy. |
| Compressed shift payoff | The report retains its folded four-beat summary; the new prediction and recipe verdicts travel inside the completed Active Playbook receipt. |
| Transformative milestones | Contract + recipe + personal goal upgrades a plan from Learning to Taking Shape to Online to Signature Build. |
| Optional challenge modifiers | Rush Hour trades quota/shell exposure for pace; Glass Carton trades shell safety for clean value; One Bell trades Show Me for pace. All are skippable. |
| One-more-shift preview | Every playbook snapshot names the next day, scenario pressure, and next visible office reward; Shift 5 previews the permanent record. |
| Adaptive guidance that retires | The existing local first-session funnel and skippable spotlight remain the guidance authority; no new permanent tutorial layer was added. |
| Faster experimentation | Practice Peck remains consequence-free and never changes save authority, attention, or rewards. |
| Campaign climax | The final hearing now cites the player's build, strongest hen and career title, relationship standing, completed recipe, and optional challenge choice. |

## Authority and persistence

- `DepartmentSimulation` owns modifiers, combo progress, prediction results,
  strategy mastery, relationship echoes, next-shift teases, and final-hearing
  evidence.
- `Office` only renders the current objective, prediction, recipe, and feedback.
- `GameplayPulseDirector` remains a read-only projection and exposes a stable
  twenty-item diagnostics contract.
- The selected challenge modifier is strictly validated in the existing
  Active Playbook checkpoint and resets once at shift rollover.

## Evidence

- `tests/intuitive_engagement_completion_test.gd` covers all three modifiers,
  modifier persistence, Called It scoring, the Safe two-step recipe, Signature
  Build transformation, the single objective/ghost path, relationship echo,
  next-shift preview, One Bell rescue lockout, final-hearing legacy evidence,
  and all twenty presentation mappings.
- Existing Active Playbook and engagement advancement regression tests remain
  green.
- Subjective fun and unaided comprehension still require real participants;
  the shipped five-person protocol remains `AWAITING REAL PARTICIPANTS`.
