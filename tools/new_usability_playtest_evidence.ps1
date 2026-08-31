param(
    [Parameter(Mandatory = $true)][string]$TestedUrl,
    [Parameter(Mandatory = $true)][string]$Coordinator,
    [string]$OutputPath = "output\release\usability-playtest-evidence.json",
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Test-MeaningfulText {
    param([string]$Value)
    return (
        -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -notmatch "(?i)(^|[^A-Z0-9])(REPLACE|PENDING|TODO|TBD)(_|[^A-Z0-9]|$)"
    )
}

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
        throw "OutputPath must remain inside the repository."
    }
    return $absolute
}

if (-not (Test-MeaningfulText $Coordinator)) {
    throw "Coordinator must contain a non-placeholder name."
}
$parsedUrl = $null
if (
    -not (Test-MeaningfulText $TestedUrl) -or
    -not [Uri]::TryCreate($TestedUrl, [UriKind]::Absolute, [ref]$parsedUrl) -or
    $parsedUrl.Scheme -ne "https" -or
    -not $parsedUrl.AbsolutePath.EndsWith("/") -or
    -not [string]::IsNullOrEmpty($parsedUrl.Query) -or
    -not [string]::IsNullOrEmpty($parsedUrl.Fragment)
) {
    throw "TestedUrl must be a query-free HTTPS deployment root ending in /."
}
$pckUrl = [Uri]::new($parsedUrl, "index.pck")

$trackedStatus = @(& git -C $root status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the Git worktree."
}
if ($trackedStatus.Count -ne 0) {
    throw "Commit or discard tracked changes before initializing playtest evidence."
}
$commit = (& git -C $root rev-parse HEAD).Trim().ToLowerInvariant()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch "^[0-9a-f]{40}$") {
    throw "Unable to resolve the exact release commit."
}

$docsPck = Join-Path $root "docs\index.pck"
$webPck = Join-Path $root "web\public\game\index.pck"
if (
    -not (Test-Path -LiteralPath $docsPck -PathType Leaf) -or
    -not (Test-Path -LiteralPath $webPck -PathType Leaf)
) {
    throw "Both shipped index.pck files must exist."
}
$docsHash = (Get-FileHash -LiteralPath $docsPck -Algorithm SHA256).Hash
$webHash = (Get-FileHash -LiteralPath $webPck -Algorithm SHA256).Hash
if ($docsHash -ne $webHash) {
    throw "The docs and wrapper index.pck payloads do not match."
}

$downloadPath = [IO.Path]::GetTempFileName()
try {
    Invoke-WebRequest `
        -Uri $pckUrl `
        -OutFile $downloadPath `
        -TimeoutSec 180 `
        -Headers @{
            "Cache-Control" = "no-cache"
            "User-Agent" = "Pecking-Order-Usability-Playtest-Initializer"
        }
    $deployedHash = (
        Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256
    ).Hash
    $deployedBytes = (Get-Item -LiteralPath $downloadPath).Length
}
finally {
    if (Test-Path -LiteralPath $downloadPath -PathType Leaf) {
        Remove-Item -LiteralPath $downloadPath -Force
    }
}
if ($deployedHash -ne $docsHash) {
    throw "The deployed index.pck at $pckUrl does not match the shipped payload."
}

$templatePath = Join-Path $root "docs\usability-playtest-evidence.template.json"
$evidence = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
if ([int]$evidence.schema_version -ne 1 -or @($evidence.sessions).Count -ne 7) {
    throw "The usability evidence template must be complete schema version 1."
}
$requiredSessionIds = @(
    "comprehension",
    "friction",
    "pacing",
    "fun",
    "strategic-depth",
    "feedback-clarity",
    "long-session-fatigue"
)
$templateSessionIds = @($evidence.sessions | ForEach-Object { [string]$_.id })
foreach ($requiredSessionId in $requiredSessionIds) {
    if (@(
        $templateSessionIds | Where-Object { $_ -eq $requiredSessionId }
    ).Count -ne 1) {
        throw "Template must contain exactly one '$requiredSessionId' session."
    }
}
$evidence.release.commit_sha = $commit
$evidence.release.pck_sha256 = $docsHash.ToLowerInvariant()
$evidence.release.tested_url = $parsedUrl.AbsoluteUri
$evidence.release.pck_url = $pckUrl.AbsoluteUri
$evidence.release.tested_at_utc = [DateTimeOffset]::UtcNow.ToString("o")
$evidence.release.coordinator = $Coordinator.Trim()

$absoluteOutputPath = Get-RepositoryPath $OutputPath
if ((Test-Path -LiteralPath $absoluteOutputPath) -and -not $Force) {
    throw "Evidence file already exists: $absoluteOutputPath. Pass -Force to replace it."
}
New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteOutputPath) -Force |
    Out-Null
$evidence |
    ConvertTo-Json -Depth 16 |
    Set-Content -LiteralPath $absoluteOutputPath -Encoding utf8

Write-Output "USABILITY_PLAYTEST_EVIDENCE_INITIALIZED path=$absoluteOutputPath"
Write-Output "  commit_sha=$commit"
Write-Output "  pck_sha256=$($docsHash.ToLowerInvariant())"
Write-Output "  tested_url=$($parsedUrl.AbsoluteUri)"
Write-Output "  pck_url=$($pckUrl.AbsoluteUri)"
Write-Output "  deployed_bytes=$deployedBytes"
Write-Output "Complete all seven sessions, then run tools\verify_usability_playtest_evidence.ps1."
