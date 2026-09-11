param(
    [string]$ReportPath = "output\release\physical-release-handoff-self-test.json"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.IO.Compression.FileSystem

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

function Invoke-ChildScript {
    param(
        [string]$ScriptPath,
        [string[]]$Arguments
    )
    $powershell = (Get-Process -Id $PID).Path
    $priorErrorPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = @(
            & $powershell `
                -NoLogo `
                -NoProfile `
                -NonInteractive `
                -ExecutionPolicy Bypass `
                -File $ScriptPath `
                @Arguments 2>&1 |
                ForEach-Object { $_.ToString() }
        )
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $priorErrorPreference
    }
    return [ordered]@{
        exit_code = $exitCode
        output = $output
    }
}

function Test-CleanGeneratedText {
    param([string]$Text)
    return @(
        $Text.ToCharArray() |
            Where-Object { [int]$_ -lt 32 -and $_ -notin @("`r", "`n") }
    ).Count -eq 0
}

function Complete-FixtureResult {
    param([string]$ResultPath)
    $result = Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json
    $result.status = "pass"
    $result.tester = "Physical Handoff Fixture Tester"
    $result.signed_at_utc = [DateTimeOffset]::UtcNow.AddMinutes(-5).ToString("o")
    $result.notes = "Complete fixture observations with no release issue."
    foreach ($property in $result.environment.PSObject.Properties) {
        if ([string]$property.Value -match "(?i)REPLACE_WITH") {
            $property.Value = "Physical fixture value"
        }
    }
    foreach ($property in $result.check_results.PSObject.Properties) {
        $property.Value = "pass"
    }
    if ([string]$result.id -like "touch-*") {
        $result.metrics.single_fire_attempts = 20
        $result.metrics.pan_attempts = 10
        $result.metrics.pinch_attempts = 10
        $result.metrics.rotation_cycles = 5
        $result.metrics.minimum_control_width_css_px = 44
        $result.metrics.minimum_control_height_css_px = 44
        $result.metrics.maximum_orientation_recovery_seconds = 2
    }
    $result |
        ConvertTo-Json -Depth 12 |
        Set-Content -LiteralPath $ResultPath -Encoding utf8
}

function New-FixtureBundle {
    param(
        [string]$SessionId,
        [string]$ResultPath,
        [string]$Directory,
        [switch]$WithoutGpuScreenshot
    )
    $source = Join-Path $Directory "$SessionId-bundle-source"
    New-Item -ItemType Directory -Path $source -Force | Out-Null
    Copy-Item -LiteralPath $ResultPath -Destination (Join-Path $source "session-result.json")
    "Physical session environment, route observations, and issue log." |
        Set-Content -LiteralPath (Join-Path $source "tester-notes.md") -Encoding utf8
    [IO.File]::WriteAllBytes(
        (Join-Path $source "session.webm"),
        [byte[]](1, 2, 3, 4)
    )
    if ($SessionId -like "gpu-*" -and -not $WithoutGpuScreenshot) {
        [IO.File]::WriteAllBytes(
            (Join-Path $source "renderer-summary.png"),
            [byte[]](137, 80, 78, 71)
        )
    }
    $bundle = Join-Path $Directory "$SessionId-session-bundle.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory($source, $bundle)
    return $bundle
}

$started = Get-Date
$selfTestRoot = Get-RepositoryPath (
    "output\release\physical-release-handoff-" +
    [Guid]::NewGuid().ToString("N")
)
New-Item -ItemType Directory -Path $selfTestRoot -Force | Out-Null
$checks = [ordered]@{}
$failed = $false
try {
    $template = Get-Content -LiteralPath (
        Join-Path $root "docs\physical-release-evidence.template.json"
    ) -Raw | ConvertFrom-Json
    $gitSafeRoot = $root.Replace("\", "/")
    $head = (
        & git -c "safe.directory=$gitSafeRoot" -C $root rev-parse HEAD
    ).Trim().ToLowerInvariant()
    $pckHash = (
        Get-FileHash -LiteralPath (Join-Path $root "docs\index.pck") -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    $template.release.commit_sha = $head
    $template.release.pck_sha256 = $pckHash
    $template.release.tested_url = "https://example.com/project-pecking-order/"
    $template.release.pck_url = "https://example.com/project-pecking-order/index.pck"
    $template.release.tested_at_utc = [DateTimeOffset]::UtcNow.AddHours(-1).ToString("o")
    $template.release.coordinator = "Physical Handoff Fixture Coordinator"
    $evidencePath = Join-Path $selfTestRoot "physical-release-evidence.json"
    $template |
        ConvertTo-Json -Depth 16 |
        Set-Content -LiteralPath $evidencePath -Encoding utf8

    $kitRoot = Join-Path $selfTestRoot "kits"
    $kitResult = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "new_physical_release_session_kit.ps1") `
        @(
            "-SessionId", "touch-ios",
            "-EvidencePath", $evidencePath,
            "-OutputDirectory", $kitRoot
        )
    $touchKit = Join-Path $kitRoot "touch-ios"
    $kitFiles = @(
        "README.md",
        "session-brief.md",
        "session-result.json",
        "tester-notes.md"
    )
    $kitBrief = if (Test-Path -LiteralPath (Join-Path $touchKit "session-brief.md")) {
        Get-Content -LiteralPath (Join-Path $touchKit "session-brief.md") -Raw
    }
    else {
        ""
    }
    $kitReadme = if (Test-Path -LiteralPath (Join-Path $touchKit "README.md")) {
        Get-Content -LiteralPath (Join-Path $touchKit "README.md") -Raw
    }
    else {
        ""
    }
    $kitComplete = (
        $kitResult.exit_code -eq 0 -and
        @($kitFiles | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $touchKit $_) -PathType Leaf)
        }).Count -eq 0 -and
        $kitBrief -match [regex]::Escape($head) -and
        $kitBrief -match [regex]::Escape($pckHash) -and
        $kitBrief -match [regex]::Escape('`blocked` or `fail`') -and
        $kitReadme -match "register_physical_release_session\.ps1" -and
        $kitReadme -match [regex]::Escape('`tester-notes.md`') -and
        $kitReadme -match [regex]::Escape('~~~powershell') -and
        (Test-CleanGeneratedText $kitBrief) -and
        (Test-CleanGeneratedText $kitReadme)
    )
    $checks["session-kit"] = [ordered]@{
        passed = $kitComplete
        exit_code = $kitResult.exit_code
        file_count = @($kitFiles | Where-Object {
            Test-Path -LiteralPath (Join-Path $touchKit $_) -PathType Leaf
        }).Count
        identity_embedded = (
            $kitBrief -match [regex]::Escape($head) -and
            $kitBrief -match [regex]::Escape($pckHash)
        )
        markdown_clean = (
            $kitBrief -match [regex]::Escape('`blocked` or `fail`') -and
            $kitReadme -match [regex]::Escape('`tester-notes.md`') -and
            $kitReadme -match [regex]::Escape('~~~powershell') -and
            (Test-CleanGeneratedText $kitBrief) -and
            (Test-CleanGeneratedText $kitReadme)
        )
    }
    if (-not $kitComplete) {
        throw "Valid physical session kit generation failed: $($kitResult.output -join '; ')"
    }

    $touchResultPath = Join-Path $touchKit "session-result.json"
    Complete-FixtureResult $touchResultPath
    $touchBundle = New-FixtureBundle "touch-ios" $touchResultPath $selfTestRoot
    $registration = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "register_physical_release_session.ps1") `
        @(
            "-SessionId", "touch-ios",
            "-ResultPath", $touchResultPath,
            "-BundlePath", $touchBundle,
            "-EvidencePath", $evidencePath
        )
    $registeredEvidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
    $registeredSession = @(
        $registeredEvidence.sessions | Where-Object { $_.id -eq "touch-ios" }
    )[0]
    $registeredBundle = @($registeredSession.evidence)[0]
    $expectedHash = (
        Get-FileHash -LiteralPath $touchBundle -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    $registrationPassed = (
        $registration.exit_code -eq 0 -and
        [string]$registeredSession.status -eq "pass" -and
        [string]$registeredBundle.sha256 -eq $expectedHash
    )
    $checks["atomic-registration"] = [ordered]@{
        passed = $registrationPassed
        exit_code = $registration.exit_code
        hash_matches = [string]$registeredBundle.sha256 -eq $expectedHash
    }
    if (-not $registrationPassed) {
        throw "Valid physical session registration failed: $($registration.output -join '; ')"
    }

    $duplicate = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "register_physical_release_session.ps1") `
        @(
            "-SessionId", "touch-ios",
            "-ResultPath", $touchResultPath,
            "-BundlePath", $touchBundle,
            "-EvidencePath", $evidencePath
        )
    $checks["duplicate-rejected"] = [ordered]@{
        passed = (
            $duplicate.exit_code -ne 0 -and
            ($duplicate.output -join " ") -match "already has registered evidence"
        )
        exit_code = $duplicate.exit_code
    }

    $gpuKitResult = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "new_physical_release_session_kit.ps1") `
        @(
            "-SessionId", "gpu-discrete",
            "-EvidencePath", $evidencePath,
            "-OutputDirectory", $kitRoot
        )
    if ($gpuKitResult.exit_code -ne 0) {
        throw "GPU kit generation failed."
    }
    $gpuResultPath = Join-Path $kitRoot "gpu-discrete\session-result.json"
    Complete-FixtureResult $gpuResultPath
    $invalidBundle = New-FixtureBundle `
        "gpu-discrete" `
        $gpuResultPath `
        $selfTestRoot `
        -WithoutGpuScreenshot
    $beforeInvalidAttempt = (
        Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256
    ).Hash
    $invalid = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "register_physical_release_session.ps1") `
        @(
            "-SessionId", "gpu-discrete",
            "-ResultPath", $gpuResultPath,
            "-BundlePath", $invalidBundle,
            "-EvidencePath", $evidencePath
        )
    $afterInvalidAttempt = (
        Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256
    ).Hash
    $checks["invalid-bundle-rejected-atomically"] = [ordered]@{
        passed = (
            $invalid.exit_code -ne 0 -and
            ($invalid.output -join " ") -match "renderer/performance screenshot" -and
            $beforeInvalidAttempt -eq $afterInvalidAttempt
        )
        exit_code = $invalid.exit_code
        evidence_unchanged = $beforeInvalidAttempt -eq $afterInvalidAttempt
    }

    $failedChecks = @(
        $checks.GetEnumerator() | Where-Object { -not $_.Value.passed }
    )
    $failed = $failedChecks.Count -ne 0
    $result = [ordered]@{
        passed = -not $failed
        generated_at = [DateTimeOffset]::UtcNow.ToString("o")
        duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
        checks = $checks
    }
}
catch {
    $failed = $true
    $result = [ordered]@{
        passed = $false
        generated_at = [DateTimeOffset]::UtcNow.ToString("o")
        duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
        error = $_.Exception.Message
        checks = $checks
    }
}
finally {
    $safePrefix = (
        Get-RepositoryPath "output\release"
    ).TrimEnd([char[]]"\/") + [IO.Path]::DirectorySeparatorChar
    if (
        $selfTestRoot.StartsWith(
            $safePrefix,
            [StringComparison]::OrdinalIgnoreCase
        ) -and
        (Test-Path -LiteralPath $selfTestRoot)
    ) {
        Remove-Item -LiteralPath $selfTestRoot -Recurse -Force
    }
}

$absoluteReportPath = Get-RepositoryPath $ReportPath
New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteReportPath) -Force |
    Out-Null
$result |
    ConvertTo-Json -Depth 12 |
    Set-Content -LiteralPath $absoluteReportPath -Encoding utf8
Write-Output "PHYSICAL_RELEASE_HANDOFF passed=$($result.passed) report=$absoluteReportPath"
if ($failed) {
    exit 1
}
