param(
    [string]$EvidencePath = "output\release\physical-release-evidence.json",
    [string]$ReportPath = "",
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$started = Get-Date

$sessionSpecs = [ordered]@{
    "touch-ios" = [ordered]@{
        kind = "touch"
        checks = @(
            "campaign-load",
            "first-clutch-touch-route",
            "all-eight-controls",
            "touch-controls-single-fire",
            "one-finger-pan",
            "pinch-zoom",
            "rotate-recover",
            "modal-focus-recovery",
            "backup-round-trip",
            "one-shift-sustained-flow",
            "safe-area-and-overflow",
            "status-feedback"
        )
    }
    "touch-android" = [ordered]@{
        kind = "touch"
        checks = @(
            "campaign-load",
            "first-clutch-touch-route",
            "all-eight-controls",
            "touch-controls-single-fire",
            "one-finger-pan",
            "pinch-zoom",
            "rotate-recover",
            "modal-focus-recovery",
            "backup-round-trip",
            "one-shift-sustained-flow",
            "safe-area-and-overflow",
            "status-feedback"
        )
    }
    "screen-reader-desktop" = [ordered]@{
        kind = "screen-reader"
        checks = @(
            "page-landmarks-and-names",
            "game-focus-summary",
            "live-status-sample",
            "notification-levels",
            "economic-decisions",
            "flockwatch-economic-equivalence",
            "backup-status",
            "no-raw-or-runaway-diagnostics"
        )
    }
    "screen-reader-mobile" = [ordered]@{
        kind = "screen-reader"
        checks = @(
            "page-landmarks-and-names",
            "mobile-controls-and-names",
            "game-focus-summary",
            "live-status-sample",
            "notification-levels",
            "economic-decisions",
            "flockwatch-economic-equivalence",
            "backup-status",
            "no-raw-or-runaway-diagnostics"
        )
    }
    "audio-listening" = [ordered]@{
        kind = "audio"
        checks = @(
            "independent-audio-buses",
            "five-semantic-cues",
            "redundant-non-audio-feedback",
            "focus-pause-resume",
            "sustained-mix-quality"
        )
    }
    "gpu-integrated" = [ordered]@{
        kind = "gpu"
        checks = @(
            "hardware-renderer",
            "balanced-warmup",
            "active-two-shift-route",
            "mature-office",
            "input-latency-sample",
            "no-context-loss",
            "no-progressive-degradation"
        )
        median_fps = 30.0
        one_percent_low_fps = 20.0
        p95_input_latency_ms = 250.0
        maximum_stall_ms = 1000.0
    }
    "gpu-discrete" = [ordered]@{
        kind = "gpu"
        checks = @(
            "hardware-renderer",
            "balanced-warmup",
            "active-two-shift-route",
            "mature-office",
            "input-latency-sample",
            "no-context-loss",
            "no-progressive-degradation"
        )
        median_fps = 55.0
        one_percent_low_fps = 40.0
        p95_input_latency_ms = 150.0
        maximum_stall_ms = 750.0
    }
}

function Get-Field {
    param(
        [object]$Object,
        [string]$Name
    )
    if ($null -eq $Object) {
        return $null
    }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Name)) {
            return $Object[$Name]
        }
        return $null
    }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

function Get-Items {
    param([object]$Value)
    if ($null -eq $Value) {
        return @()
    }
    return @($Value)
}

function Add-Issue {
    param(
        [System.Collections.Generic.List[string]]$Issues,
        [string]$Path,
        [string]$Message
    )
    [void]$Issues.Add("$Path`: $Message")
}

function Test-MeaningfulText {
    param([object]$Value)
    if ($null -eq $Value) {
        return $false
    }
    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $false
    }
    return $text -notmatch "(?i)\b(REPLACE|PENDING|TODO|TBD)\b"
}

function Require-MeaningfulText {
    param(
        [System.Collections.Generic.List[string]]$Issues,
        [object]$Object,
        [string]$Name,
        [string]$Path
    )
    if (-not (Test-MeaningfulText (Get-Field $Object $Name))) {
        Add-Issue $Issues "$Path.$Name" "must contain a non-placeholder value"
    }
}

function Test-IsoTimestamp {
    param([object]$Value)
    if (-not (Test-MeaningfulText $Value)) {
        return $false
    }
    $parsed = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse([string]$Value, [ref]$parsed)) {
        return $false
    }
    return [string]$Value -match "(Z|[+-]\d\d:\d\d)$"
}

function Get-Number {
    param(
        [object]$Object,
        [string]$Name
    )
    $value = Get-Field $Object $Name
    if ($null -eq $value) {
        return [double]::NaN
    }
    try {
        return [double]$value
    }
    catch {
        return [double]::NaN
    }
}

function Require-Minimum {
    param(
        [System.Collections.Generic.List[string]]$Issues,
        [object]$Object,
        [string]$Name,
        [double]$Minimum,
        [string]$Path
    )
    $value = Get-Number $Object $Name
    if ([double]::IsNaN($value) -or $value -lt $Minimum) {
        Add-Issue $Issues "$Path.$Name" "must be at least $Minimum"
    }
}

function Require-Maximum {
    param(
        [System.Collections.Generic.List[string]]$Issues,
        [object]$Object,
        [string]$Name,
        [double]$Maximum,
        [string]$Path
    )
    $value = Get-Number $Object $Name
    if ([double]::IsNaN($value) -or $value -gt $Maximum) {
        Add-Issue $Issues "$Path.$Name" "must be at most $Maximum"
    }
}

function Require-Zero {
    param(
        [System.Collections.Generic.List[string]]$Issues,
        [object]$Object,
        [string]$Name,
        [string]$Path
    )
    $value = Get-Number $Object $Name
    if ([double]::IsNaN($value) -or $value -ne 0.0) {
        Add-Issue $Issues "$Path.$Name" "must be zero"
    }
}

function Get-CurrentReleaseIdentity {
    $docsPck = Join-Path $root "docs\index.pck"
    $webPck = Join-Path $root "web\public\game\index.pck"
    if (-not (Test-Path -LiteralPath $docsPck)) {
        throw "Missing release payload: $docsPck"
    }
    if (-not (Test-Path -LiteralPath $webPck)) {
        throw "Missing release payload: $webPck"
    }
    $docsHash = (Get-FileHash -LiteralPath $docsPck -Algorithm SHA256).Hash
    $webHash = (Get-FileHash -LiteralPath $webPck -Algorithm SHA256).Hash
    if ($docsHash -ne $webHash) {
        throw "Release payload mismatch between docs/index.pck and web/public/game/index.pck"
    }
    $commit = (& git -C $root rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $commit -notmatch "^[0-9a-fA-F]{40}$") {
        throw "Unable to resolve the current Git commit."
    }
    return [ordered]@{
        commit_sha = $commit.ToLowerInvariant()
        pck_sha256 = $docsHash.ToLowerInvariant()
    }
}

function Test-PhysicalEvidence {
    param(
        [object]$Evidence,
        [object]$Identity
    )
    $issues = [System.Collections.Generic.List[string]]::new()
    if ((Get-Number $Evidence "schema_version") -ne 1.0) {
        Add-Issue $issues "schema_version" "must equal 1"
    }

    $release = Get-Field $Evidence "release"
    if ($null -eq $release) {
        Add-Issue $issues "release" "is required"
    }
    else {
        $commit = [string](Get-Field $release "commit_sha")
        if ($commit -notmatch "^[0-9a-fA-F]{40}$") {
            Add-Issue $issues "release.commit_sha" "must be a full 40-character Git SHA"
        }
        elseif ($commit.ToLowerInvariant() -ne [string]$Identity.commit_sha) {
            Add-Issue $issues "release.commit_sha" "does not match the checked-out commit $($Identity.commit_sha)"
        }
        $pckHash = [string](Get-Field $release "pck_sha256")
        if ($pckHash -notmatch "^[0-9a-fA-F]{64}$") {
            Add-Issue $issues "release.pck_sha256" "must be a 64-character SHA-256"
        }
        elseif ($pckHash.ToLowerInvariant() -ne [string]$Identity.pck_sha256) {
            Add-Issue $issues "release.pck_sha256" "does not match the shipped payload $($Identity.pck_sha256)"
        }
        $testedUrl = [string](Get-Field $release "tested_url")
        $parsedUrl = $null
        if (
            -not (Test-MeaningfulText $testedUrl) -or
            -not [Uri]::TryCreate($testedUrl, [UriKind]::Absolute, [ref]$parsedUrl) -or
            $parsedUrl.Scheme -ne "https"
        ) {
            Add-Issue $issues "release.tested_url" "must be a non-placeholder HTTPS URL"
        }
        if (-not (Test-IsoTimestamp (Get-Field $release "tested_at_utc"))) {
            Add-Issue $issues "release.tested_at_utc" "must be an ISO-8601 timestamp with an explicit UTC offset"
        }
        Require-MeaningfulText $issues $release "coordinator" "release"
    }

    $sessions = Get-Items (Get-Field $Evidence "sessions")
    $sessionsById = @{}
    foreach ($session in $sessions) {
        $sessionId = [string](Get-Field $session "id")
        if ([string]::IsNullOrWhiteSpace($sessionId)) {
            Add-Issue $issues "sessions" "contains a session without an id"
            continue
        }
        if ($sessionsById.ContainsKey($sessionId)) {
            Add-Issue $issues "sessions.$sessionId" "is duplicated"
            continue
        }
        $sessionsById[$sessionId] = $session
    }

    foreach ($sessionId in $sessionSpecs.Keys) {
        $spec = $sessionSpecs[$sessionId]
        if (-not $sessionsById.ContainsKey($sessionId)) {
            Add-Issue $issues "sessions.$sessionId" "required session is missing"
            continue
        }
        $session = $sessionsById[$sessionId]
        $sessionPath = "sessions.$sessionId"
        if ([string](Get-Field $session "status") -ne "pass") {
            Add-Issue $issues "$sessionPath.status" "must equal pass"
        }
        Require-MeaningfulText $issues $session "tester" $sessionPath
        if (-not (Test-IsoTimestamp (Get-Field $session "signed_at_utc"))) {
            Add-Issue $issues "$sessionPath.signed_at_utc" "must be an ISO-8601 timestamp with an explicit UTC offset"
        }

        $environment = Get-Field $session "environment"
        if ($null -eq $environment) {
            Add-Issue $issues "$sessionPath.environment" "is required"
        }
        else {
            if ((Get-Field $environment "physical_device") -ne $true) {
                Add-Issue $issues "$sessionPath.environment.physical_device" "must be true"
            }
            foreach ($field in @("device_model", "os_version", "browser", "browser_version")) {
                Require-MeaningfulText $issues $environment $field "$sessionPath.environment"
            }
            if ($spec.kind -eq "screen-reader") {
                foreach ($field in @("assistive_technology", "assistive_technology_version")) {
                    Require-MeaningfulText $issues $environment $field "$sessionPath.environment"
                }
            }
            elseif ($spec.kind -eq "audio") {
                foreach ($field in @("output_device", "listening_environment")) {
                    Require-MeaningfulText $issues $environment $field "$sessionPath.environment"
                }
            }
            elseif ($spec.kind -eq "gpu") {
                foreach ($field in @("gpu_model", "driver_version", "renderer_string")) {
                    Require-MeaningfulText $issues $environment $field "$sessionPath.environment"
                }
                if ((Get-Field $environment "hardware_accelerated") -ne $true) {
                    Add-Issue $issues "$sessionPath.environment.hardware_accelerated" "must be true"
                }
                $renderer = [string](Get-Field $environment "renderer_string")
                if ($renderer -match "(?i)(SwiftShader|software|llvmpipe|Microsoft Basic|virtual monitor|virtual display)") {
                    Add-Issue $issues "$sessionPath.environment.renderer_string" "names a software or virtual renderer"
                }
            }
        }

        $checkResults = Get-Field $session "check_results"
        if ($null -eq $checkResults) {
            Add-Issue $issues "$sessionPath.check_results" "is required"
        }
        else {
            foreach ($checkId in $spec.checks) {
                if ([string](Get-Field $checkResults $checkId) -ne "pass") {
                    Add-Issue $issues "$sessionPath.check_results.$checkId" "must equal pass"
                }
            }
            if ($checkResults -is [System.Collections.IDictionary]) {
                foreach ($checkId in $checkResults.Keys) {
                    if ([string]$checkResults[$checkId] -ne "pass") {
                        Add-Issue $issues "$sessionPath.check_results.$checkId" "contains a non-pass result"
                    }
                }
            }
            else {
                foreach ($property in $checkResults.PSObject.Properties) {
                    if ([string]$property.Value -ne "pass") {
                        Add-Issue $issues "$sessionPath.check_results.$($property.Name)" "contains a non-pass result"
                    }
                }
            }
        }

        $metrics = Get-Field $session "metrics"
        if ($null -eq $metrics) {
            Add-Issue $issues "$sessionPath.metrics" "is required"
        }
        elseif ($spec.kind -eq "touch") {
            Require-Minimum $issues $metrics "single_fire_attempts" 20 $sessionPath
            Require-Zero $issues $metrics "single_fire_failures" $sessionPath
            Require-Minimum $issues $metrics "pan_attempts" 10 $sessionPath
            Require-Zero $issues $metrics "pan_failures" $sessionPath
            Require-Minimum $issues $metrics "pinch_attempts" 10 $sessionPath
            Require-Zero $issues $metrics "pinch_failures" $sessionPath
            Require-Minimum $issues $metrics "rotation_cycles" 5 $sessionPath
            Require-Zero $issues $metrics "rotation_failures" $sessionPath
        }
        elseif ($spec.kind -eq "screen-reader") {
            Require-Minimum $issues $metrics "announcement_samples" 10 $sessionPath
            Require-Minimum $issues $metrics "economic_decisions_completed" 3 $sessionPath
            Require-Zero $issues $metrics "raw_diagnostic_announcements" $sessionPath
            Require-Zero $issues $metrics "runaway_repetitions" $sessionPath
        }
        elseif ($spec.kind -eq "audio") {
            Require-Minimum $issues $metrics "listening_minutes" 15 $sessionPath
            Require-Minimum $issues $metrics "focus_cycles" 5 $sessionPath
            Require-Zero $issues $metrics "clipping_incidents" $sessionPath
            Require-Zero $issues $metrics "stuck_loop_incidents" $sessionPath
        }
        elseif ($spec.kind -eq "gpu") {
            Require-Minimum $issues $metrics "resolution_width" 1920 $sessionPath
            Require-Minimum $issues $metrics "resolution_height" 1080 $sessionPath
            if ([string](Get-Field $metrics "visual_quality") -ne "balanced") {
                Add-Issue $issues "$sessionPath.metrics.visual_quality" "must equal balanced"
            }
            Require-Minimum $issues $metrics "sample_seconds" 600 $sessionPath
            Require-Minimum $issues $metrics "input_samples" 20 $sessionPath
            Require-Minimum $issues $metrics "median_fps" ([double]$spec.median_fps) $sessionPath
            Require-Minimum $issues $metrics "one_percent_low_fps" ([double]$spec.one_percent_low_fps) $sessionPath
            Require-Maximum $issues $metrics "p95_input_latency_ms" ([double]$spec.p95_input_latency_ms) $sessionPath
            Require-Maximum $issues $metrics "maximum_stall_ms" ([double]$spec.maximum_stall_ms) $sessionPath
            Require-Minimum $issues $metrics "end_to_start_fps_ratio" 0.8 $sessionPath
            Require-Zero $issues $metrics "context_losses" $sessionPath
        }

        $evidenceItems = Get-Items (Get-Field $session "evidence")
        if ($evidenceItems.Count -lt 1) {
            Add-Issue $issues "$sessionPath.evidence" "must contain at least one immutable evidence bundle"
        }
        foreach ($item in $evidenceItems) {
            Require-MeaningfulText $issues $item "type" "$sessionPath.evidence"
            Require-MeaningfulText $issues $item "uri" "$sessionPath.evidence"
            $evidenceHash = [string](Get-Field $item "sha256")
            if ($evidenceHash -notmatch "^[0-9a-fA-F]{64}$") {
                Add-Issue $issues "$sessionPath.evidence.sha256" "must be a 64-character SHA-256"
            }
        }
        if ((Get-Items (Get-Field $session "blocking_issues")).Count -ne 0) {
            Add-Issue $issues "$sessionPath.blocking_issues" "must be empty for a passing session"
        }
    }

    foreach ($sessionId in $sessionsById.Keys) {
        if (-not $sessionSpecs.Contains($sessionId)) {
            Add-Issue $issues "sessions.$sessionId" "is not a recognized required session"
        }
    }

    $decision = Get-Field $Evidence "decision"
    if ($null -eq $decision) {
        Add-Issue $issues "decision" "is required"
    }
    else {
        if ([string](Get-Field $decision "status") -ne "pass") {
            Add-Issue $issues "decision.status" "must equal pass"
        }
        Require-MeaningfulText $issues $decision "approved_by" "decision"
        if (-not (Test-IsoTimestamp (Get-Field $decision "approved_at_utc"))) {
            Add-Issue $issues "decision.approved_at_utc" "must be an ISO-8601 timestamp with an explicit UTC offset"
        }
        Require-Zero $issues $decision "open_p0_issues" "decision"
        Require-Zero $issues $decision "open_p1_issues" "decision"
    }

    return $issues.ToArray()
}

function New-PassingCheckResults {
    param([object[]]$CheckIds)
    $result = [ordered]@{}
    foreach ($checkId in $CheckIds) {
        $result[[string]$checkId] = "pass"
    }
    return $result
}

function New-SelfTestEvidence {
    param([object]$Identity)
    $timestamp = (Get-Date).ToUniversalTime().ToString("o")
    $protocolPath = Join-Path $root "docs\PHYSICAL_RELEASE_ACCEPTANCE.md"
    $protocolHash = (Get-FileHash -LiteralPath $protocolPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $sessions = @()
    foreach ($sessionId in $sessionSpecs.Keys) {
        $spec = $sessionSpecs[$sessionId]
        $environment = [ordered]@{
            physical_device = $true
            device_model = "Contract self-test device"
            os_version = "Contract self-test OS"
            browser = "Contract self-test browser"
            browser_version = "1"
        }
        if ($spec.kind -eq "screen-reader") {
            $environment.assistive_technology = "Contract self-test reader"
            $environment.assistive_technology_version = "1"
        }
        elseif ($spec.kind -eq "audio") {
            $environment.output_device = "Contract self-test speakers"
            $environment.listening_environment = "Contract self-test room"
        }
        elseif ($spec.kind -eq "gpu") {
            $environment.gpu_model = "Contract self-test physical GPU"
            $environment.driver_version = "1"
            $environment.hardware_accelerated = $true
            $environment.renderer_string = "Contract self-test physical GPU renderer"
        }

        if ($spec.kind -eq "touch") {
            $metrics = [ordered]@{
                single_fire_attempts = 20
                single_fire_failures = 0
                pan_attempts = 10
                pan_failures = 0
                pinch_attempts = 10
                pinch_failures = 0
                rotation_cycles = 5
                rotation_failures = 0
            }
        }
        elseif ($spec.kind -eq "screen-reader") {
            $metrics = [ordered]@{
                announcement_samples = 10
                economic_decisions_completed = 3
                raw_diagnostic_announcements = 0
                runaway_repetitions = 0
            }
        }
        elseif ($spec.kind -eq "audio") {
            $metrics = [ordered]@{
                listening_minutes = 15
                focus_cycles = 5
                clipping_incidents = 0
                stuck_loop_incidents = 0
            }
        }
        else {
            $metrics = [ordered]@{
                resolution_width = 1920
                resolution_height = 1080
                visual_quality = "balanced"
                sample_seconds = 600
                input_samples = 20
                median_fps = [double]$spec.median_fps
                one_percent_low_fps = [double]$spec.one_percent_low_fps
                p95_input_latency_ms = [double]$spec.p95_input_latency_ms
                maximum_stall_ms = [double]$spec.maximum_stall_ms
                end_to_start_fps_ratio = 0.8
                context_losses = 0
            }
        }

        $sessions += [ordered]@{
            id = $sessionId
            status = "pass"
            tester = "Contract self-test"
            signed_at_utc = $timestamp
            environment = $environment
            check_results = New-PassingCheckResults $spec.checks
            metrics = $metrics
            evidence = @(
                [ordered]@{
                    type = "contract"
                    uri = "docs/PHYSICAL_RELEASE_ACCEPTANCE.md"
                    sha256 = $protocolHash
                }
            )
            blocking_issues = @()
            notes = "Synthetic validator contract only; not release evidence."
        }
    }
    return [ordered]@{
        schema_version = 1
        release = [ordered]@{
            commit_sha = $Identity.commit_sha
            pck_sha256 = $Identity.pck_sha256
            tested_url = "https://pecking-order.invalid/contract-self-test"
            tested_at_utc = $timestamp
            coordinator = "Contract self-test"
        }
        sessions = $sessions
        decision = [ordered]@{
            status = "pass"
            approved_by = "Contract self-test"
            approved_at_utc = $timestamp
            open_p0_issues = 0
            open_p1_issues = 0
            accepted_p2_issues = @()
        }
    }
}

$identity = Get-CurrentReleaseIdentity
$mode = if ($SelfTest) { "contract-self-test" } else { "physical-release-evidence" }
$errors = @()
$selfTestInvalidErrorCount = $null

if ($SelfTest) {
    $validFixture = New-SelfTestEvidence $identity
    $validErrors = @(Test-PhysicalEvidence $validFixture $identity)
    $invalidFixture = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $invalidFixture.decision.status = "pending"
    $invalidErrors = @(Test-PhysicalEvidence $invalidFixture $identity)
    $selfTestInvalidErrorCount = $invalidErrors.Count
    if ($validErrors.Count -ne 0) {
        $errors += @($validErrors | ForEach-Object { "valid fixture rejected: $_" })
    }
    if ($invalidErrors.Count -eq 0) {
        $errors += "invalid fixture was accepted"
    }
}
else {
    $absoluteEvidencePath = if ([IO.Path]::IsPathRooted($EvidencePath)) {
        $EvidencePath
    }
    else {
        Join-Path $root $EvidencePath
    }
    if (-not (Test-Path -LiteralPath $absoluteEvidencePath)) {
        $errors += "evidence file not found: $absoluteEvidencePath"
    }
    else {
        try {
            $evidence = Get-Content -LiteralPath $absoluteEvidencePath -Raw | ConvertFrom-Json
            $errors += @(Test-PhysicalEvidence $evidence $identity)
        }
        catch {
            $errors += "evidence could not be parsed or validated: $($_.Exception.Message)"
        }
    }
}

$result = [ordered]@{
    passed = $errors.Count -eq 0
    mode = $mode
    generated_at = (Get-Date).ToUniversalTime().ToString("o")
    duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
    current_release = $identity
    evidence_path = if ($SelfTest) { $null } else { $EvidencePath }
    self_test_invalid_error_count = $selfTestInvalidErrorCount
    errors = @($errors)
}

if ([string]::IsNullOrWhiteSpace($ReportPath)) {
    $ReportPath = if ($SelfTest) {
        "output\release\physical-release-validator-self-test.json"
    }
    else {
        "output\release\physical-release-evidence-validation.json"
    }
}
$absoluteReportPath = if ([IO.Path]::IsPathRooted($ReportPath)) {
    $ReportPath
}
else {
    Join-Path $root $ReportPath
}
New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteReportPath) -Force | Out-Null
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $absoluteReportPath -Encoding utf8
Write-Output "PHYSICAL_RELEASE_EVIDENCE passed=$($result.passed) mode=$mode report=$absoluteReportPath"
if (-not $result.passed) {
    foreach ($issue in $errors) {
        Write-Output "  $issue"
    }
    exit 1
}
