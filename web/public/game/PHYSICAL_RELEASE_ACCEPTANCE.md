# Pecking Order physical release acceptance

This is the mandatory human-hardware gate for a release candidate. It covers
the parts of the experience that repository automation cannot honestly prove:
physical iOS and Android touch behavior, screen-reader and listening quality on
real hardware, and representative integrated- and discrete-GPU throughput.

Passing the automated beta gate is a prerequisite, not a substitute for this
protocol.

## Release identity and evidence

Run every session against the same deployed release candidate. Record:

- the full 40-character Git commit;
- the SHA-256 of the deployed `index.pck`;
- the exact HTTPS game root and derived `index.pck` URL;
- UTC test and approval timestamps;
- device, OS, browser, assistive-technology, audio-device, GPU, and driver
  versions as applicable;
- one immutable evidence bundle per session, with its SHA-256; and
- every observed issue, including non-blocking issues accepted for beta.

After the candidate is committed and deployed, initialize its exact identity:

```powershell
./tools/new_physical_release_evidence.ps1 `
  -TestedUrl "https://REPLACE_WITH_DEPLOYED_RELEASE_URL/" `
  -Coordinator "Release owner"
```

The initializer requires a clean tracked worktree, matching shipped PCK files,
an HTTPS deployment root ending in `/`, and the schema-v2 template. It downloads
that root's `index.pck` with cache bypass, requires its bytes to match both local
release copies, and writes
`output/release/physical-release-evidence.json` with the current full commit,
payload hash, game/PCK URLs, UTC start time, and coordinator. Complete every
placeholder, then validate it with:

```powershell
./tools/verify_physical_release_evidence.ps1
```

The validator requires the recorded commit to equal the checked-out commit and
the recorded payload hash to equal both shipped copies:
`docs/index.pck` and `web/public/game/index.pck`.

Use only these result values:

- `pass`: the session met every threshold;
- `fail`: a threshold was missed or a release defect was found; or
- `blocked`: the session could not produce trustworthy evidence.

`blocked` is not a release pass.

## Required matrix

| Session ID | Required physical environment | Primary purpose |
| --- | --- | --- |
| `touch-ios` | Recent supported iPhone, current Safari | Physical touch, safe areas, rotation, and mobile flow |
| `touch-android` | Representative mid-range Android phone, current Chrome | Physical touch, browser chrome, rotation, and mobile flow |
| `screen-reader-desktop` | Windows with NVDA or macOS with VoiceOver | Page, focus, live status, decisions, and economic equivalence |
| `screen-reader-mobile` | iOS VoiceOver or Android TalkBack | Mobile controls, status, focus recovery, and economic equivalence |
| `audio-listening` | Real speakers or headphones in a quiet environment | Mix clarity, semantic cues, independent buses, and focus behavior |
| `gpu-integrated` | Hardware-accelerated integrated-GPU laptop or desktop | Default-quality minimum throughput and stability |
| `gpu-discrete` | Hardware-accelerated discrete-GPU desktop or laptop | Default-quality 60 Hz-class throughput and stability |

A virtual display, remote-rendered session, cloud browser, SwiftShader, Microsoft
Basic Render Driver, or other software renderer does not satisfy a physical GPU
row. An iOS or Android emulator does not satisfy a touch row.

## Common setup

1. Run `./tools/verify_beta_release.ps1` for the exact candidate.
2. Confirm the deployed payload hash matches the local `index.pck` hash.
3. Use a normal browser profile with hardware acceleration enabled. Disable
   browser extensions that inject UI or alter input.
4. Start from cleared site data for the new-campaign checks. Use an exported
   campaign only where the route explicitly calls for a mature office.
5. Record the complete session. Keep the browser address bar and device identity
   visible at the start, then capture the game and any measurement tools.
6. Record failures as they happen. Do not repeat a failed attempt until it
   disappears from the evidence.

## Physical touch protocol

Run this complete route on both `touch-ios` and `touch-android`.

### Route

1. Load the public URL from cleared site data and start **New Campaign**.
2. Complete the First Clutch inspect, route, check-in, Priority Peck, delivery,
   collection, reinvestment, and handoff sequence using touch.
3. Exercise each of the eight visible touch controls: Pause, Next hen, Priority,
   Zoom +, Zoom -, Flockwatch, Overview, and Settings.
4. Make 20 deliberate control taps distributed across all eight controls.
   Every tap must produce exactly one matching action. A missed action, double
   action, or adjacent-control activation is a failure.
5. Perform 10 one-finger pans across open office space. No pan may activate a
   control, move through a modal, or leave the camera stuck.
6. Perform 10 pinch-zoom cycles across the useful zoom range. No cycle may scroll
   the page, activate a control, or strand the office outside recoverable bounds.
7. Rotate portrait to landscape and back five times, including once with
   Flockwatch open and once with Settings open.
8. Open and close Flockwatch and Settings five times. Selection, focus, camera,
   pause state, and current shift must survive.
9. Export a campaign backup, advance one authoritative action, import the
   backup, and confirm the earlier state and accessible save receipt return.
10. Play continuously through one complete shift. Confirm chickens remain
    routable, occupied desks alone produce eggs, status feedback remains visible,
    and no fixed UI covers a required action.

### Pass criteria

- Touch controls are at least 44 by 44 CSS pixels, do not overlap, and are fully
  reachable inside the safe area.
- The page has no horizontal scroll and no clipped required control in either
  orientation.
- All 20 control taps single-fire with zero failures.
- All 10 pans, 10 pinch cycles, and five rotation cycles complete with zero
  failures.
- Orientation recovery takes no more than two seconds and does not reload or
  reset the campaign.
- The complete First Clutch and one-shift routes require no keyboard or mouse.
- Text remains legible at the browser's default zoom and at the game's 1.5x UI
  scale.
- Backup export/import is explicit, reversible, and does not silently replace a
  newer career.

## Screen-reader protocol

Run the desktop and mobile rows with speech enabled and the screen off or eyes
averted for the critical-decision checks. The 3D office is supplemental visual
presentation; the release contract is that every critical economic fact and
action is available through the page controls, game focus contract, live status,
Flockwatch summaries, and authored narration.

### Route

1. Navigate the page from the browser chrome. Confirm the page title, main
   heading, playable-game region, Career save status, Management Handbook, and
   Focus game control are named in a useful order.
2. Focus the game and listen to its control summary. Confirm focus can return to
   the page without getting trapped.
3. Start or resume a campaign and collect at least 10 live-status announcements
   across an action, a milestone, a routine update, a purchase, a denial, a
   warning, a save, a decision, a shift transition, and a farmer review.
4. Change Transient Notices through All Notices, Priority Only, and Shift Record
   Only. Confirm urgent actions remain available and suppressed notices remain
   discoverable in the Shift Record.
5. Complete at least three economic decisions from narration alone. The reader
   must announce choice, exact cost, availability, immediate effect, delayed
   tradeoff, and the accepted or rejected receipt.
6. Open Flockwatch and verify that cash, reserved funds, profitability, active
   objective, worker/manager state, and the next required action are
   understandable without inspecting the 3D office.
7. Export and import a campaign backup and verify that the save status and
   restored-state result are announced.

### Pass criteria

- No critical control is unnamed, duplicated without context, or unreachable.
- Focus order is stable; focus returns to the invoker after Settings, Flockwatch,
  and decision surfaces close.
- Live announcements are polite, bounded, and causal. No raw JSON, internal node
  name, diagnostic key, or repeated runaway announcement is spoken.
- Priority/action, milestone, and routine meanings are distinguishable in words,
  not color or sound alone.
- The three sampled decisions can be completed without sight and without guessing
  undisclosed costs or consequences.
- All critical economic information sampled in the visual UI has an equivalent
  spoken summary.

## Listening protocol

Use real speakers or headphones in a quiet environment for at least 15 minutes.
Test Master, SFX, UI, Music, and Ambient independently.

### Route and pass criteria

- Change and mute each bus independently. Only the intended bus changes, its
  setting persists after reload, and Master affects the complete mix.
- Trigger and identify, without looking, a profit/collection cue, warning,
  completed production cue, major purchase cue, and failure/denial cue.
- Confirm each audio-only distinction has redundant visual or narrated feedback.
- Move focus away from the browser and back five times. The configured
  pause/resume behavior is immediate, stable, and does not stack or restart music.
- During the 15-minute route there is no clipping, stuck loop, duplicated burst,
  harsh discontinuity, or mix element that masks spoken status.
- Music and ambience remain supportive rather than fatiguing at default levels.

## Physical GPU protocol

Run the same active route on one representative integrated GPU and one
representative discrete GPU. Use the production URL, a 1920x1080 or larger
viewport, the default **Balanced** visual quality, browser hardware acceleration,
and no frame-rate limiter below 60 Hz.

Record the WebGL renderer string and browser GPU diagnostics. The renderer must
name the physical GPU and must not contain `SwiftShader`, `software`, `llvmpipe`,
`Microsoft Basic`, or a virtual-display renderer.

Record the GPU class and display refresh rate, the warmup duration, the complete
sample duration, both two-minute window durations and median FPS values, and the
calculated final/initial ratio. The validator recomputes that ratio from the raw
window medians.

The headed hardware audit requires the tester to provide the measured display
refresh through `ACTIVE_PROGRESSION_DISPLAY_REFRESH_HZ`. A measured integer 59
is accepted as the normal Windows representation of a nominal 59.94/60 Hz
mode; lower values are rejected before Chromium launches. Keep the game tab
visible and focused for the continuous sample. More than five seconds of
hidden-page time or lost browser focus marks the environment ineligible and
stops frame thresholds from being interpreted as game performance. This
prevents a 30 Hz desktop or Chromium's one-frame-per-second background cadence
from being mislabeled as a runtime regression or a physical-GPU pass.

### Route

1. Allow 60 seconds after the office becomes interactive for shader and browser
   warmup.
2. Record at least 10 continuous minutes that include two complete shifts,
   repeated pans and zooms, Flockwatch and Settings transitions, a farmer review,
   a purchase or denial, active manager/worker movement, and a mature-office
   section loaded from a verified campaign backup.
3. Sample frame timing continuously. Measure input-to-visible-receipt latency for
   at least 20 actions spread across camera, navigation, and economic actions.
4. Compare median FPS in the first and final two-minute windows to detect
   progressive degradation.

### Pass thresholds

| Metric | Integrated GPU | Discrete GPU |
| --- | ---: | ---: |
| Sample duration | at least 600 seconds | at least 600 seconds |
| Median FPS | at least 30 | at least 55 |
| 1% low FPS | at least 20 | at least 40 |
| 95th-percentile input latency | at most 250 ms | at most 150 ms |
| Longest post-warmup stall | at most 1000 ms | at most 750 ms |
| Final/initial two-minute median FPS ratio | at least 0.80 | at least 0.80 |
| WebGL context loss or visual corruption | zero | zero |

Low quality may be recorded as diagnostic fallback evidence, but it does not
convert a Balanced-quality failure into a pass. Headless capture frame rates are
informational and do not replace this route.

## Evidence bundle

Each session's evidence bundle must include:

- a continuous video or screen/audio recording of the route;
- a short text log containing the environment identity and results;
- screenshots of any issue and, for GPU rows, the renderer and performance
  summary;
- the SHA-256 for every referenced evidence bundle; and
- issue IDs for every failure or accepted beta defect.

Store a local session bundle as a ZIP whose filename includes the exact session
ID. It must contain at least one non-empty video/audio recording and one
non-empty text, Markdown, JSON, or CSV log. GPU bundles must also contain a
non-empty PNG, JPEG, or WebP renderer/performance screenshot. Archive paths may
not be absolute or contain `..`.

Generate a candidate-bound kit for each session before handing it to a tester:

```powershell
./tools/new_physical_release_session_kit.ps1 `
  -SessionId "touch-ios"
```

The kit contains the exact commit, PCK hash, deployed URL, focus-specific
equipment and route reminders, a result object copied from the authoritative
schema, and tester notes. After the route, place the recording, completed
result, and notes in the session ZIP. GPU bundles also need a renderer or
performance screenshot.

Register the completed result and bundle together without editing the evidence
URI or digest by hand:

```powershell
./tools/register_physical_release_session.ps1 `
  -SessionId "touch-ios" `
  -ResultPath "output/release/physical-session-kits/touch-ios/session-result.json" `
  -BundlePath "output/release/evidence/touch-ios-session-bundle.zip"
```

Registration requires the evidence commit and PCK identity to match the current
candidate, rejects placeholder results, validates the ZIP contents and path
safety, computes its SHA-256, prevents cross-session reuse, and atomically
replaces that session's result plus evidence item. It refuses to replace already
registered evidence unless `-Force` is explicit. The final validator repeats the
same ZIP inspection, so manual JSON editing cannot bypass it.

`register_physical_session_bundle.ps1` remains available for an already
completed evidence JSON, but the atomic result-and-bundle path above is the
preferred handoff because it avoids partial manual updates.

The JSON may reference a repository-relative path or an immutable HTTPS URL.
Do not use a mutable shared-folder URL without a content hash.

For a repository-relative URI, the validator resolves the file inside this
repository, rejects path traversal or missing files, and recomputes SHA-256
from the referenced bytes. An HTTPS URI must remain an immutable, downloadable
release artifact; record the digest produced from the downloaded bundle rather
than a page, folder, or mutable sharing link. The standard beta gate runs the
validator's valid and adversarial fixtures plus a handoff self-test. The handoff
self-test proves candidate-bound kit creation, valid atomic registration,
duplicate rejection, and rejection of a GPU bundle missing its required
screenshot without changing the evidence record.

Schema v2 also verifies that iOS touch uses Safari, Android touch uses Chrome,
desktop reading uses NVDA or VoiceOver, mobile reading uses VoiceOver or
TalkBack, GPU rows declare the correct integrated/discrete class, touch targets
and recovery meet their numeric limits, all measurement windows are complete,
and approval occurs after every signed session. Timestamps more than five
minutes in the future are rejected.

## Release decision

Physical acceptance passes only when:

- all seven required sessions are `pass`;
- every required check in every session is `pass`;
- every evidence bundle has a non-placeholder URI and SHA-256;
- there are no open P0 or P1 issues;
- any accepted P2 issue is listed in the final decision; and
- the release owner records a `pass` decision with name and UTC timestamp.

If the checked-out candidate changes after testing, invalidate the decision and
run the affected sessions again. Keep the physical-evidence commit as the final
candidate: the validator intentionally requires both the exact commit and exact
PCK hash rather than inferring that a later change is harmless.
