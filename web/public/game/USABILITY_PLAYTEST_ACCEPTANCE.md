# Pecking Order usability and playtest acceptance

This is the mandatory human-experience gate for a release candidate. Automated
tests can prove deterministic rules, layout bounds, accessible state, and input
contracts. They cannot prove that a player understands the economy, enjoys the
decisions, or remains comfortable through a long session.

Passing the automated beta gate is a prerequisite, not a substitute for this
protocol. Do not combine the seven focuses into one retrospective survey: each
row needs its own session, primary question, route, observation log, and signed
evidence.

## Release identity and evidence

Run every session against the same deployed candidate and record:

- the full 40-character Git commit;
- the SHA-256 of the deployed `index.pck`;
- the exact HTTPS game root;
- UTC candidate, session, and approval timestamps;
- the tester's familiarity with management/economy games and *Pecking Order*;
- task-level outcome, elapsed time, help requests, wrong turns, and recovery;
- the focus-specific rating and written rationale;
- all observed issues, including accepted non-blocking issues; and
- one immutable evidence ZIP per session with its SHA-256.

Initialize the record only after the candidate is committed and deployed:

```powershell
./tools/new_usability_playtest_evidence.ps1 `
  -TestedUrl "https://REPLACE_WITH_DEPLOYED_RELEASE_URL/" `
  -Coordinator "Research coordinator"
```

Complete every placeholder in
`output/release/usability-playtest-evidence.json`, then run:

```powershell
./tools/verify_usability_playtest_evidence.ps1
```

The validator requires the recorded commit to equal the checked-out commit and
the deployed payload to match both shipped `index.pck` copies.

Generate the session-specific route, task log, and moderator worksheet before
each participant:

```powershell
./tools/new_usability_playtest_session_kit.ps1 `
  -SessionId "comprehension"
```

After the first-attempt recording and result are complete, put the recording,
completed `session-result.json`, and moderator notes in one ZIP, then register
them together:

```powershell
./tools/register_usability_playtest_session.ps1 `
  -SessionId "comprehension" `
  -ResultPath "output/release/playtest-session-kits/comprehension/session-result.json" `
  -BundlePath "output/release/evidence/comprehension-session-bundle.zip"
```

Registration content-inspects the ZIP, computes its digest, prevents
cross-session reuse or accidental replacement, and atomically updates both the
result and evidence reference. Do not paste bundle paths or hashes by hand.

## Moderation rules

1. Recruit a tester who did not implement the route being evaluated. Record
   whether they are new, returning, or expert.
2. Use a clean browser profile and cleared site data unless the route explicitly
   requests the provided mature-office save.
3. Read only the neutral scenario prompt. Do not explain the interface, economy,
   satire, or expected solution.
4. Ask the tester to think aloud. A moderator may ask "What are you looking
   for?" but may not name a control or recommend a choice.
5. Count every directional hint as external instruction. A session with a
   release-critical task completed only after a hint is not an unaided pass.
6. Keep the first attempt. Retests after a fix belong to a new candidate or a
   new signed session.
7. Record observations before discussing them with the tester. Capture the
   post-session rating and rationale in the tester's own words.

Record every attempted task with this exact shape:

```json
{
  "id": "stable-kebab-case-task-id",
  "outcome": "pass",
  "critical": true,
  "completed_unaided": true,
  "elapsed_seconds": 74,
  "external_instruction_count": 0
}
```

Allowed outcomes are `pass`, `fail`, and `blocked`. Rates use the inclusive
`0.0` to `1.0` range. The validator recomputes attempted, unaided-completion,
critical-attempt, and unaided-critical totals from `task_results`; editing only
the summary metrics cannot convert a failed route into a pass.

## Required focus matrix

| Session ID | Minimum time | Minimum tasks | Primary release question |
| --- | ---: | ---: | --- |
| `comprehension` | 20 min | 5 | Can a new player explain the objective, resources, change causes, and recovery path? |
| `friction` | 20 min | 8 | Can common actions be completed quickly without unnecessary clicks, traps, or accidental commands? |
| `pacing` | 30 min | 5 | Does the first two-shift rhythm alternate planning, action, consequence, payoff, and recovery? |
| `fun` | 30 min | 5 | Are choices, outcomes, satire, and progression enjoyable enough to continue voluntarily? |
| `strategic-depth` | 45 min | 6 | Can the player form, compare, and adapt at least two viable economic plans? |
| `feedback-clarity` | 20 min | 7 | Can the player tell what changed, why, and what to do next from the receipts and world response? |
| `long-session-fatigue` | 90 min | 5 | Does sustained play avoid repetitive strain, unreadable clutter, audio/motion fatigue, and decision exhaustion? |

Every session also samples four common capabilities:

- find the current objective or most important economic warning;
- explain one Feed Fund, cost, capacity, welfare, or market change;
- complete a relevant economic action without external instruction; and
- recover from a safe mistake using cancel, back, route Undo, a disclosed
  recovery option, or save restore.

## Focus routes

### Comprehension

Use a player unfamiliar with *Pecking Order*. Ask them to start a new campaign,
complete First Clutch, find the current objective, explain why Feed Fund changed,
identify the leading bottleneck, compare two disclosed options, and recover from
one deliberately invited reversible route mistake. If the player makes two
consecutive off-specialty route changes, observe whether they notice and use the
temporary recovery action without moderator prompting. Do not define the insurance
or farm-corporate vocabulary for them.

Pass when at least 80% of tasks and every critical task are completed unaided,
the player correctly finds at least 80% of requested information, correctly
explains at least 80% of sampled changes, recovers from the mistake, requests no
directional hint, and rates comprehension at least 5/7.

### Friction

Sample starting/resuming, inspecting and routing a hen, changing speed, using
Priority Peck, opening and closing Flockwatch, filing or canceling a claimant
path, using route Undo, changing a preference, and exporting a backup. Count
clicks/activations, wrong turns, accidental duplicate commands, and recovery.

Pass when at least 85% of tasks and every critical task are completed unaided,
there are no accidental duplicate economic commands, no workflow trap, no
directional hint, mistake recovery succeeds, and friction is rated at least 5/7.

### Pacing

Play from a clean campaign through First Clutch and two complete shifts. Mark the
first meaningful decision, first visible consequence, first payoff, first
recovery interval, every decisionless wait longer than 30 seconds, and any point
where several major tutorials or commitments arrive together.

Pass when all five rhythm beats occur, two shifts complete, there is no
unskippable decisionless wait longer than 30 seconds, no overload cluster that
prevents an informed choice, and pacing is rated at least 5/7.

### Fun

Sample an incident response, a worker-care or labor choice, a contract or
directive, a reinvestment/expansion, and a farmer-credit outcome. Ask what the
tester anticipated, enjoyed, disliked, and would choose differently. Do not use
retention tricks or rewards outside the game.

Pass when at least 80% of tasks complete unaided, the tester identifies at least
three enjoyable moments and one meaningful personal choice, voluntarily says
they would continue, and rates fun at least 5/7.

### Strategic depth

Use a provided deterministic campaign seed. Ask the tester to state one plan,
forecast a market or bottleneck, choose between short-term yield and resilience,
adapt after a setback, then try or compare a materially different plan. Record
the levers used and the evidence behind each adaptation.

Pass when the player attempts at least two distinct strategies, makes at least
eight reasoned economic choices, adapts at least twice from visible evidence,
finds no universally dominant choice in the sampled state, and rates strategic
depth at least 5/7.

### Feedback clarity

Sample money earned, money spent, a rejected action, a warning, a save receipt,
a milestone, and a delayed consequence. After each, ask the tester what changed,
why it changed, and what action remains. Test with normal effects, then Essential
Only effects for at least two samples.

Pass when at least 80% of sampled changes are correctly explained, all seven
semantic outcomes remain identifiable without relying on color alone, the
Essential Only samples remain complete, no receipt obscures the next decision,
and feedback clarity is rated at least 5/7.

### Long-session fatigue

Play continuously for at least 90 minutes, including three shifts, one Farmer
Review, repeated routing/collection, two planning surfaces, a preference change,
and a return from a five-minute break. Record repetitive chores, discomfort,
audio or motion fatigue, clutter accumulation, decision exhaustion, and whether
the return recap restored context.

Pass when the tester completes the route, reports fatigue no higher than 3/7,
identifies no more than three low-value repetitive chores, encounters no
accessibility or comfort blocker, can resume from the recap without a hint, and
rates willingness to continue at least 5/7.

## Evidence bundle

Each ZIP must include:

- a continuous `.webm`, `.mp4`, `.mkv`, `.mov`, `.wav`, or `.m4a` recording;
- a machine-readable `.json` or `.csv` task/observation log;
- a `.md` or `.txt` moderator note containing issue references and tester
  rationale; and
- no absolute, drive-qualified, empty, or `..` archive paths.

Repository-relative bundle URIs must stay inside this repository, exist, be
unique across sessions, and match their recorded SHA-256. HTTPS evidence must be
an immutable, query-free ZIP object whose filename contains the session ID, not
a shared-folder landing page.

## Release decision

Usability/playtest acceptance passes only when:

- all seven focus sessions are independently run and signed `pass`;
- every focus threshold and common capability is satisfied;
- every evidence bundle is non-placeholder, unique, content-complete, and
  hash-verified;
- there are no open P0 or P1 issues;
- accepted P2 issues are listed in the final decision; and
- the research/release owner signs a `pass` decision after all sessions.

`fail`, `blocked`, `pending`, or a session completed against a different commit
or PCK is not a release pass. Changing the candidate invalidates the decision.
