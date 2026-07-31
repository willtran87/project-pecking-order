param(
    [string]$ReportPath = "output\release\usability-playtest-handoff-self-test.json"
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
    param(
        [string]$ResultPath,
        [string]$SessionId,
        [string]$Status = "pass"
    )
    $result = Get-Content -LiteralPath $ResultPath -Raw | ConvertFrom-Json
    $result.status = $Status
    $result.tester = "Handoff Fixture Tester"
    $result.signed_at_utc = [DateTimeOffset]::UtcNow.AddMinutes(-5).ToString("o")
    $result.independent_tester = $true
    $result.consent_to_record = $true
    $result.experience = "new"
    $result.notes = "Participant rationale and moderator observations are recorded."
    foreach ($task in @($result.task_results)) {
        $task.outcome = "pass"
        $task.completed_unaided = $true
        $task.elapsed_seconds = 60
    }
    $result.metrics.session_minutes = 20
    $result.metrics.tasks_attempted = @($result.task_results).Count
    $result.metrics.tasks_completed_unaided = @($result.task_results).Count
    $criticalCount = @($result.task_results | Where-Object { $_.critical }).Count
    $result.metrics.critical_tasks_attempted = $criticalCount
    $result.metrics.critical_tasks_completed_unaided = $criticalCount
    $result.metrics.information_find_rate = 1.0
    $result.metrics.change_explanation_rate = 1.0
    $result.metrics.mistake_recovery_rate = 1.0
    $result.metrics.focus_rating_1_to_7 = 6
    foreach ($property in $result.common_capabilities.PSObject.Properties) {
        $property.Value = "pass"
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
        [switch]$WithoutRecording
    )
    $source = Join-Path $Directory "$SessionId-bundle-source"
    New-Item -ItemType Directory -Path $source -Force | Out-Null
    Copy-Item -LiteralPath $ResultPath -Destination (Join-Path $source "session-result.json")
    "Participant rationale and moderator observations." |
        Set-Content -LiteralPath (Join-Path $source "moderator-notes.md") -Encoding utf8
    if (-not $WithoutRecording) {
        [IO.File]::WriteAllBytes(
            (Join-Path $source "session.webm"),
            [byte[]](1, 2, 3, 4)
        )
    }
    $bundle = Join-Path $Directory "$SessionId-session-bundle.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory($source, $bundle)
    return $bundle
}

$started = Get-Date
$selfTestRoot = Get-RepositoryPath (
    "output\release\usability-playtest-handoff-" +
    [Guid]::NewGuid().ToString("N")
)
New-Item -ItemType Directory -Path $selfTestRoot -Force | Out-Null
$checks = [ordered]@{}
$failed = $false
try {
    $template = Get-Content -LiteralPath (
        Join-Path $root "docs\usability-playtest-evidence.template.json"
    ) -Raw | ConvertFrom-Json
    $head = (& git -C $root rev-parse HEAD).Trim().ToLowerInvariant()
    $pckHash = (
        Get-FileHash -LiteralPath (Join-Path $root "docs\index.pck") -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    $template.release.commit_sha = $head
    $template.release.pck_sha256 = $pckHash
    $template.release.tested_url = "https://example.com/project-pecking-order/"
    $template.release.pck_url = "https://example.com/project-pecking-order/index.pck"
    $template.release.tested_at_utc = [DateTimeOffset]::UtcNow.AddHours(-1).ToString("o")
    $template.release.coordinator = "Handoff Fixture Coordinator"
    $evidencePath = Join-Path $selfTestRoot "usability-playtest-evidence.json"
    $template |
        ConvertTo-Json -Depth 16 |
        Set-Content -LiteralPath $evidencePath -Encoding utf8

    $kitRoot = Join-Path $selfTestRoot "kits"
    $kitResult = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "new_usability_playtest_session_kit.ps1") `
        @(
            "-SessionId", "comprehension",
            "-EvidencePath", $evidencePath,
            "-OutputDirectory", $kitRoot
        )
    $comprehensionKit = Join-Path $kitRoot "comprehension"
    $kitFiles = @(
        "README.md",
        "session-brief.md",
        "session-result.json",
        "moderator-notes.md"
    )
    $kitBrief = if (Test-Path -LiteralPath (Join-Path $comprehensionKit "session-brief.md")) {
        Get-Content -LiteralPath (Join-Path $comprehensionKit "session-brief.md") -Raw
    }
    else {
        ""
    }
    $kitReadme = if (Test-Path -LiteralPath (Join-Path $comprehensionKit "README.md")) {
        Get-Content -LiteralPath (Join-Path $comprehensionKit "README.md") -Raw
    }
    else {
        ""
    }
    $kitSessionResult = if (
        Test-Path -LiteralPath (Join-Path $comprehensionKit "session-result.json")
    ) {
        Get-Content -LiteralPath (
            Join-Path $comprehensionKit "session-result.json"
        ) -Raw | ConvertFrom-Json
    }
    else {
        $null
    }
    $kitComplete = (
        $kitResult.exit_code -eq 0 -and
        @($kitFiles | Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $comprehensionKit $_) -PathType Leaf)
        }).Count -eq 0 -and
        $kitBrief -match [regex]::Escape($head) -and
        $kitBrief -match [regex]::Escape($pckHash) -and
        $kitReadme -match "register_usability_playtest_session\.ps1" -and
        $kitBrief -match [regex]::Escape('`external_instruction_count`') -and
        $kitReadme -match [regex]::Escape('`moderator-notes.md`') -and
        $kitReadme -match [regex]::Escape('~~~powershell') -and
        (Test-CleanGeneratedText $kitBrief) -and
        (Test-CleanGeneratedText $kitReadme) -and
        @($kitSessionResult.task_results).Count -eq 5 -and
        @(
            $kitSessionResult.task_results |
                Where-Object { $_.id -eq "recover-route-mistake" -and $_.critical }
        ).Count -eq 1
    )
    $checks["session-kit"] = [ordered]@{
        passed = $kitComplete
        exit_code = $kitResult.exit_code
        file_count = @($kitFiles | Where-Object {
            Test-Path -LiteralPath (Join-Path $comprehensionKit $_) -PathType Leaf
        }).Count
        task_count = @($kitSessionResult.task_results).Count
        identity_embedded = (
            $kitBrief -match [regex]::Escape($head) -and
            $kitBrief -match [regex]::Escape($pckHash)
        )
        markdown_clean = (
            $kitBrief -match [regex]::Escape('`external_instruction_count`') -and
            $kitReadme -match [regex]::Escape('`moderator-notes.md`') -and
            $kitReadme -match [regex]::Escape('~~~powershell') -and
            (Test-CleanGeneratedText $kitBrief) -and
            (Test-CleanGeneratedText $kitReadme)
        )
    }
    if (-not $kitComplete) {
        throw "Valid session kit generation failed: $($kitResult.output -join '; ')"
    }

    $resultPath = Join-Path $comprehensionKit "session-result.json"
    Complete-FixtureResult $resultPath "comprehension"
    $bundle = New-FixtureBundle "comprehension" $resultPath $selfTestRoot
    $registration = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "register_usability_playtest_session.ps1") `
        @(
            "-SessionId", "comprehension",
            "-ResultPath", $resultPath,
            "-BundlePath", $bundle,
            "-EvidencePath", $evidencePath
        )
    $registeredEvidence = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
    $registeredSession = @(
        $registeredEvidence.sessions | Where-Object { $_.id -eq "comprehension" }
    )[0]
    $registeredBundle = @($registeredSession.evidence)[0]
    $expectedHash = (
        Get-FileHash -LiteralPath $bundle -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    $registrationPassed = (
        $registration.exit_code -eq 0 -and
        [string]$registeredSession.status -eq "pass" -and
        [string]$registeredBundle.sha256 -eq $expectedHash -and
        [string]$registeredBundle.uri -match "comprehension-session-bundle\.zip$"
    )
    $checks["atomic-registration"] = [ordered]@{
        passed = $registrationPassed
        exit_code = $registration.exit_code
        hash_matches = [string]$registeredBundle.sha256 -eq $expectedHash
    }
    if (-not $registrationPassed) {
        throw "Valid session registration failed: $($registration.output -join '; ')"
    }

    $duplicate = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "register_usability_playtest_session.ps1") `
        @(
            "-SessionId", "comprehension",
            "-ResultPath", $resultPath,
            "-BundlePath", $bundle,
            "-EvidencePath", $evidencePath
        )
    $checks["duplicate-rejected"] = [ordered]@{
        passed = (
            $duplicate.exit_code -ne 0 -and
            ($duplicate.output -join " ") -match "already has registered evidence"
        )
        exit_code = $duplicate.exit_code
    }

    $frictionKitResult = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "new_usability_playtest_session_kit.ps1") `
        @(
            "-SessionId", "friction",
            "-EvidencePath", $evidencePath,
            "-OutputDirectory", $kitRoot
        )
    if ($frictionKitResult.exit_code -ne 0) {
        throw "Friction kit generation failed."
    }
    $frictionResultPath = Join-Path $kitRoot "friction\session-result.json"
    Complete-FixtureResult $frictionResultPath "friction"
    $invalidBundle = New-FixtureBundle `
        "friction" `
        $frictionResultPath `
        $selfTestRoot `
        -WithoutRecording
    $beforeInvalidAttempt = (
        Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256
    ).Hash
    $invalid = Invoke-ChildScript `
        (Join-Path $PSScriptRoot "register_usability_playtest_session.ps1") `
        @(
            "-SessionId", "friction",
            "-ResultPath", $frictionResultPath,
            "-BundlePath", $invalidBundle,
            "-EvidencePath", $evidencePath
        )
    $afterInvalidAttempt = (
        Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256
    ).Hash
    $checks["invalid-bundle-rejected-atomically"] = [ordered]@{
        passed = (
            $invalid.exit_code -ne 0 -and
            ($invalid.output -join " ") -match "session recording" -and
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
Write-Output "USABILITY_PLAYTEST_HANDOFF passed=$($result.passed) report=$absoluteReportPath"
if ($failed) {
    exit 1
}
