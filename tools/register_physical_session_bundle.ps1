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
    [Parameter(Mandatory = $true)][string]$BundlePath,
    [string]$EvidencePath = "output\release\physical-release-evidence.json",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "physical_release_bundle.ps1")

function Get-AbsoluteRepositoryPath {
    param([string]$Path)
    $absolutePath = if ([IO.Path]::IsPathRooted($Path)) {
        [IO.Path]::GetFullPath($Path)
    }
    else {
        [IO.Path]::GetFullPath((Join-Path $root $Path))
    }
    $rootPrefix =
        [IO.Path]::GetFullPath($root).TrimEnd([char[]]"\/") +
        [IO.Path]::DirectorySeparatorChar
    if (-not $absolutePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path must remain inside the repository: $Path"
    }
    return $absolutePath
}

$absoluteEvidencePath = Get-AbsoluteRepositoryPath $EvidencePath
$absoluteBundlePath = Get-AbsoluteRepositoryPath $BundlePath
if (-not (Test-Path -LiteralPath $absoluteEvidencePath -PathType Leaf)) {
    throw "Physical evidence record does not exist: $absoluteEvidencePath"
}
if (-not (Test-Path -LiteralPath $absoluteBundlePath -PathType Leaf)) {
    throw "Session bundle does not exist: $absoluteBundlePath"
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
if ([int]$evidence.schema_version -ne 2) {
    throw "Physical evidence record must use schema version 2."
}
$head = (& git -C $root rev-parse HEAD).Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $evidence.release.commit_sha -ne $head) {
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

$sessions = @($evidence.sessions)
$matchingSessions = @($sessions | Where-Object { $_.id -eq $SessionId })
if ($matchingSessions.Count -ne 1) {
    throw "Evidence record must contain exactly one '$SessionId' session."
}
$session = $matchingSessions[0]
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

$bundleIssues = @(Get-PhysicalSessionBundleIssues `
    -BundlePath $absoluteBundlePath `
    -SessionKind $sessionKind)
if ($bundleIssues.Count -ne 0) {
    throw "Invalid $SessionId bundle: $($bundleIssues -join '; ')"
}

$existingEvidence = @($session.evidence)
$hasRegisteredEvidence = @(
    $existingEvidence | Where-Object {
        [string]$_.uri -notmatch "(?i)(REPLACE|PENDING|TODO|TBD)" -and
        [string]$_.sha256 -match "^[0-9a-fA-F]{64}$"
    }
).Count -gt 0
if ($hasRegisteredEvidence -and -not $Force) {
    throw "Session already has registered evidence. Pass -Force to replace it."
}

$rootPrefix =
    [IO.Path]::GetFullPath($root).TrimEnd([char[]]"\/") +
    [IO.Path]::DirectorySeparatorChar
$relativeBundlePath =
    $absoluteBundlePath.Substring($rootPrefix.Length).Replace("\", "/")
$bundleHash = (
    Get-FileHash -LiteralPath $absoluteBundlePath -Algorithm SHA256
).Hash.ToLowerInvariant()
$session.evidence = [object[]]@(
    [ordered]@{
        type = "session-bundle"
        uri = $relativeBundlePath
        sha256 = $bundleHash
    }
)

$temporaryPath = "$absoluteEvidencePath.tmp-$([Guid]::NewGuid().ToString('N'))"
try {
    $evidence |
        ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $temporaryPath -Encoding utf8
    Get-Content -LiteralPath $temporaryPath -Raw | ConvertFrom-Json | Out-Null
    Move-Item -LiteralPath $temporaryPath -Destination $absoluteEvidencePath -Force
}
finally {
    if (Test-Path -LiteralPath $temporaryPath -PathType Leaf) {
        Remove-Item -LiteralPath $temporaryPath -Force
    }
}

Write-Output "PHYSICAL_SESSION_BUNDLE_REGISTERED session=$SessionId"
Write-Output "  evidence=$absoluteEvidencePath"
Write-Output "  uri=$relativeBundlePath"
Write-Output "  sha256=$bundleHash"
