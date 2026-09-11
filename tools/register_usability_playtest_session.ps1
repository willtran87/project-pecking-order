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
    [Parameter(Mandatory = $true)][string]$ResultPath,
    [Parameter(Mandatory = $true)][string]$BundlePath,
    [string]$EvidencePath = "output\release\usability-playtest-evidence.json",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "usability_playtest_bundle.ps1")

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

function Test-MeaningfulText {
    param([AllowNull()][object]$Value)
    $text = [string]$Value
    return (
        -not [string]::IsNullOrWhiteSpace($text) -and
        $text -notmatch "(?i)(^|[^A-Z0-9])(REPLACE|PENDING|TODO|TBD)(_|[^A-Z0-9]|$)"
    )
}

$absoluteEvidencePath = Get-RepositoryPath $EvidencePath
$absoluteResultPath = Get-RepositoryPath $ResultPath
$absoluteBundlePath = Get-RepositoryPath $BundlePath
foreach ($requiredPath in @($absoluteEvidencePath, $absoluteResultPath, $absoluteBundlePath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required file does not exist: $requiredPath"
    }
}

$evidence = Get-Content -LiteralPath $absoluteEvidencePath -Raw | ConvertFrom-Json
$result = Get-Content -LiteralPath $absoluteResultPath -Raw | ConvertFrom-Json
if ([int]$evidence.schema_version -ne 1) {
    throw "Usability evidence record must use schema version 1."
}
if ([string]$result.id -ne $SessionId) {
    throw "Session result ID does not match '$SessionId'."
}
if ([string]$result.status -notin @("pass", "fail", "blocked")) {
    throw "Session result status must be pass, fail, or blocked."
}
if (
    -not (Test-MeaningfulText $result.tester) -or
    -not (Test-MeaningfulText $result.signed_at_utc) -or
    -not (Test-MeaningfulText $result.notes)
) {
    throw "Session result needs a tester, signed timestamp, and participant rationale."
}
if (@($result.task_results).Count -lt 1) {
    throw "Session result must contain task-level observations."
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

$bundleIssues = @(
    Get-UsabilityPlaytestBundleIssues `
        -BundlePath $absoluteBundlePath `
        -SessionId $SessionId
)
if ($bundleIssues.Count -ne 0) {
    throw "Invalid $SessionId bundle: $($bundleIssues -join '; ')"
}

$matchingSessions = @($evidence.sessions | Where-Object { $_.id -eq $SessionId })
if ($matchingSessions.Count -ne 1) {
    throw "Evidence record must contain exactly one '$SessionId' session."
}
$existingSession = $matchingSessions[0]
$alreadyRegistered = @(
    @($existingSession.evidence) | Where-Object {
        Test-MeaningfulText $_.uri -and [string]$_.sha256 -match "^[0-9a-fA-F]{64}$"
    }
).Count -gt 0
if ($alreadyRegistered -and -not $Force) {
    throw "Session already has registered evidence. Pass -Force to replace it."
}

$repositoryPrefix = (
    [IO.Path]::GetFullPath($root).TrimEnd([char[]]"\/") +
    [IO.Path]::DirectorySeparatorChar
)
$relativeBundlePath = $absoluteBundlePath.Substring(
    $repositoryPrefix.Length
).Replace("\", "/")
foreach ($session in @($evidence.sessions)) {
    if ([string]$session.id -eq $SessionId) {
        continue
    }
    if (@(
        @($session.evidence) | Where-Object {
            [string]$_.uri -eq $relativeBundlePath
        }
    ).Count -gt 0) {
        throw "Bundle URI is already registered to session '$($session.id)'."
    }
}
$bundleHash = (
    Get-FileHash -LiteralPath $absoluteBundlePath -Algorithm SHA256
).Hash.ToLowerInvariant()
$result.evidence = [object[]]@(
    [ordered]@{
        type = "session-bundle"
        uri = $relativeBundlePath
        sha256 = $bundleHash
    }
)

for ($index = 0; $index -lt @($evidence.sessions).Count; $index++) {
    if ([string]$evidence.sessions[$index].id -eq $SessionId) {
        $evidence.sessions[$index] = $result
        break
    }
}

$temporaryPath = "$absoluteEvidencePath.tmp-$([Guid]::NewGuid().ToString('N'))"
try {
    $evidence |
        ConvertTo-Json -Depth 16 |
        Set-Content -LiteralPath $temporaryPath -Encoding utf8
    Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json | Out-Null
    Move-Item -LiteralPath $temporaryPath -Destination $absoluteEvidencePath -Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

Write-Output "USABILITY_PLAYTEST_SESSION_REGISTERED session=$SessionId status=$($result.status)"
Write-Output "  evidence=$absoluteEvidencePath"
Write-Output "  uri=$relativeBundlePath"
Write-Output "  sha256=$bundleHash"
