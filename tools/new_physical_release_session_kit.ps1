param(
    [Parameter(Mandatory = $true)]
    [ValidateSet(
        "touch-ios",
        "touch-android",
        "screen-reader-desktop",
        "screen-reader-mobile",
        "audio-listening",
        "gpu-integrated",
        "gpu-discrete"
    )]
    [string]$SessionId,
    [string]$EvidencePath = "output\release\physical-release-evidence.json",
    [string]$OutputDirectory = "output\release\physical-session-kits",
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
    "touch-ios" = [ordered]@{
        title = "iOS touch"
        duration = "First Clutch plus one complete shift"
        equipment = "Recent supported iPhone, current Safari, screen recorder"
        reminder = "Use touch only. Record 20 taps, 10 pans, 10 pinch cycles, and five rotation cycles."
    }
    "touch-android" = [ordered]@{
        title = "Android touch"
        duration = "First Clutch plus one complete shift"
        equipment = "Representative mid-range Android phone, current Chrome, screen recorder"
        reminder = "Use touch only. Record 20 taps, 10 pans, 10 pinch cycles, and five rotation cycles."
    }
    "screen-reader-desktop" = [ordered]@{
        title = "Desktop screen reader"
        duration = "Complete narration route and three economic decisions"
        equipment = "Windows with NVDA or macOS with VoiceOver; speech captured in the recording"
        reminder = "Run critical decisions with the screen off or eyes averted. Preserve spoken output."
    }
    "screen-reader-mobile" = [ordered]@{
        title = "Mobile screen reader"
        duration = "Complete mobile narration route and three economic decisions"
        equipment = "iOS VoiceOver or Android TalkBack; speech captured in the recording"
        reminder = "Run critical decisions with the screen off or eyes averted. Preserve spoken output."
    }
    "audio-listening" = [ordered]@{
        title = "Audio listening"
        duration = "At least 15 continuous minutes"
        equipment = "Real headphones or speakers in a quiet environment"
        reminder = "Test Master, SFX, UI, Music, and Ambient independently and record five focus cycles."
    }
    "gpu-integrated" = [ordered]@{
        title = "Integrated GPU"
        duration = "60-second warmup plus at least 10 continuous minutes"
        equipment = "Hardware-accelerated integrated-GPU computer and 1920x1080 or larger display"
        reminder = "Use Balanced quality. Capture renderer diagnostics, frame metrics, and a performance screenshot."
    }
    "gpu-discrete" = [ordered]@{
        title = "Discrete GPU"
        duration = "60-second warmup plus at least 10 continuous minutes"
        equipment = "Hardware-accelerated discrete-GPU computer and 1920x1080 or larger display"
        reminder = "Use Balanced quality. Capture renderer diagnostics, frame metrics, and a performance screenshot."
    }
}

$absoluteEvidencePath = Get-RepositoryPath $EvidencePath
if (-not (Test-Path -LiteralPath $absoluteEvidencePath -PathType Leaf)) {
    throw "Physical evidence record does not exist: $absoluteEvidencePath"
}
$evidence = Get-Content -LiteralPath $absoluteEvidencePath -Raw | ConvertFrom-Json
if ([int]$evidence.schema_version -ne 2) {
    throw "Physical evidence record must use schema version 2."
}
$gitSafeRoot = $root.Replace("\", "/")
$head = (
    & git -c "safe.directory=$gitSafeRoot" -C $root rev-parse HEAD
).Trim().ToLowerInvariant()
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

$absoluteOutputRoot = Get-RepositoryPath $OutputDirectory
$sessionDirectory = Join-Path $absoluteOutputRoot $SessionId
$knownFiles = @(
    "README.md",
    "session-brief.md",
    "session-result.json",
    "tester-notes.md"
)
if (
    (Test-Path -LiteralPath $sessionDirectory) -and
    -not $Force -and
    @(Get-ChildItem -LiteralPath $sessionDirectory -Force -ErrorAction SilentlyContinue).Count -gt 0
) {
    throw "Session kit already exists: $sessionDirectory. Pass -Force to refresh known files."
}
New-Item -ItemType Directory -Path $sessionDirectory -Force | Out-Null

$sessionResult = (
    $matchingSessions[0] |
        ConvertTo-Json -Depth 12 |
        ConvertFrom-Json
)
$sessionResult.evidence = @()
$sessionResult |
    ConvertTo-Json -Depth 12 |
    Set-Content -LiteralPath (Join-Path $sessionDirectory "session-result.json") -Encoding utf8

$definition = $catalog[$SessionId]
$checklist = @(
    $sessionResult.check_results.PSObject.Properties.Name |
        ForEach-Object { "- $_" }
) -join "`n"
$brief = @"
# $($definition.title) physical acceptance brief

Candidate commit: $head
Candidate PCK SHA-256: $docsHash
Tested URL: $($evidence.release.tested_url)
Expected duration: $($definition.duration)
Equipment: $($definition.equipment)

$($definition.reminder)

Required check-result keys:

$checklist

Follow the complete route and thresholds in
`docs/PHYSICAL_RELEASE_ACCEPTANCE.md`. Preserve the first attempt and record
every failure or accepted defect. A `blocked` or `fail` session is useful
evidence, but it does not approve the release.
"@
$brief |
    Set-Content -LiteralPath (Join-Path $sessionDirectory "session-brief.md") -Encoding utf8

$notes = @"
# $($definition.title) tester notes

## Environment

- Device model:
- OS and version:
- Browser and version:
- Assistive technology / audio device / GPU and driver, if applicable:
- Recording filename:

## Route observations

- Start and end UTC:
- First failure or hesitation:
- Focus, rotation, or recovery behavior:
- Economic state checked:
- Performance or listening observations:

## Issues

List every issue ID and severity, including accepted non-blocking issues.
"@
$notes |
    Set-Content -LiteralPath (Join-Path $sessionDirectory "tester-notes.md") -Encoding utf8

$relativeResultPath = (
    (Join-Path $sessionDirectory "session-result.json").
        Replace($root, "").
        TrimStart("\").
        Replace("\", "/")
)
$readme = @"
# $($definition.title) evidence kit

1. Confirm the commit, PCK hash, and URL in `session-brief.md`.
2. Record the complete first attempt on the required physical hardware.
3. Fill every field in `session-result.json` and `tester-notes.md`.
4. Put the recording, completed JSON, and notes in one ZIP named
   `$SessionId-session-bundle.zip`. GPU sessions also require a renderer or
   performance screenshot.
5. Register the completed result and bundle atomically:

```powershell
./tools/register_physical_release_session.ps1 ``
  -SessionId "$SessionId" ``
  -ResultPath "$relativeResultPath" ``
  -BundlePath "output/release/evidence/$SessionId-session-bundle.zip"
```

Do not edit the evidence URI or SHA-256 by hand. Registration validates the
archive, computes its digest, rejects reuse or accidental replacement, and
updates the candidate record atomically.
"@
$readme |
    Set-Content -LiteralPath (Join-Path $sessionDirectory "README.md") -Encoding utf8

Write-Output "PHYSICAL_RELEASE_SESSION_KIT_CREATED session=$SessionId"
Write-Output "  path=$sessionDirectory"
Write-Output "  commit_sha=$head"
Write-Output "  pck_sha256=$docsHash"
Write-Output "  files=$($knownFiles.Count)"
