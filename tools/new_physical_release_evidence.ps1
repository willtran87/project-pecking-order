param(
    [Parameter(Mandatory = $true)][string]$TestedUrl,
    [Parameter(Mandatory = $true)][string]$Coordinator,
    [string]$OutputPath = "output\release\physical-release-evidence.json",
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

if (-not (Test-MeaningfulText $Coordinator)) {
    throw "Coordinator must contain a non-placeholder name."
}

$parsedUrl = $null
if (
    -not (Test-MeaningfulText $TestedUrl) -or
    -not [Uri]::TryCreate($TestedUrl, [UriKind]::Absolute, [ref]$parsedUrl) -or
    $parsedUrl.Scheme -ne "https"
) {
    throw "TestedUrl must be a non-placeholder HTTPS URL."
}
if (
    -not $parsedUrl.AbsolutePath.EndsWith("/") -or
    -not [string]::IsNullOrEmpty($parsedUrl.Query) -or
    -not [string]::IsNullOrEmpty($parsedUrl.Fragment)
) {
    throw "TestedUrl must be a query-free deployment root ending in /."
}
$pckUrl = [Uri]::new($parsedUrl, "index.pck")

$trackedStatus = @(& git -C $root status --porcelain --untracked-files=no)
if ($LASTEXITCODE -ne 0) {
    throw "Unable to inspect the Git worktree."
}
if ($trackedStatus.Count -ne 0) {
    throw "Commit or discard tracked changes before initializing physical evidence."
}

$commit = (& git -C $root rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch "^[0-9a-fA-F]{40}$") {
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
            "User-Agent" = "Pecking-Order-Physical-Release-Initializer"
        }
    $deployedHash = (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash
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

$templatePath = Join-Path $root "docs\physical-release-evidence.template.json"
$evidence = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Json
if ([int]$evidence.schema_version -ne 2) {
    throw "The physical evidence template must use schema version 2."
}

$evidence.release.commit_sha = $commit.ToLowerInvariant()
$evidence.release.pck_sha256 = $docsHash.ToLowerInvariant()
$evidence.release.tested_url = $parsedUrl.AbsoluteUri
$evidence.release.pck_url = $pckUrl.AbsoluteUri
$evidence.release.tested_at_utc = [DateTimeOffset]::UtcNow.ToString("o")
$evidence.release.coordinator = $Coordinator.Trim()

$absoluteOutputPath = if ([IO.Path]::IsPathRooted($OutputPath)) {
    [IO.Path]::GetFullPath($OutputPath)
}
else {
    [IO.Path]::GetFullPath((Join-Path $root $OutputPath))
}
$rootPrefix =
    [IO.Path]::GetFullPath($root).TrimEnd([char[]]"\/") +
    [IO.Path]::DirectorySeparatorChar
if (-not $absoluteOutputPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "OutputPath must remain inside the repository."
}
if ((Test-Path -LiteralPath $absoluteOutputPath) -and -not $Force) {
    throw "Evidence file already exists: $absoluteOutputPath. Pass -Force to replace it."
}

New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteOutputPath) -Force |
    Out-Null
$evidence |
    ConvertTo-Json -Depth 12 |
    Set-Content -LiteralPath $absoluteOutputPath -Encoding utf8

Write-Output "PHYSICAL_RELEASE_EVIDENCE_INITIALIZED path=$absoluteOutputPath"
Write-Output "  commit_sha=$($commit.ToLowerInvariant())"
Write-Output "  pck_sha256=$($docsHash.ToLowerInvariant())"
Write-Output "  tested_url=$($parsedUrl.AbsoluteUri)"
Write-Output "  pck_url=$($pckUrl.AbsoluteUri)"
Write-Output "  deployed_bytes=$deployedBytes"
Write-Output "Complete all seven sessions, then run tools\verify_physical_release_evidence.ps1."
