param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "comprehension",
        "friction",
        "pacing",
        "fun",
        "strategic-depth",
        "feedback-clarity",
        "long-session-fatigue"
    )]
    [string]$SessionId,
    [string]$EvidencePath = "output\release\usability-playtest-evidence.json",
    [string]$OutputDirectory = "output\release\playtest-session-kits",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Get-RepositoryPath {
    param([string]$Path)
    $absolute = if ([IO.Path]::IsPathRooted($Path)) {
        [IO.Path]::GetFullPath($Path)
    }
    else {
        [IO.Path]::GetFullPath((Join-Path $root $Path))
    }
    $prefix = (
        [IO.Path]::GetFullPath($root).TrimEnd([char[]]"\/") +
        [IO.Path]::DirectorySeparatorChar
    )
    if (-not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path must remain inside the repository: $Path"
    }
    return $absolute
}

$catalog = [ordered]@{
    "comprehension" = [ordered]@{
        title = "Comprehension"
        minimum_minutes = 20
        focus_prompt = "Can the player explain the objective, resources, change causes, and recovery path without instruction?"
        tasks = @(
            @("find-current-objective", $true, "Find and state the current objective."),
            @("explain-feed-fund-change", $true, "Explain why Feed Fund changed after one outcome."),
            @("identify-leading-bottleneck", $false, "Find the leading bottleneck and its suggested action."),
            @("compare-disclosed-options", $false, "Compare two available choices using disclosed costs and tradeoffs."),
            @("recover-route-mistake", $true, "Recover from an invited reversible route mistake.")
        )
    }
    "friction" = [ordered]@{
        title = "Friction"
        minimum_minutes = 20
        focus_prompt = "Can common actions be completed without unnecessary clicks, traps, or accidental commands?"
        tasks = @(
            @("start-or-resume-campaign", $true, "Start or resume the intended campaign."),
            @("inspect-and-route-hen", $false, "Inspect and route one named hen."),
            @("change-simulation-speed", $false, "Change speed and return to the prior speed."),
            @("use-priority-peck", $false, "Use one Priority Peck intervention."),
            @("open-close-flockwatch", $false, "Open and close Flockwatch without losing context."),
            @("claim-confirm-and-cancel", $false, "Open an irreversible claimant confirmation and cancel safely."),
            @("route-undo", $true, "Change a route and restore the prior tray with Undo."),
            @("export-campaign-backup", $false, "Export a campaign backup and identify the receipt.")
        )
    }
    "pacing" = [ordered]@{
        title = "Pacing"
        minimum_minutes = 30
        focus_prompt = "Does the first two-shift rhythm move through planning, action, consequence, payoff, and recovery?"
        tasks = @(
            @("first-meaningful-decision", $false, "Reach and identify the first meaningful decision."),
            @("first-visible-consequence", $false, "Observe and explain the first visible consequence."),
            @("first-payoff", $false, "Reach and identify the first payoff."),
            @("recovery-interval", $false, "Use or identify a useful recovery/planning interval."),
            @("complete-two-shifts", $true, "Complete First Clutch and two full shifts.")
        )
    }
    "fun" = [ordered]@{
        title = "Fun"
        minimum_minutes = 30
        focus_prompt = "Are the choices, outcomes, satire, and progression enjoyable enough to continue voluntarily?"
        tasks = @(
            @("incident-choice", $false, "Make and reflect on an incident response."),
            @("worker-care-choice", $false, "Make and reflect on a worker-care or labor choice."),
            @("contract-or-directive-choice", $true, "Choose a contract or directive from disclosed terms."),
            @("reinvestment-choice", $false, "Make a reinvestment or expansion choice."),
            @("farmer-credit-outcome", $false, "Reach and interpret a farmer-credit outcome.")
        )
    }
    "strategic-depth" = [ordered]@{
        title = "Strategic depth"
        minimum_minutes = 45
        focus_prompt = "Can the player form, compare, and adapt at least two viable economic plans?"
        tasks = @(
            @("state-first-plan", $true, "State a plan before committing resources."),
            @("forecast-market-or-bottleneck", $false, "Forecast one market change or bottleneck."),
            @("short-vs-long-tradeoff", $false, "Choose between immediate yield and later resilience."),
            @("adapt-after-setback", $true, "Adapt the plan after a visible setback."),
            @("compare-second-strategy", $false, "Try or compare a materially different strategy."),
            @("explain-build-identity", $false, "Explain which choices define the current economic build.")
        )
    }
    "feedback-clarity" = [ordered]@{
        title = "Feedback clarity"
        minimum_minutes = 20
        focus_prompt = "Can the player tell what changed, why, and what to do next from receipts and world response?"
        tasks = @(
            @("identify-money-earned", $false, "Identify a money-earned outcome and its source."),
            @("identify-money-spent", $false, "Identify a money-spent outcome and its purpose."),
            @("interpret-rejected-action", $true, "Explain why an action was rejected and how to recover."),
            @("interpret-warning", $false, "Explain one warning and its next action."),
            @("interpret-save-receipt", $false, "Identify one successful or failed save receipt."),
            @("interpret-milestone", $false, "Explain one milestone and what it unlocked."),
            @("trace-delayed-consequence", $true, "Trace one delayed consequence back to its prior choice.")
        )
    }
    "long-session-fatigue" = [ordered]@{
        title = "Long-session fatigue"
        minimum_minutes = 90
        focus_prompt = "Does sustained play avoid repetitive strain, clutter, sensory fatigue, and decision exhaustion?"
        tasks = @(
            @("complete-three-shifts", $true, "Complete at least three shifts."),
            @("complete-farmer-review", $false, "Complete and interpret one Farmer Review."),
            @("use-two-planning-surfaces", $false, "Use two different planning or comparison surfaces."),
            @("change-comfort-preference", $false, "Change one comfort preference and verify its effect."),
            @("resume-after-break", $true, "Return after five minutes and recover context from the recap.")
        )
    }
}

$absoluteEvidencePath = Get-RepositoryPath $EvidencePath
if (-not (Test-Path -LiteralPath $absoluteEvidencePath -PathType Leaf)) {
    throw "Usability evidence record does not exist: $absoluteEvidencePath"
}
$evidence = Get-Content -LiteralPath $absoluteEvidencePath -Raw | ConvertFrom-Json
if ([int]$evidence.schema_version -ne 1) {
    throw "Usability evidence record must use schema version 1."
}
$head = (& git -C $root rev-parse HEAD).Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or [string]$evidence.release.commit_sha -ne $head) {
    throw "Evidence release commit does not match the checked-out commit."
}
$docsHash = (
    Get-FileHash -LiteralPath (Join-Path $root "docs\index.pck") -Algorithm SHA256
).Hash.ToLowerInvariant()
$webHash = (
    Get-FileHash -LiteralPath (Join-Path $root "web\public\game\index.pck") -Algorithm SHA256
).Hash.ToLowerInvariant()
if (
    $docsHash -ne $webHash -or
    [string]$evidence.release.pck_sha256 -ne $docsHash
) {
    throw "Evidence release payload does not match both shipped PCK files."
}
$matchingSessions = @($evidence.sessions | Where-Object { $_.id -eq $SessionId })
if ($matchingSessions.Count -ne 1) {
    throw "Evidence record must contain exactly one '$SessionId' session."
}

$definition = $catalog[$SessionId]
$absoluteOutputRoot = Get-RepositoryPath $OutputDirectory
$sessionDirectory = Join-Path $absoluteOutputRoot $SessionId
$knownFiles = @(
    "README.md",
    "session-brief.md",
    "session-result.json",
    "moderator-notes.md"
)
if (
    (Test-Path -LiteralPath $sessionDirectory) -and
    -not $Force -and
    @(Get-ChildItem -LiteralPath $sessionDirectory -Force -ErrorAction SilentlyContinue).Count -gt 0
) {
    throw "Session kit already exists: $sessionDirectory. Pass -Force to refresh known files."
}
New-Item -ItemType Directory -Path $sessionDirectory -Force | Out-Null

$taskRows = @()
foreach ($taskDefinition in $definition.tasks) {
    $taskRows += [ordered]@{
        id = [string]$taskDefinition[0]
        prompt = [string]$taskDefinition[2]
        outcome = "pending"
        critical = [bool]$taskDefinition[1]
        completed_unaided = $false
        elapsed_seconds = 0
        external_instruction_count = 0
        wrong_turns = 0
        notes = ""
    }
}
$sessionResult = [ordered]@{
    id = $SessionId
    status = "pending"
    tester = "REPLACE_WITH_TESTER"
    signed_at_utc = "REPLACE_WITH_ISO_8601_UTC_TIMESTAMP"
    independent_tester = $false
    consent_to_record = $false
    experience = "new"
    metrics = [ordered]@{
        session_minutes = 0
        tasks_attempted = 0
        tasks_completed_unaided = 0
        critical_tasks_attempted = 0
        critical_tasks_completed_unaided = 0
        information_find_rate = 0
        change_explanation_rate = 0
        mistake_recovery_rate = 0
        external_instruction_count = 0
        focus_rating_1_to_7 = 0
        distinct_strategies_attempted = 0
        reasoned_economic_choices = 0
        evidence_based_adaptations = 0
        decisionless_waits_over_30_seconds = 0
        enjoyable_moments = 0
        would_continue = $false
        fatigue_rating_1_to_7 = 0
        low_value_repetitive_chores = 0
    }
    common_capabilities = [ordered]@{
        "find-current-priority" = "pending"
        "explain-economic-change" = "pending"
        "complete-economic-action" = "pending"
        "recover-from-mistake" = "pending"
    }
    task_results = $taskRows
    evidence = @()
    blocking_issues = @()
    notes = ""
}
$sessionResult |
    ConvertTo-Json -Depth 12 |
    Set-Content -LiteralPath (Join-Path $sessionDirectory "session-result.json") -Encoding utf8

$brief = @"
# $($definition.title) session brief

Candidate commit: $head
Candidate PCK SHA-256: $docsHash
Tested URL: $($evidence.release.tested_url)
Minimum duration: $($definition.minimum_minutes) minutes
Minimum task count: $($definition.tasks.Count)

Primary question: $($definition.focus_prompt)

Read only the task prompts from ``session-result.json``. Do not name a control,
define the economy, recommend a choice, or rescue a wrong turn. Count every
directional hint in ``external_instruction_count``. Preserve the first attempt.

The session must also sample finding the current priority, explaining an
economic change, completing an economic action, and recovering from a mistake.
Record the participant's rationale in their own words.
"@
$brief | Set-Content -LiteralPath (Join-Path $sessionDirectory "session-brief.md") -Encoding utf8

$notes = @"
# $($definition.title) moderator notes

## Environment

- Device / OS:
- Browser / version:
- Input method:
- Recording filename:

## Observations

- First hesitation:
- Wrong turns:
- Information searched for:
- Change explanation:
- Mistake recovery:
- Enjoyable or frustrating moments:

## Participant rationale

Record the participant's words for the focus rating and willingness to continue.

## Issues

List every issue ID and severity, including accepted non-blocking issues.
"@
$notes | Set-Content -LiteralPath (Join-Path $sessionDirectory "moderator-notes.md") -Encoding utf8

$readme = @"
# $($definition.title) evidence kit

1. Confirm the commit, PCK hash, and URL in ``session-brief.md``.
2. Record the complete first attempt.
3. Fill every field in ``session-result.json`` and ``moderator-notes.md``.
4. Put the recording, completed JSON, and notes in one ZIP named
   ``$($SessionId)-session-bundle.zip``.
5. Register both the result and bundle atomically:

~~~powershell
./tools/register_usability_playtest_session.ps1 ``
  -SessionId "$SessionId" ``
  -ResultPath "$($sessionDirectory.Replace($root, '').TrimStart('\').Replace('\', '/'))/session-result.json" ``
  -BundlePath "output/release/evidence/$SessionId-session-bundle.zip"
~~~

Do not edit the evidence URI or SHA-256 by hand. The registration tool validates
the archive, computes its digest, prevents cross-session reuse, and writes the
candidate evidence record atomically.
"@
$readme | Set-Content -LiteralPath (Join-Path $sessionDirectory "README.md") -Encoding utf8

Write-Output "USABILITY_PLAYTEST_SESSION_KIT_CREATED session=$SessionId"
Write-Output "  path=$sessionDirectory"
Write-Output "  commit_sha=$head"
Write-Output "  pck_sha256=$docsHash"
Write-Output "  files=$($knownFiles.Count)"
