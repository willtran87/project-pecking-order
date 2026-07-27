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
        browser_pattern = "(?i)\bSafari\b"
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
            "text-legibility",
            "status-feedback"
        )
    }
    "touch-android" = [ordered]@{
        kind = "touch"
        browser_pattern = "(?i)\bChrome\b"
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
            "text-legibility",
            "status-feedback"
        )
    }
    "screen-reader-desktop" = [ordered]@{
        kind = "screen-reader"
        assistive_technology_pattern = "(?i)\b(NVDA|VoiceOver)\b"
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
        assistive_technology_pattern = "(?i)\b(VoiceOver|TalkBack)\b"
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
        return ,([object[]]@())
    }
    # Keep a one-item JSON array as an array. PowerShell otherwise unwraps it
    # while returning from this helper, which makes `.Count` disappear from a
    # lone PSCustomObject and falsely reports the evidence bundle as missing.
    return ,([object[]]@($Value))
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
    # Template tokens use underscores (for example REPLACE_WITH_TESTER), which
    # are word characters and therefore evade a conventional `\b` boundary.
    return $text -notmatch "(?i)(^|[^A-Z0-9])(REPLACE|PENDING|TODO|TBD)(_|[^A-Z0-9]|$)"
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

function Convert-IsoTimestamp {
    param([object]$Value)
    if (-not (Test-IsoTimestamp $Value)) {
        return $null
    }
    return [DateTimeOffset]::Parse([string]$Value)
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

function Test-EvidenceReference {
    param(
        [System.Collections.Generic.List[string]]$Issues,
        [object]$Item,
        [string]$Path
    )
    Require-MeaningfulText $Issues $Item "type" $Path
    Require-MeaningfulText $Issues $Item "uri" $Path

    $evidenceHash = [string](Get-Field $Item "sha256")
    $hashIsValid = $evidenceHash -match "^[0-9a-fA-F]{64}$"
    if (-not $hashIsValid) {
        Add-Issue $Issues "$Path.sha256" "must be a 64-character SHA-256"
    }

    $uriText = [string](Get-Field $Item "uri")
    if (-not (Test-MeaningfulText $uriText)) {
        return
    }

    $absoluteUri = $null
    if ([Uri]::TryCreate($uriText, [UriKind]::Absolute, [ref]$absoluteUri)) {
        if ($absoluteUri.Scheme -ne "https") {
            Add-Issue $Issues "$Path.uri" "must be a repository-relative file or immutable HTTPS URL"
        }
        return
    }

    if ([IO.Path]::IsPathRooted($uriText)) {
        Add-Issue $Issues "$Path.uri" "must not be an absolute local path"
        return
    }

    try {
        $rootPath = [IO.Path]::GetFullPath($root)
        $rootPrefix = $rootPath.TrimEnd([char[]]"\/") + [IO.Path]::DirectorySeparatorChar
        $evidencePath = [IO.Path]::GetFullPath((Join-Path $rootPath $uriText))
        if (-not $evidencePath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            Add-Issue $Issues "$Path.uri" "escapes the repository root"
            return
        }
        if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
            Add-Issue $Issues "$Path.uri" "does not reference an existing evidence file"
            return
        }
        if ($hashIsValid) {
            $actualHash = (Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256).Hash
            if ($actualHash -ne $evidenceHash) {
                Add-Issue $Issues "$Path.sha256" "does not match the referenced evidence file"
            }
        }
    }
    catch {
        Add-Issue $Issues "$Path.uri" "could not be resolved safely: $($_.Exception.Message)"
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
    $latestAllowedTimestamp = [DateTimeOffset]::UtcNow.AddMinutes(5)
    $testedAt = $null
    $latestSessionSignedAt = [DateTimeOffset]::MinValue
    if ((Get-Number $Evidence "schema_version") -ne 2.0) {
        Add-Issue $issues "schema_version" "must equal 2"
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
        $testedAt = Convert-IsoTimestamp (Get-Field $release "tested_at_utc")
        if ($null -eq $testedAt) {
            Add-Issue $issues "release.tested_at_utc" "must be an ISO-8601 timestamp with an explicit UTC offset"
        }
        elseif ($testedAt -gt $latestAllowedTimestamp) {
            Add-Issue $issues "release.tested_at_utc" "must not be in the future"
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
        $sessionSignedAt = Convert-IsoTimestamp (Get-Field $session "signed_at_utc")
        if ($null -eq $sessionSignedAt) {
            Add-Issue $issues "$sessionPath.signed_at_utc" "must be an ISO-8601 timestamp with an explicit UTC offset"
        }
        else {
            if ($null -ne $testedAt -and $sessionSignedAt -lt $testedAt) {
                Add-Issue $issues "$sessionPath.signed_at_utc" "must not precede release.tested_at_utc"
            }
            if ($sessionSignedAt -gt $latestAllowedTimestamp) {
                Add-Issue $issues "$sessionPath.signed_at_utc" "must not be in the future"
            }
            if ($sessionSignedAt -gt $latestSessionSignedAt) {
                $latestSessionSignedAt = $sessionSignedAt
            }
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
            if (
                $spec.Contains("browser_pattern") -and
                [string](Get-Field $environment "browser") -notmatch [string]$spec.browser_pattern
            ) {
                Add-Issue $issues "$sessionPath.environment.browser" "does not match the required physical browser"
            }
            if ($spec.kind -eq "screen-reader") {
                foreach ($field in @("assistive_technology", "assistive_technology_version")) {
                    Require-MeaningfulText $issues $environment $field "$sessionPath.environment"
                }
                if (
                    [string](Get-Field $environment "assistive_technology") -notmatch
                    [string]$spec.assistive_technology_pattern
                ) {
                    Add-Issue $issues "$sessionPath.environment.assistive_technology" "does not match the required reader"
                }
            }
            elseif ($spec.kind -eq "audio") {
                foreach ($field in @("output_device", "listening_environment")) {
                    Require-MeaningfulText $issues $environment $field "$sessionPath.environment"
                }
            }
            elseif ($spec.kind -eq "gpu") {
                foreach ($field in @("gpu_class", "gpu_model", "driver_version", "renderer_string")) {
                    Require-MeaningfulText $issues $environment $field "$sessionPath.environment"
                }
                $requiredGpuClass = if ($sessionId -eq "gpu-integrated") {
                    "integrated"
                }
                else {
                    "discrete"
                }
                if ([string](Get-Field $environment "gpu_class") -ne $requiredGpuClass) {
                    Add-Issue $issues "$sessionPath.environment.gpu_class" "must equal $requiredGpuClass"
                }
                if ((Get-Field $environment "hardware_accelerated") -ne $true) {
                    Add-Issue $issues "$sessionPath.environment.hardware_accelerated" "must be true"
                }
                $renderer = [string](Get-Field $environment "renderer_string")
                if (
                    $renderer -match
                    "(?i)(SwiftShader|software|llvmpipe|Microsoft Basic|virtual|VMware|Parallels|Citrix|Remote Desktop|VirGL)"
                ) {
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
                    if (
                        $checkId -notin $spec.checks -and
                        [string]$checkResults[$checkId] -ne "pass"
                    ) {
                        Add-Issue $issues "$sessionPath.check_results.$checkId" "contains a non-pass result"
                    }
                }
            }
            else {
                foreach ($property in $checkResults.PSObject.Properties) {
                    if (
                        $property.Name -notin $spec.checks -and
                        [string]$property.Value -ne "pass"
                    ) {
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
            Require-Minimum $issues $metrics "minimum_control_width_css_px" 44 $sessionPath
            Require-Minimum $issues $metrics "minimum_control_height_css_px" 44 $sessionPath
            Require-Maximum $issues $metrics "maximum_orientation_recovery_seconds" 2 $sessionPath
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
            Require-Minimum $issues $metrics "audio_buses_verified" 5 $sessionPath
            Require-Minimum $issues $metrics "semantic_cues_identified" 5 $sessionPath
            Require-Zero $issues $metrics "clipping_incidents" $sessionPath
            Require-Zero $issues $metrics "stuck_loop_incidents" $sessionPath
        }
        elseif ($spec.kind -eq "gpu") {
            Require-Minimum $issues $metrics "resolution_width" 1920 $sessionPath
            Require-Minimum $issues $metrics "resolution_height" 1080 $sessionPath
            Require-Minimum $issues $metrics "display_refresh_hz" 60 $sessionPath
            if ([string](Get-Field $metrics "visual_quality") -ne "balanced") {
                Add-Issue $issues "$sessionPath.metrics.visual_quality" "must equal balanced"
            }
            Require-Minimum $issues $metrics "warmup_seconds" 60 $sessionPath
            Require-Minimum $issues $metrics "sample_seconds" 600 $sessionPath
            Require-Minimum $issues $metrics "initial_window_seconds" 120 $sessionPath
            Require-Minimum $issues $metrics "final_window_seconds" 120 $sessionPath
            Require-Minimum $issues $metrics "input_samples" 20 $sessionPath
            Require-Minimum $issues $metrics "median_fps" ([double]$spec.median_fps) $sessionPath
            Require-Minimum $issues $metrics "one_percent_low_fps" ([double]$spec.one_percent_low_fps) $sessionPath
            Require-Maximum $issues $metrics "p95_input_latency_ms" ([double]$spec.p95_input_latency_ms) $sessionPath
            Require-Maximum $issues $metrics "maximum_stall_ms" ([double]$spec.maximum_stall_ms) $sessionPath
            Require-Minimum $issues $metrics "end_to_start_fps_ratio" 0.8 $sessionPath
            Require-Minimum $issues $metrics "initial_window_median_fps" 0.001 $sessionPath
            Require-Minimum $issues $metrics "final_window_median_fps" 0.001 $sessionPath
            $initialMedianFps = Get-Number $metrics "initial_window_median_fps"
            $finalMedianFps = Get-Number $metrics "final_window_median_fps"
            $declaredRatio = Get-Number $metrics "end_to_start_fps_ratio"
            if (
                -not [double]::IsNaN($initialMedianFps) -and
                -not [double]::IsNaN($finalMedianFps) -and
                -not [double]::IsNaN($declaredRatio) -and
                $initialMedianFps -gt 0
            ) {
                $calculatedRatio = $finalMedianFps / $initialMedianFps
                if ([Math]::Abs($calculatedRatio - $declaredRatio) -gt 0.01) {
                    Add-Issue $issues "$sessionPath.metrics.end_to_start_fps_ratio" "does not match the recorded window medians"
                }
            }
            Require-Zero $issues $metrics "context_losses" $sessionPath
        }

        $evidenceItems = Get-Items (Get-Field $session "evidence")
        if ($evidenceItems.Count -lt 1) {
            Add-Issue $issues "$sessionPath.evidence" "must contain at least one immutable evidence bundle"
        }
        $evidenceUris = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($item in $evidenceItems) {
            Test-EvidenceReference $issues $item "$sessionPath.evidence"
            $evidenceUri = [string](Get-Field $item "uri")
            if (
                (Test-MeaningfulText $evidenceUri) -and
                -not $evidenceUris.Add($evidenceUri)
            ) {
                Add-Issue $issues "$sessionPath.evidence.uri" "is duplicated"
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
        $approvedAt = Convert-IsoTimestamp (Get-Field $decision "approved_at_utc")
        if ($null -eq $approvedAt) {
            Add-Issue $issues "decision.approved_at_utc" "must be an ISO-8601 timestamp with an explicit UTC offset"
        }
        else {
            if ($approvedAt -lt $latestSessionSignedAt) {
                Add-Issue $issues "decision.approved_at_utc" "must not precede any signed session"
            }
            if ($approvedAt -gt $latestAllowedTimestamp) {
                Add-Issue $issues "decision.approved_at_utc" "must not be in the future"
            }
        }
        Require-Zero $issues $decision "open_p0_issues" "decision"
        Require-Zero $issues $decision "open_p1_issues" "decision"
        foreach ($issueId in (Get-Items (Get-Field $decision "accepted_p2_issues"))) {
            if (-not (Test-MeaningfulText $issueId)) {
                Add-Issue $issues "decision.accepted_p2_issues" "contains an empty or placeholder issue ID"
            }
        }
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
            browser = if ($sessionId -in @("touch-ios", "screen-reader-mobile")) {
                "Safari"
            }
            elseif ($sessionId -eq "touch-android") {
                "Chrome"
            }
            else {
                "Contract self-test browser"
            }
            browser_version = "1"
        }
        if ($spec.kind -eq "screen-reader") {
            $environment.assistive_technology = if ($sessionId -eq "screen-reader-desktop") {
                "NVDA"
            }
            else {
                "VoiceOver"
            }
            $environment.assistive_technology_version = "1"
        }
        elseif ($spec.kind -eq "audio") {
            $environment.output_device = "Contract self-test speakers"
            $environment.listening_environment = "Contract self-test room"
        }
        elseif ($spec.kind -eq "gpu") {
            $environment.gpu_class = if ($sessionId -eq "gpu-integrated") {
                "integrated"
            }
            else {
                "discrete"
            }
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
                minimum_control_width_css_px = 44
                minimum_control_height_css_px = 44
                maximum_orientation_recovery_seconds = 2
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
                audio_buses_verified = 5
                semantic_cues_identified = 5
                clipping_incidents = 0
                stuck_loop_incidents = 0
            }
        }
        else {
            $metrics = [ordered]@{
                resolution_width = 1920
                resolution_height = 1080
                display_refresh_hz = 60
                visual_quality = "balanced"
                warmup_seconds = 60
                sample_seconds = 600
                initial_window_seconds = 120
                final_window_seconds = 120
                input_samples = 20
                median_fps = [double]$spec.median_fps
                one_percent_low_fps = [double]$spec.one_percent_low_fps
                p95_input_latency_ms = [double]$spec.p95_input_latency_ms
                maximum_stall_ms = [double]$spec.maximum_stall_ms
                end_to_start_fps_ratio = 0.8
                initial_window_median_fps = [double]$spec.median_fps
                final_window_median_fps = [double]$spec.median_fps * 0.8
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
        schema_version = 2
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
$selfTestInvalidCaseCount = $null

if ($SelfTest) {
    $validFixture = New-SelfTestEvidence $identity
    $validErrors = @(Test-PhysicalEvidence $validFixture $identity)
    if ($validErrors.Count -ne 0) {
        $errors += @($validErrors | ForEach-Object { "valid fixture rejected: $_" })
    }

    $invalidFixtures = @()

    $pendingDecision = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $pendingDecision.decision.status = "pending"
    $invalidFixtures += [ordered]@{
        name = "pending decision"
        evidence = $pendingDecision
        expected = "decision.status"
    }

    $wrongEvidenceHash = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $wrongEvidenceHash.sessions[0].evidence[0].sha256 = ("0" * 64)
    $invalidFixtures += [ordered]@{
        name = "mismatched local evidence hash"
        evidence = $wrongEvidenceHash
        expected = "does not match the referenced evidence file"
    }

    $missingEvidenceFile = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $missingEvidenceFile.sessions[0].evidence[0].uri =
        "output/release/missing-physical-evidence-bundle.zip"
    $invalidFixtures += [ordered]@{
        name = "missing local evidence file"
        evidence = $missingEvidenceFile
        expected = "does not reference an existing evidence file"
    }

    $escapingEvidencePath = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $escapingEvidencePath.sessions[0].evidence[0].uri =
        "../outside-physical-evidence-bundle.zip"
    $invalidFixtures += [ordered]@{
        name = "repository traversal"
        evidence = $escapingEvidencePath
        expected = "escapes the repository root"
    }

    $softwareRenderer = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $softwareGpuSession = @(
        $softwareRenderer.sessions | Where-Object { $_.id -eq "gpu-discrete" }
    )[0]
    $softwareGpuSession.environment.renderer_string = "ANGLE SwiftShader"
    $invalidFixtures += [ordered]@{
        name = "software GPU renderer"
        evidence = $softwareRenderer
        expected = "names a software or virtual renderer"
    }

    $failedTouchAttempt = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $touchSession = @(
        $failedTouchAttempt.sessions | Where-Object { $_.id -eq "touch-ios" }
    )[0]
    $touchSession.metrics.single_fire_failures = 1
    $invalidFixtures += [ordered]@{
        name = "failed physical touch attempt"
        evidence = $failedTouchAttempt
        expected = "single_fire_failures"
    }

    $wrongTouchBrowser = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $iosSession = @(
        $wrongTouchBrowser.sessions | Where-Object { $_.id -eq "touch-ios" }
    )[0]
    $iosSession.environment.browser = "Chrome"
    $invalidFixtures += [ordered]@{
        name = "wrong iOS browser"
        evidence = $wrongTouchBrowser
        expected = "does not match the required physical browser"
    }

    $wrongReader = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $desktopReaderSession = @(
        $wrongReader.sessions | Where-Object { $_.id -eq "screen-reader-desktop" }
    )[0]
    $desktopReaderSession.environment.assistive_technology = "TalkBack"
    $invalidFixtures += [ordered]@{
        name = "wrong desktop assistive technology"
        evidence = $wrongReader
        expected = "does not match the required reader"
    }

    $wrongGpuClass = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $integratedGpuSession = @(
        $wrongGpuClass.sessions | Where-Object { $_.id -eq "gpu-integrated" }
    )[0]
    $integratedGpuSession.environment.gpu_class = "discrete"
    $invalidFixtures += [ordered]@{
        name = "wrong GPU class"
        evidence = $wrongGpuClass
        expected = "environment.gpu_class"
    }

    $shortGpuWarmup = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $shortWarmupSession = @(
        $shortGpuWarmup.sessions | Where-Object { $_.id -eq "gpu-discrete" }
    )[0]
    $shortWarmupSession.metrics.warmup_seconds = 59
    $invalidFixtures += [ordered]@{
        name = "incomplete GPU warmup"
        evidence = $shortGpuWarmup
        expected = "warmup_seconds"
    }

    $inconsistentFpsRatio = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $ratioSession = @(
        $inconsistentFpsRatio.sessions | Where-Object { $_.id -eq "gpu-discrete" }
    )[0]
    $ratioSession.metrics.end_to_start_fps_ratio = 0.95
    $invalidFixtures += [ordered]@{
        name = "inconsistent GPU window ratio"
        evidence = $inconsistentFpsRatio
        expected = "does not match the recorded window medians"
    }

    $prematureApproval = ($validFixture | ConvertTo-Json -Depth 12 | ConvertFrom-Json)
    $approvalTime = [DateTimeOffset]::Parse(
        [string]$prematureApproval.decision.approved_at_utc
    )
    $prematureApproval.decision.approved_at_utc =
        $approvalTime.AddMinutes(-1).ToString("o")
    $invalidFixtures += [ordered]@{
        name = "approval before signed sessions"
        evidence = $prematureApproval
        expected = "must not precede any signed session"
    }

    $selfTestInvalidCaseCount = $invalidFixtures.Count
    $selfTestInvalidErrorCount = 0
    foreach ($invalidCase in $invalidFixtures) {
        $invalidErrors = @(
            Test-PhysicalEvidence $invalidCase.evidence $identity
        )
        $selfTestInvalidErrorCount += $invalidErrors.Count
        if ($invalidErrors.Count -eq 0) {
            $errors += "invalid fixture accepted: $($invalidCase.name)"
            continue
        }
        if (-not ($invalidErrors -match [regex]::Escape([string]$invalidCase.expected))) {
            $errors +=
                "invalid fixture did not report '$($invalidCase.expected)': $($invalidCase.name)"
        }
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
    self_test_invalid_case_count = $selfTestInvalidCaseCount
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
