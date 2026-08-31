param(
    [string]$EvidencePath = "output\release\usability-playtest-evidence.json",
    [string]$ReportPath = "output\release\usability-playtest-validation.json",
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "usability_playtest_bundle.ps1")

$focusDefinitions = [ordered]@{
    "comprehension" = @{ min_minutes = 20; min_tasks = 5; min_completion = 0.80 }
    "friction" = @{ min_minutes = 20; min_tasks = 8; min_completion = 0.85 }
    "pacing" = @{ min_minutes = 30; min_tasks = 5; min_completion = 0.80 }
    "fun" = @{ min_minutes = 30; min_tasks = 5; min_completion = 0.80 }
    "strategic-depth" = @{ min_minutes = 45; min_tasks = 6; min_completion = 0.80 }
    "feedback-clarity" = @{ min_minutes = 20; min_tasks = 7; min_completion = 0.80 }
    "long-session-fatigue" = @{ min_minutes = 90; min_tasks = 5; min_completion = 0.80 }
}
$commonCapabilityIds = @(
    "find-current-priority",
    "explain-economic-change",
    "complete-economic-action",
    "recover-from-mistake"
)

function Test-MeaningfulText {
    param([AllowNull()][object]$Value)
    $text = [string]$Value
    return (
        -not [string]::IsNullOrWhiteSpace($text) -and
        $text -notmatch "(?i)(^|[^A-Z0-9])(REPLACE|PENDING|TODO|TBD)(_|[^A-Z0-9]|$)"
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
    $rootPath = [IO.Path]::GetFullPath($root).TrimEnd([char[]]"\/")
    $prefix = $rootPath + [IO.Path]::DirectorySeparatorChar
    if (
        $absolute -ne $rootPath -and
        -not $absolute.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
    ) {
        throw "Path must remain inside the repository: $Path"
    }
    return $absolute
}

function Get-UtcTimestamp {
    param(
        [AllowNull()][object]$Value,
        [string]$Label,
        [System.Collections.Generic.List[string]]$Issues
    )
    $parsed = [DateTimeOffset]::MinValue
    if (
        -not (Test-MeaningfulText $Value) -or
        -not [DateTimeOffset]::TryParse(
            [string]$Value,
            [Globalization.CultureInfo]::InvariantCulture,
            [Globalization.DateTimeStyles]::AssumeUniversal,
            [ref]$parsed
        )
    ) {
        [void]$Issues.Add("$Label must be a non-placeholder ISO-8601 timestamp.")
        return $null
    }
    if ($parsed -gt [DateTimeOffset]::UtcNow.AddMinutes(5)) {
        [void]$Issues.Add("$Label may not be more than five minutes in the future.")
    }
    return $parsed.ToUniversalTime()
}

function Get-PlaytestEvidenceIssues {
    param(
        [Parameter(Mandatory = $true)][object]$Evidence,
        [switch]$Fixture
    )
    $issues = [System.Collections.Generic.List[string]]::new()
    if ([int]$Evidence.schema_version -ne 1) {
        [void]$issues.Add("schema_version must be 1.")
    }

    $head = (& git -C $root rev-parse HEAD).Trim().ToLowerInvariant()
    $commit = [string]$Evidence.release.commit_sha
    if ($commit -notmatch "^[0-9a-fA-F]{40}$") {
        [void]$issues.Add("release.commit_sha must be a full 40-character Git SHA.")
    }
    elseif (-not $Fixture -and $commit.ToLowerInvariant() -ne $head) {
        [void]$issues.Add("release.commit_sha does not match the checked-out commit.")
    }

    $docsPck = Join-Path $root "docs\index.pck"
    $webPck = Join-Path $root "web\public\game\index.pck"
    if (
        -not (Test-Path -LiteralPath $docsPck -PathType Leaf) -or
        -not (Test-Path -LiteralPath $webPck -PathType Leaf)
    ) {
        [void]$issues.Add("both shipped index.pck files must exist.")
    }
    else {
        $docsHash = (Get-FileHash -LiteralPath $docsPck -Algorithm SHA256).Hash
        $webHash = (Get-FileHash -LiteralPath $webPck -Algorithm SHA256).Hash
        $recordedHash = [string]$Evidence.release.pck_sha256
        if ($docsHash -ne $webHash) {
            [void]$issues.Add("shipped index.pck files do not match.")
        }
        if (
            $recordedHash -notmatch "^[0-9a-fA-F]{64}$" -or
            (-not $Fixture -and $recordedHash.ToUpperInvariant() -ne $docsHash)
        ) {
            [void]$issues.Add("release.pck_sha256 does not match the shipped payload.")
        }
    }

    $testedUrl = $null
    if (
        -not (Test-MeaningfulText $Evidence.release.tested_url) -or
        -not [Uri]::TryCreate(
            [string]$Evidence.release.tested_url,
            [UriKind]::Absolute,
            [ref]$testedUrl
        ) -or
        $testedUrl.Scheme -ne "https" -or
        -not $testedUrl.AbsolutePath.EndsWith("/") -or
        -not [string]::IsNullOrEmpty($testedUrl.Query) -or
        -not [string]::IsNullOrEmpty($testedUrl.Fragment)
    ) {
        [void]$issues.Add("release.tested_url must be a query-free HTTPS root ending in /.")
    }
    else {
        $expectedPckUrl = [Uri]::new($testedUrl, "index.pck").AbsoluteUri
        if ([string]$Evidence.release.pck_url -ne $expectedPckUrl) {
            [void]$issues.Add("release.pck_url must be the tested root's exact index.pck URL.")
        }
    }
    if (-not (Test-MeaningfulText $Evidence.release.coordinator)) {
        [void]$issues.Add("release.coordinator must name the research coordinator.")
    }
    $releaseTime = Get-UtcTimestamp `
        $Evidence.release.tested_at_utc `
        "release.tested_at_utc" `
        $issues

    $sessions = @($Evidence.sessions)
    if ($sessions.Count -ne $focusDefinitions.Count) {
        [void]$issues.Add("sessions must contain exactly seven focus sessions.")
    }
    $sessionIds = @($sessions | ForEach-Object { [string]$_.id })
    foreach ($requiredId in $focusDefinitions.Keys) {
        if (@($sessionIds | Where-Object { $_ -eq $requiredId }).Count -ne 1) {
            [void]$issues.Add("sessions must contain exactly one '$requiredId' session.")
        }
    }
    if (@($sessionIds | Select-Object -Unique).Count -ne $sessionIds.Count) {
        [void]$issues.Add("session IDs must be unique.")
    }

    $usedEvidenceUris = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::OrdinalIgnoreCase
    )
    $latestSessionTime = $releaseTime
    foreach ($session in $sessions) {
        $id = [string]$session.id
        if (-not $focusDefinitions.Contains($id)) {
            [void]$issues.Add("unknown session ID '$id'.")
            continue
        }
        $definition = $focusDefinitions[$id]
        if ([string]$session.status -ne "pass") {
            [void]$issues.Add("$id.status must be pass.")
        }
        if (-not (Test-MeaningfulText $session.tester)) {
            [void]$issues.Add("$id.tester must name the tester.")
        }
        if ($session.independent_tester -ne $true) {
            [void]$issues.Add("$id.independent_tester must be true.")
        }
        if ($session.consent_to_record -ne $true) {
            [void]$issues.Add("$id.consent_to_record must be true.")
        }
        if ([string]$session.experience -notin @("new", "returning", "expert")) {
            [void]$issues.Add("$id.experience must be new, returning, or expert.")
        }
        $sessionTime = Get-UtcTimestamp `
            $session.signed_at_utc `
            "$id.signed_at_utc" `
            $issues
        if ($null -ne $sessionTime) {
            if ($null -ne $releaseTime -and $sessionTime -lt $releaseTime) {
                [void]$issues.Add("$id.signed_at_utc must follow release initialization.")
            }
            if ($null -eq $latestSessionTime -or $sessionTime -gt $latestSessionTime) {
                $latestSessionTime = $sessionTime
            }
        }

        $metrics = $session.metrics
        $taskResults = @($session.task_results)
        $taskIds = @($taskResults | ForEach-Object { [string]$_.id })
        if ($taskResults.Count -lt [int]$definition.min_tasks) {
            [void]$issues.Add("$id.task_results needs at least $($definition.min_tasks) tasks.")
        }
        if (@($taskIds | Select-Object -Unique).Count -ne $taskIds.Count) {
            [void]$issues.Add("$id.task_results IDs must be unique.")
        }
        $completedUnaided = 0
        $criticalAttempted = 0
        $criticalCompletedUnaided = 0
        foreach ($task in $taskResults) {
            if (-not (Test-MeaningfulText $task.id)) {
                [void]$issues.Add("$id has a task with a placeholder ID.")
            }
            if ([string]$task.outcome -notin @("pass", "fail", "blocked")) {
                [void]$issues.Add("$id task '$($task.id)' has an invalid outcome.")
            }
            if ([double]$task.elapsed_seconds -lt 0) {
                [void]$issues.Add("$id task '$($task.id)' has negative elapsed_seconds.")
            }
            if ([int]$task.external_instruction_count -lt 0) {
                [void]$issues.Add("$id task '$($task.id)' has a negative instruction count.")
            }
            $unaidedPass = (
                [string]$task.outcome -eq "pass" -and
                $task.completed_unaided -eq $true -and
                [int]$task.external_instruction_count -eq 0
            )
            if ($unaidedPass) {
                $completedUnaided += 1
            }
            if ($task.critical -eq $true) {
                $criticalAttempted += 1
                if ($unaidedPass) {
                    $criticalCompletedUnaided += 1
                }
            }
        }
        if ([int]$metrics.tasks_attempted -ne $taskResults.Count) {
            [void]$issues.Add("$id.metrics.tasks_attempted must equal the task log count.")
        }
        if ([int]$metrics.tasks_completed_unaided -ne $completedUnaided) {
            [void]$issues.Add("$id.metrics.tasks_completed_unaided must equal the unaided pass count.")
        }
        if (
            [int]$metrics.critical_tasks_attempted -ne $criticalAttempted -or
            [int]$metrics.critical_tasks_completed_unaided -ne $criticalCompletedUnaided
        ) {
            [void]$issues.Add("$id critical-task metrics must equal the task log.")
        }
        if ($criticalAttempted -lt 1 -or $criticalCompletedUnaided -ne $criticalAttempted) {
            [void]$issues.Add("$id must complete every critical task unaided.")
        }
        $completionRate = if ($taskResults.Count -gt 0) {
            $completedUnaided / [double]$taskResults.Count
        }
        else {
            0.0
        }
        if ($completionRate -lt [double]$definition.min_completion) {
            [void]$issues.Add("$id unaided task completion is below $($definition.min_completion).")
        }
        if ([double]$metrics.session_minutes -lt [double]$definition.min_minutes) {
            [void]$issues.Add("$id.metrics.session_minutes is below $($definition.min_minutes).")
        }
        foreach ($rateName in @(
            "information_find_rate",
            "change_explanation_rate",
            "mistake_recovery_rate"
        )) {
            $rate = [double]$metrics.$rateName
            if ($rate -lt 0.80 -or $rate -gt 1.0) {
                [void]$issues.Add("$id.metrics.$rateName must be between 0.80 and 1.0.")
            }
        }
        if ([int]$metrics.external_instruction_count -ne 0) {
            [void]$issues.Add("$id.metrics.external_instruction_count must be zero.")
        }
        if (
            [double]$metrics.focus_rating_1_to_7 -lt 5 -or
            [double]$metrics.focus_rating_1_to_7 -gt 7
        ) {
            [void]$issues.Add("$id.metrics.focus_rating_1_to_7 must be between 5 and 7.")
        }
        foreach ($capabilityId in $commonCapabilityIds) {
            $capabilityValue = if (
                $session.common_capabilities -is [Collections.IDictionary]
            ) {
                $session.common_capabilities[$capabilityId]
            }
            else {
                $property = (
                    $session.common_capabilities.PSObject.Properties[$capabilityId]
                )
                if ($null -eq $property) { $null } else { $property.Value }
            }
            if ([string]$capabilityValue -ne "pass") {
                [void]$issues.Add("$id.common_capabilities.$capabilityId must be pass.")
            }
        }
        if (
            $id -eq "pacing" -and
            [int]$metrics.decisionless_waits_over_30_seconds -ne 0
        ) {
            [void]$issues.Add("pacing must have zero decisionless waits over 30 seconds.")
        }
        if ($id -eq "fun") {
            if ([int]$metrics.enjoyable_moments -lt 3) {
                [void]$issues.Add("fun needs at least three enjoyable moments.")
            }
            if ($metrics.would_continue -ne $true) {
                [void]$issues.Add("fun.would_continue must be true.")
            }
        }
        if ($id -eq "strategic-depth") {
            if ([int]$metrics.distinct_strategies_attempted -lt 2) {
                [void]$issues.Add("strategic-depth needs at least two distinct strategies.")
            }
            if ([int]$metrics.reasoned_economic_choices -lt 8) {
                [void]$issues.Add("strategic-depth needs at least eight reasoned economic choices.")
            }
            if ([int]$metrics.evidence_based_adaptations -lt 2) {
                [void]$issues.Add("strategic-depth needs at least two evidence-based adaptations.")
            }
        }
        if ($id -eq "long-session-fatigue") {
            if (
                [double]$metrics.fatigue_rating_1_to_7 -lt 1 -or
                [double]$metrics.fatigue_rating_1_to_7 -gt 3
            ) {
                [void]$issues.Add("long-session-fatigue rating must be between 1 and 3.")
            }
            if ([int]$metrics.low_value_repetitive_chores -gt 3) {
                [void]$issues.Add("long-session-fatigue has more than three low-value chores.")
            }
            if ($metrics.would_continue -ne $true) {
                [void]$issues.Add("long-session-fatigue.would_continue must be true.")
            }
        }
        if (@($session.blocking_issues).Count -ne 0) {
            [void]$issues.Add("$id.blocking_issues must be empty for a passing session.")
        }
        if (-not (Test-MeaningfulText $session.notes)) {
            [void]$issues.Add("$id.notes must contain the tester rationale and observations.")
        }

        $bundleRows = @(
            @($session.evidence) |
                Where-Object { [string]$_.type -eq "session-bundle" }
        )
        if ($bundleRows.Count -ne 1) {
            [void]$issues.Add("$id.evidence must contain exactly one session-bundle.")
            continue
        }
        $bundleRow = $bundleRows[0]
        $uri = [string]$bundleRow.uri
        if (-not (Test-MeaningfulText $uri)) {
            [void]$issues.Add("$id evidence URI is a placeholder.")
            continue
        }
        if (-not $usedEvidenceUris.Add($uri)) {
            [void]$issues.Add("$id evidence URI must be unique across sessions.")
        }
        if ([string]$bundleRow.sha256 -notmatch "^[0-9a-fA-F]{64}$") {
            [void]$issues.Add("$id evidence SHA-256 is malformed.")
            continue
        }
        $bundlePath = $null
        $temporaryDownload = $null
        try {
            $absoluteUri = $null
            if (
                [Uri]::TryCreate($uri, [UriKind]::Absolute, [ref]$absoluteUri) -and
                $absoluteUri.Scheme -eq "https"
            ) {
                if (
                    -not $absoluteUri.AbsolutePath.EndsWith(
                        ".zip",
                        [StringComparison]::OrdinalIgnoreCase
                    ) -or
                    -not [string]::IsNullOrEmpty($absoluteUri.Query) -or
                    -not [string]::IsNullOrEmpty($absoluteUri.Fragment)
                ) {
                    throw "HTTPS evidence must be a query-free ZIP object URL."
                }
                if (
                    [IO.Path]::GetFileNameWithoutExtension(
                        $absoluteUri.AbsolutePath
                    ).IndexOf(
                        $id,
                        [StringComparison]::OrdinalIgnoreCase
                    ) -lt 0
                ) {
                    throw "HTTPS evidence ZIP filename must include session ID '$id'."
                }
                $temporaryDownload = Join-Path (
                    [IO.Path]::GetTempPath()
                ) (
                    "pecking-order-$id-$([Guid]::NewGuid().ToString('N')).zip"
                )
                Invoke-WebRequest `
                    -Uri $absoluteUri `
                    -OutFile $temporaryDownload `
                    -TimeoutSec 180 `
                    -Headers @{ "User-Agent" = "Pecking-Order-Playtest-Validator" }
                $bundlePath = $temporaryDownload
            }
            elseif ([IO.Path]::IsPathRooted($uri)) {
                [void]$issues.Add("$id evidence URI must be repository-relative or HTTPS.")
            }
            else {
                $bundlePath = Get-RepositoryPath $uri
            }
            if ($null -ne $bundlePath) {
                if (-not (Test-Path -LiteralPath $bundlePath -PathType Leaf)) {
                    [void]$issues.Add("$id evidence bundle does not exist.")
                }
                else {
                    $actualHash = (
                        Get-FileHash -LiteralPath $bundlePath -Algorithm SHA256
                    ).Hash
                    if ($actualHash -ne ([string]$bundleRow.sha256).ToUpperInvariant()) {
                        [void]$issues.Add("$id evidence SHA-256 does not match the bundle.")
                    }
                    foreach ($bundleIssue in @(
                        Get-UsabilityPlaytestBundleIssues $bundlePath $id
                    )) {
                        [void]$issues.Add("$id $bundleIssue.")
                    }
                }
            }
        }
        catch {
            [void]$issues.Add("$id evidence bundle could not be verified: $($_.Exception.Message)")
        }
        finally {
            if (
                $null -ne $temporaryDownload -and
                (Test-Path -LiteralPath $temporaryDownload -PathType Leaf)
            ) {
                Remove-Item -LiteralPath $temporaryDownload -Force
            }
        }
    }

    if ([string]$Evidence.decision.status -ne "pass") {
        [void]$issues.Add("decision.status must be pass.")
    }
    if (-not (Test-MeaningfulText $Evidence.decision.approved_by)) {
        [void]$issues.Add("decision.approved_by must name the release owner.")
    }
    $approvalTime = Get-UtcTimestamp `
        $Evidence.decision.approved_at_utc `
        "decision.approved_at_utc" `
        $issues
    if (
        $null -ne $approvalTime -and
        $null -ne $latestSessionTime -and
        $approvalTime -lt $latestSessionTime
    ) {
        [void]$issues.Add("decision approval must follow every signed session.")
    }
    if ([int]$Evidence.decision.open_p0_issues -ne 0) {
        [void]$issues.Add("decision.open_p0_issues must be zero.")
    }
    if ([int]$Evidence.decision.open_p1_issues -ne 0) {
        [void]$issues.Add("decision.open_p1_issues must be zero.")
    }
    return @($issues)
}

function New-SelfTestBundle {
    param(
        [string]$SessionId,
        [string]$Directory
    )
    $source = Join-Path $Directory "$SessionId-source"
    New-Item -ItemType Directory -Path $source -Force | Out-Null
    [IO.File]::WriteAllBytes(
        (Join-Path $source "session.webm"),
        [byte[]](1, 2, 3, 4)
    )
    '{"tasks":"recorded"}' |
        Set-Content -LiteralPath (Join-Path $source "task-log.json") -Encoding utf8
    "Tester rationale and moderator observations." |
        Set-Content -LiteralPath (Join-Path $source "moderator-notes.md") -Encoding utf8
    $zip = Join-Path $Directory "$SessionId-session-bundle.zip"
    [IO.Compression.ZipFile]::CreateFromDirectory($source, $zip)
    return $zip
}

function Invoke-SelfTest {
    $selfTestRoot = Get-RepositoryPath (
        "output\release\usability-playtest-validator-self-test-" +
        [Guid]::NewGuid().ToString("N")
    )
    New-Item -ItemType Directory -Path $selfTestRoot -Force | Out-Null
    try {
        $head = (& git -C $root rev-parse HEAD).Trim().ToLowerInvariant()
        $pckHash = (
            Get-FileHash -LiteralPath (Join-Path $root "docs\index.pck") -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        $releaseTime = [DateTimeOffset]::UtcNow.AddHours(-3)
        $sessions = @()
        $sessionIndex = 0
        foreach ($id in $focusDefinitions.Keys) {
            $definition = $focusDefinitions[$id]
            $bundle = New-SelfTestBundle $id $selfTestRoot
            $repositoryPrefix = (
                [IO.Path]::GetFullPath($root).TrimEnd([char[]]"\/") +
                [IO.Path]::DirectorySeparatorChar
            )
            $relativeBundle = $bundle.Substring(
                $repositoryPrefix.Length
            ).Replace("\", "/")
            $tasks = @()
            for ($taskIndex = 0; $taskIndex -lt [int]$definition.min_tasks; $taskIndex++) {
                $tasks += [ordered]@{
                    id = "$id-task-$($taskIndex + 1)"
                    outcome = "pass"
                    critical = $taskIndex -eq 0
                    completed_unaided = $true
                    elapsed_seconds = 45 + $taskIndex
                    external_instruction_count = 0
                }
            }
            $metrics = [ordered]@{
                session_minutes = [int]$definition.min_minutes
                tasks_attempted = $tasks.Count
                tasks_completed_unaided = $tasks.Count
                critical_tasks_attempted = 1
                critical_tasks_completed_unaided = 1
                information_find_rate = 0.9
                change_explanation_rate = 0.9
                mistake_recovery_rate = 1.0
                external_instruction_count = 0
                focus_rating_1_to_7 = 6
                distinct_strategies_attempted = if ($id -eq "strategic-depth") { 2 } else { 0 }
                reasoned_economic_choices = if ($id -eq "strategic-depth") { 8 } else { 0 }
                evidence_based_adaptations = if ($id -eq "strategic-depth") { 2 } else { 0 }
                decisionless_waits_over_30_seconds = 0
                enjoyable_moments = if ($id -eq "fun") { 3 } else { 0 }
                would_continue = $id -in @("fun", "long-session-fatigue")
                fatigue_rating_1_to_7 = if ($id -eq "long-session-fatigue") { 3 } else { 0 }
                low_value_repetitive_chores = 1
            }
            $sessions += [ordered]@{
                id = $id
                status = "pass"
                tester = "Fixture Tester $sessionIndex"
                signed_at_utc = $releaseTime.AddMinutes(5 + $sessionIndex).ToString("o")
                independent_tester = $true
                consent_to_record = $true
                experience = if ($id -in @("strategic-depth", "long-session-fatigue")) {
                    "returning"
                }
                else {
                    "new"
                }
                metrics = $metrics
                common_capabilities = [ordered]@{
                    "find-current-priority" = "pass"
                    "explain-economic-change" = "pass"
                    "complete-economic-action" = "pass"
                    "recover-from-mistake" = "pass"
                }
                task_results = $tasks
                evidence = @(
                    [ordered]@{
                        type = "session-bundle"
                        uri = $relativeBundle
                        sha256 = (
                            Get-FileHash -LiteralPath $bundle -Algorithm SHA256
                        ).Hash.ToLowerInvariant()
                    }
                )
                blocking_issues = @()
                notes = "Observed route, player rationale, and issue review recorded."
            }
            $sessionIndex += 1
        }
        $fixture = [ordered]@{
            schema_version = 1
            release = [ordered]@{
                commit_sha = $head
                pck_sha256 = $pckHash
                tested_url = "https://example.com/project-pecking-order/"
                pck_url = "https://example.com/project-pecking-order/index.pck"
                tested_at_utc = $releaseTime.ToString("o")
                coordinator = "Fixture Coordinator"
            }
            sessions = $sessions
            decision = [ordered]@{
                status = "pass"
                approved_by = "Fixture Release Owner"
                approved_at_utc = $releaseTime.AddHours(2).ToString("o")
                open_p0_issues = 0
                open_p1_issues = 0
                accepted_p2_issues = @()
            }
        }
        $validIssues = @(Get-PlaytestEvidenceIssues $fixture -Fixture)
        $cases = @()

        $mutations = @(
            @{
                name = "missing-session"
                expected = "exactly seven|exactly one"
                mutate = { param($copy) $copy.sessions = @($copy.sessions | Select-Object -First 6) }
            },
            @{
                name = "short-session"
                expected = "session_minutes"
                mutate = { param($copy) $copy.sessions[0].metrics.session_minutes = 1 }
            },
            @{
                name = "assisted-critical-task"
                expected = "critical task unaided|completed_unaided"
                mutate = {
                    param($copy)
                    $copy.sessions[0].task_results[0].completed_unaided = $false
                }
            },
            @{
                name = "mismatched-bundle-hash"
                expected = "SHA-256 does not match"
                mutate = { param($copy) $copy.sessions[0].evidence[0].sha256 = ("0" * 64) }
            },
            @{
                name = "duplicate-evidence"
                expected = "unique across sessions|filename must include"
                mutate = {
                    param($copy)
                    $copy.sessions[1].evidence[0].uri = $copy.sessions[0].evidence[0].uri
                    $copy.sessions[1].evidence[0].sha256 = $copy.sessions[0].evidence[0].sha256
                }
            },
            @{
                name = "mutable-remote-evidence"
                expected = "query-free ZIP object URL"
                mutate = {
                    param($copy)
                    $copy.sessions[0].evidence[0].uri = "https://example.com/shared-folder"
                }
            },
            @{
                name = "misidentified-remote-evidence"
                expected = "filename must include session ID"
                mutate = {
                    param($copy)
                    $copy.sessions[0].evidence[0].uri = "https://example.com/immutable-evidence.zip"
                }
            },
            @{
                name = "open-blocker"
                expected = "blocking_issues"
                mutate = { param($copy) $copy.sessions[0].blocking_issues = @("P1-1") }
            },
            @{
                name = "unsigned-decision"
                expected = "approved_by"
                mutate = { param($copy) $copy.decision.approved_by = "REPLACE_WITH_OWNER" }
            }
        )
        foreach ($mutation in $mutations) {
            $copy = (
                $fixture | ConvertTo-Json -Depth 16 | ConvertFrom-Json
            )
            & $mutation.mutate $copy
            $mutationIssues = @(Get-PlaytestEvidenceIssues $copy -Fixture)
            $targeted = @(
                $mutationIssues | Where-Object { $_ -match $mutation.expected }
            ).Count -gt 0
            $cases += [ordered]@{
                name = $mutation.name
                rejected = $mutationIssues.Count -gt 0
                targeted_reason = $targeted
                issue_count = $mutationIssues.Count
            }
        }
        $passed = (
            $validIssues.Count -eq 0 -and
            @($cases | Where-Object {
                -not $_.rejected -or -not $_.targeted_reason
            }).Count -eq 0
        )
        return [ordered]@{
            passed = $passed
            valid_fixture_issue_count = $validIssues.Count
            valid_fixture_issues = $validIssues
            adversarial_cases = $cases
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
}

$started = Get-Date
if ($SelfTest) {
    $selfTestResult = Invoke-SelfTest
    $result = [ordered]@{
        passed = [bool]$selfTestResult.passed
        mode = "self-test"
        generated_at = [DateTimeOffset]::UtcNow.ToString("o")
        duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
        contract = $selfTestResult
    }
}
else {
    $absoluteEvidencePath = Get-RepositoryPath $EvidencePath
    if (-not (Test-Path -LiteralPath $absoluteEvidencePath -PathType Leaf)) {
        $issues = @("evidence file does not exist: $absoluteEvidencePath")
    }
    else {
        try {
            $evidence = Get-Content -LiteralPath $absoluteEvidencePath -Raw |
                ConvertFrom-Json
            $issues = @(Get-PlaytestEvidenceIssues $evidence)
        }
        catch {
            $issues = @("evidence file could not be parsed: $($_.Exception.Message)")
        }
    }
    $result = [ordered]@{
        passed = $issues.Count -eq 0
        mode = "evidence"
        generated_at = [DateTimeOffset]::UtcNow.ToString("o")
        duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
        evidence_path = $absoluteEvidencePath
        issue_count = $issues.Count
        issues = $issues
    }
}

$absoluteReportPath = Get-RepositoryPath $ReportPath
New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteReportPath) -Force |
    Out-Null
$result |
    ConvertTo-Json -Depth 16 |
    Set-Content -LiteralPath $absoluteReportPath -Encoding utf8
Write-Output (
    "USABILITY_PLAYTEST_VALIDATION passed={0} mode={1} report={2}" -f
    $result.passed,
    $result.mode,
    $absoluteReportPath
)
if (-not $result.passed) {
    if ($result.PSObject.Properties["issues"]) {
        $result.issues | ForEach-Object { Write-Output "  - $_" }
    }
    exit 1
}
