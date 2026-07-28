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
    [Parameter(Mandatory = $true)][string]$ResultPath,
    [Parameter(Mandatory = $true)][string]$BundlePath,
    [string]$EvidencePath = "output\release\physical-release-evidence.json",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "physical_release_bundle.ps1")

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
if (
    [IO.Path]::GetFileNameWithoutExtension($absoluteBundlePath).IndexOf(
        $SessionId,
        [StringComparison]::OrdinalIgnoreCase
    ) -lt 0
) {
    throw "Bundle filename must include the session ID '$SessionId'."
}

$evidence = Get-Content -LiteralPath $absoluteEvidencePath -Raw | ConvertFrom-Json
$result = Get-Content -LiteralPath $absoluteResultPath -Raw | ConvertFrom-Json
if ([int]$evidence.schema_version -ne 2) {
    throw "Physical evidence record must use schema version 2."
}
if ([string]$result.id -ne $SessionId) {
    throw "Session result ID does not match '$SessionId'."
}
if ([string]$result.status -notin @("pass", "fail", "blocked")) {
    throw "Session result status must be pass, fail, or blocked."
}
if (-not (Test-MeaningfulText $result.tester)) {
    throw "Session result needs a non-placeholder tester."
}
$signedAt = [DateTimeOffset]::MinValue
if (
    -not [DateTimeOffset]::TryParse(
        [string]$result.signed_at_utc,
        [ref]$signedAt
    ) -or
    $signedAt.Offset -ne [TimeSpan]::Zero -or
    $signedAt -gt [DateTimeOffset]::UtcNow.AddMinutes(5)
) {
    throw "Session result needs a valid non-future UTC signed timestamp."
}
if ($result.environment.physical_device -ne $true) {
    throw "Session result must identify a physical device."
}
$serializedResult = $result | ConvertTo-Json -Depth 12
if ($serializedResult -match "(?i)(REPLACE_WITH|`"pending`")") {
    throw "Session result still contains placeholder or pending values."
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
$expectedChecks = @(
    $matchingSessions[0].check_results.PSObject.Properties.Name | Sort-Object
)
$actualChecks = @($result.check_results.PSObject.Properties.Name | Sort-Object)
if (
    $expectedChecks.Count -ne $actualChecks.Count -or
    (Compare-Object $expectedChecks $actualChecks).Count -ne 0
) {
    throw "Session result check keys do not match the '$SessionId' template."
}

$sessionKind = if ($SessionId -like "touch-*") {
    "touch"
}
elseif ($SessionId -like "screen-reader-*") {
    "screen-reader"
}
elseif ($SessionId -eq "audio-listening") {
    "audio"
}
else {
    "gpu"
}
$bundleIssues = @(
    Get-PhysicalSessionBundleIssues `
        -BundlePath $absoluteBundlePath `
        -SessionKind $sessionKind
)
if ($bundleIssues.Count -ne 0) {
    throw "Invalid $SessionId bundle: $($bundleIssues -join '; ')"
}

$existingSession = $matchingSessions[0]
$alreadyRegistered = @(
    @($existingSession.evidence) | Where-Object {
        (Test-MeaningfulText $_.uri) -and
        [string]$_.sha256 -match "^[0-9a-fA-F]{64}$"
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
$bundleHash = (
    Get-FileHash -LiteralPath $absoluteBundlePath -Algorithm SHA256
).Hash.ToLowerInvariant()
foreach ($session in @($evidence.sessions)) {
    if ([string]$session.id -eq $SessionId) {
        continue
    }
    if (@(
        @($session.evidence) | Where-Object {
            [string]$_.uri -eq $relativeBundlePath -or
            [string]$_.sha256 -eq $bundleHash
        }
    ).Count -gt 0) {
        throw "Bundle is already registered to session '$($session.id)'."
    }
}

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

Write-Output "PHYSICAL_RELEASE_SESSION_REGISTERED session=$SessionId status=$($result.status)"
Write-Output "  evidence=$absoluteEvidencePath"
Write-Output "  uri=$relativeBundlePath"
Write-Output "  sha256=$bundleHash"
