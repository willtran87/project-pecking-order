param(
    [string]$OutputPath = "output\release\release-readiness-current.json",
    [string]$MarkdownPath = "output\release\release-readiness-current.md",
    [string]$PhysicalEvidencePath = "output\release\physical-release-evidence.json",
    [string]$UsabilityEvidencePath = "output\release\usability-playtest-evidence.json",
    [string]$BetaGatePath = "output\release\beta-release-gate.json",
    [switch]$RequireReleaseReady,
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$started = Get-Date

$physicalSessionIds = @(
    "touch-ios",
    "touch-android",
    "screen-reader-desktop",
    "screen-reader-mobile",
    "audio-listening",
    "gpu-integrated",
    "gpu-discrete"
)
$usabilitySessionIds = @(
    "comprehension",
    "friction",
    "pacing",
    "fun",
    "strategic-depth",
    "feedback-clarity",
    "long-session-fatigue"
)
$releaseFiles = @(
    "index.apple-touch-icon.png",
    "index.audio.position.worklet.js",
    "index.audio.worklet.js",
    "index.html",
    "index.icon.png",
    "index.js",
    "index.pck",
    "index.png",
    "index.wasm"
)
$pckLocations = @(
    "web/public/game/index.pck",
    "web/dist/client/game/index.pck",
    "web/dist/index.pck",
    "dist/index.pck",
    "dist/client/game/index.pck",
    "docs/index.pck"
)

function Get-RepositoryPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ([IO.Path]::IsPathRooted($Path)) {
        return [IO.Path]::GetFullPath($Path)
    }
    return [IO.Path]::GetFullPath((Join-Path $root $Path))
}

function Get-RelativeRepositoryPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    $absolute = [IO.Path]::GetFullPath($Path)
    $rootPrefix = [IO.Path]::GetFullPath($root).TrimEnd('\') + '\'
    if ($absolute.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        return $absolute.Substring($rootPrefix.Length).Replace('\', '/')
    }
    return $absolute
}

function Get-FileIdentity {
    param([Parameter(Mandatory = $true)][string]$Path)
    $absolute = Get-RepositoryPath $Path
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        return [ordered]@{
            path = (Get-RelativeRepositoryPath $absolute)
            exists = $false
            bytes = 0
            sha256 = ""
            modified_at_utc = $null
        }
    }
    $item = Get-Item -LiteralPath $absolute
    return [ordered]@{
        path = (Get-RelativeRepositoryPath $absolute)
        exists = $true
        bytes = [long]$item.Length
        sha256 = (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash.ToLowerInvariant()
        modified_at_utc = $item.LastWriteTimeUtc.ToString("o")
    }
}

function Get-GitValue {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $value = @(& git -C $root @Arguments 2>$null)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
    return ($value -join "`n").Trim()
}

function Get-DecisionStatus {
    param([AllowNull()][object]$Evidence)
    if ($null -eq $Evidence -or $null -eq $Evidence.decision) {
        return "missing"
    }
    $status = [string]$Evidence.decision.status
    if ([string]::IsNullOrWhiteSpace($status)) {
        return "missing"
    }
    return $status.ToLowerInvariant()
}

function Get-EvidenceSummary {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$RequiredSessionIds,
        [Parameter(Mandatory = $true)][string]$CommitSha,
        [Parameter(Mandatory = $true)][string]$PckSha256
    )
    $absolute = Get-RepositoryPath $Path
    $summary = [ordered]@{
        path = (Get-RelativeRepositoryPath $absolute)
        exists = $false
        sha256 = ""
        commit_matches = $false
        pck_matches = $false
        identity_matches = $false
        required_session_count = $RequiredSessionIds.Count
        passed_session_count = 0
        pending_session_ids = @($RequiredSessionIds)
        decision_status = "missing"
        ready = $false
        parse_error = ""
    }
    if (-not (Test-Path -LiteralPath $absolute -PathType Leaf)) {
        return $summary
    }
    $summary.exists = $true
    $summary.sha256 = (Get-FileHash -LiteralPath $absolute -Algorithm SHA256).Hash.ToLowerInvariant()
    try {
        $evidence = Get-Content -LiteralPath $absolute -Raw | ConvertFrom-Json
        $recordedCommit = [string]$evidence.release.commit_sha
        $recordedPck = [string]$evidence.release.pck_sha256
        $summary.commit_matches = $recordedCommit.ToLowerInvariant() -eq $CommitSha.ToLowerInvariant()
        $summary.pck_matches = $recordedPck.ToLowerInvariant() -eq $PckSha256.ToLowerInvariant()
        $summary.identity_matches = $summary.commit_matches -and $summary.pck_matches
        $pending = @()
        foreach ($sessionId in $RequiredSessionIds) {
            $session = @($evidence.sessions | Where-Object { [string]$_.id -eq $sessionId }) | Select-Object -First 1
            if ($null -eq $session -or [string]$session.status -ne "pass") {
                $pending += $sessionId
            }
        }
        $summary.passed_session_count = $RequiredSessionIds.Count - $pending.Count
        $summary.pending_session_ids = @($pending)
        $summary.decision_status = Get-DecisionStatus $evidence
        $summary.ready = (
            $summary.identity_matches -and
            $pending.Count -eq 0 -and
            $summary.decision_status -eq "pass"
        )
    }
    catch {
        $summary.parse_error = $_.Exception.Message
    }
    return $summary
}

function Add-Blocker {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][Collections.Generic.List[object]]$Blockers,
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Category,
        [Parameter(Mandatory = $true)][string]$Detail,
        [Parameter(Mandatory = $true)][string]$NextAction
    )
    $Blockers.Add([ordered]@{
        id = $Id
        category = $Category
        detail = $Detail
        next_action = $NextAction
    }) | Out-Null
}

Push-Location $root
try {
    $commitSha = Get-GitValue @("rev-parse", "HEAD")
    $branch = Get-GitValue @("branch", "--show-current")
    $statusText = Get-GitValue @("status", "--porcelain=v1")
    $statusLines = @($statusText -split "`n" | Where-Object { $_ -ne "" })
    $trackedChanges = @($statusLines | Where-Object { -not $_.StartsWith("?? ") })
    $sourceUntracked = @(
        $statusLines | Where-Object {
            $_.StartsWith("?? ") -and
            -not $_.Substring(3).Replace('\', '/').StartsWith("output/") -and
            -not $_.Substring(3).Replace('\', '/').StartsWith("dist/")
        }
    )
    $sourceWorktreeClean = $trackedChanges.Count -eq 0 -and $sourceUntracked.Count -eq 0

    $docsPck = Get-FileIdentity "docs/index.pck"
    if (-not $docsPck.exists) {
        throw "Missing authoritative shipping payload: docs/index.pck"
    }

    $payloadParity = @()
    $payloadParityPassed = $true
    foreach ($fileName in $releaseFiles) {
        $docsIdentity = Get-FileIdentity ("docs/" + $fileName)
        $webIdentity = Get-FileIdentity ("web/public/game/" + $fileName)
        $matches = (
            $docsIdentity.exists -and
            $webIdentity.exists -and
            $docsIdentity.bytes -eq $webIdentity.bytes -and
            $docsIdentity.sha256 -eq $webIdentity.sha256
        )
        if (-not $matches) {
            $payloadParityPassed = $false
        }
        $payloadParity += [ordered]@{
            name = $fileName
            matches = $matches
            docs = $docsIdentity
            web_public = $webIdentity
        }
    }

    $pckParity = @()
    $pckParityPassed = $true
    foreach ($pckPath in $pckLocations) {
        $identity = Get-FileIdentity $pckPath
        $matches = (
            $identity.exists -and
            $identity.bytes -eq $docsPck.bytes -and
            $identity.sha256 -eq $docsPck.sha256
        )
        if (-not $matches) {
            $pckParityPassed = $false
        }
        $pckParity += [ordered]@{
            path = $identity.path
            exists = $identity.exists
            bytes = $identity.bytes
            sha256 = $identity.sha256
            matches_authoritative = $matches
        }
    }

    $betaGateAbsolute = Get-RepositoryPath $BetaGatePath
    $betaGate = [ordered]@{
        path = (Get-RelativeRepositoryPath $betaGateAbsolute)
        exists = $false
        passed = $false
        generated_at = $null
        sha256 = ""
        current_for_payload = $false
    }
    if (Test-Path -LiteralPath $betaGateAbsolute -PathType Leaf) {
        $betaGate.exists = $true
        $betaGate.sha256 = (Get-FileHash -LiteralPath $betaGateAbsolute -Algorithm SHA256).Hash.ToLowerInvariant()
        try {
            $betaRecord = Get-Content -LiteralPath $betaGateAbsolute -Raw | ConvertFrom-Json
            $betaGate.passed = [bool]$betaRecord.passed
            $betaGate.generated_at = [string]$betaRecord.generated_at
            $gateItem = Get-Item -LiteralPath $betaGateAbsolute
            $pckItem = Get-Item -LiteralPath (Get-RepositoryPath "docs/index.pck")
            $betaGate.current_for_payload = $betaGate.passed -and $gateItem.LastWriteTimeUtc -ge $pckItem.LastWriteTimeUtc
        }
        catch {
            $betaGate.parse_error = $_.Exception.Message
        }
    }

    $physical = Get-EvidenceSummary `
        -Path $PhysicalEvidencePath `
        -RequiredSessionIds $physicalSessionIds `
        -CommitSha $commitSha `
        -PckSha256 $docsPck.sha256
    $usability = Get-EvidenceSummary `
        -Path $UsabilityEvidencePath `
        -RequiredSessionIds $usabilitySessionIds `
        -CommitSha $commitSha `
        -PckSha256 $docsPck.sha256

    $blockers = [Collections.Generic.List[object]]::new()
    if (-not $sourceWorktreeClean) {
        Add-Blocker $blockers "candidate-not-frozen" "candidate" `
            "The source worktree has $($trackedChanges.Count) tracked and $($sourceUntracked.Count) source-relevant untracked changes." `
            "Commit or deliberately remove every candidate source change, then regenerate this report."
    }
    if (-not $payloadParityPassed -or -not $pckParityPassed) {
        Add-Blocker $blockers "artifact-parity" "artifacts" `
            "One or more shipping payloads differ or are missing." `
            "Re-export and synchronize every release payload before testing the candidate."
    }
    if (-not $betaGate.current_for_payload) {
        Add-Blocker $blockers "automated-gate-stale" "automation" `
            "The configured automated release gate is missing, failed, or older than the authoritative PCK." `
            "Run tools/verify_beta_release.ps1 against the frozen payload and regenerate this report."
    }
    if (-not $physical.exists) {
        Add-Blocker $blockers "physical-evidence-missing" "external" `
            "The exact-candidate physical evidence record does not exist." `
            "Initialize it with tools/new_physical_release_evidence.ps1 and complete all seven physical sessions."
    }
    elseif (-not $physical.identity_matches) {
        Add-Blocker $blockers "physical-evidence-stale" "external" `
            "The physical evidence record does not match commit $commitSha and PCK $($docsPck.sha256)." `
            "Initialize a fresh record after the candidate is frozen; never carry observations across candidate hashes."
    }
    if ($physical.pending_session_ids.Count -gt 0) {
        Add-Blocker $blockers "physical-sessions-pending" "external" `
            ("Pending physical sessions: " + ($physical.pending_session_ids -join ", ") + ".") `
            "Conduct, register, and independently sign the required device sessions."
    }
    if (-not $usability.exists) {
        Add-Blocker $blockers "usability-evidence-missing" "external" `
            "The exact-candidate moderated usability evidence record does not exist." `
            "Initialize it with tools/new_usability_playtest_evidence.ps1 and complete all seven moderated sessions."
    }
    elseif (-not $usability.identity_matches) {
        Add-Blocker $blockers "usability-evidence-stale" "external" `
            "The usability evidence record does not match commit $commitSha and PCK $($docsPck.sha256)." `
            "Initialize a fresh record after the candidate is frozen; never carry observations across candidate hashes."
    }
    if ($usability.pending_session_ids.Count -gt 0) {
        Add-Blocker $blockers "usability-sessions-pending" "external" `
            ("Pending moderated sessions: " + ($usability.pending_session_ids -join ", ") + ".") `
            "Conduct, register, and independently moderate the required player sessions."
    }

    $releaseReady = (
        $sourceWorktreeClean -and
        $payloadParityPassed -and
        $pckParityPassed -and
        $betaGate.current_for_payload -and
        $physical.ready -and
        $usability.ready -and
        $blockers.Count -eq 0
    )
    $report = [ordered]@{
        schema_version = 1
        generated_at_utc = (Get-Date).ToUniversalTime().ToString("o")
        release_ready = $releaseReady
        candidate = [ordered]@{
            commit_sha = $commitSha
            branch = $branch
            frozen = $sourceWorktreeClean
            tracked_change_count = $trackedChanges.Count
            source_untracked_count = $sourceUntracked.Count
            change_sample = @($trackedChanges + $sourceUntracked | Select-Object -First 25)
            pck_bytes = $docsPck.bytes
            pck_sha256 = $docsPck.sha256
        }
        automated_gate = $betaGate
        artifact_parity = [ordered]@{
            passed = $payloadParityPassed -and $pckParityPassed
            docs_web_file_count = $releaseFiles.Count
            synchronized_pck_count = @($pckParity | Where-Object { $_.matches_authoritative }).Count
            required_pck_count = $pckLocations.Count
            files = $payloadParity
            pck_locations = $pckParity
        }
        external_evidence = [ordered]@{
            physical = $physical
            usability = $usability
        }
        blocker_count = $blockers.Count
        blockers = @($blockers)
        duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
    }

    if ($SelfTest) {
        if ($report.schema_version -ne 1) { throw "Self-test: schema version must be 1." }
        if ($physicalSessionIds.Count -ne 7) { throw "Self-test: physical session contract must contain seven IDs." }
        if ($usabilitySessionIds.Count -ne 7) { throw "Self-test: usability session contract must contain seven IDs." }
        if ($releaseFiles.Count -ne 9) { throw "Self-test: release payload contract must contain nine files." }
        if ($pckLocations.Count -ne 6) { throw "Self-test: PCK contract must contain six locations." }
        if ($report.candidate.pck_sha256 -notmatch '^[0-9a-f]{64}$') { throw "Self-test: PCK identity is invalid." }
    }

    $absoluteOutput = Get-RepositoryPath $OutputPath
    $absoluteMarkdown = Get-RepositoryPath $MarkdownPath
    New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteOutput) -Force | Out-Null
    New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteMarkdown) -Force | Out-Null
    $report | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $absoluteOutput -Encoding utf8

    $markdown = [Collections.Generic.List[string]]::new()
    $markdown.Add("# Pecking Order release readiness") | Out-Null
    $markdown.Add("") | Out-Null
    $markdown.Add("Generated: $($report.generated_at_utc)") | Out-Null
    $markdown.Add("") | Out-Null
    $markdown.Add("| Gate | Status | Evidence |") | Out-Null
    $markdown.Add("| --- | --- | --- |") | Out-Null
    $markdownCodeTick = [char]96
    $candidateCommitEvidence = $markdownCodeTick + [string]$report.candidate.commit_sha + $markdownCodeTick
    $candidatePckEvidence = $markdownCodeTick + [string]$report.candidate.pck_sha256 + $markdownCodeTick
    $automatedGateEvidence = $markdownCodeTick + [string]$report.automated_gate.path + $markdownCodeTick
    $markdown.Add("| Candidate frozen | $(if ($report.candidate.frozen) { 'PASS' } else { 'BLOCKED' }) | $candidateCommitEvidence / $candidatePckEvidence |") | Out-Null
    $markdown.Add("| Payload parity | $(if ($report.artifact_parity.passed) { 'PASS' } else { 'BLOCKED' }) | $($report.artifact_parity.synchronized_pck_count)/$($report.artifact_parity.required_pck_count) PCK locations synchronized |") | Out-Null
    $markdown.Add("| Automated release gate | $(if ($report.automated_gate.current_for_payload) { 'PASS' } else { 'BLOCKED' }) | $automatedGateEvidence |") | Out-Null
    $markdown.Add("| Physical evidence | $(if ($report.external_evidence.physical.ready) { 'PASS' } else { 'BLOCKED' }) | $($report.external_evidence.physical.passed_session_count)/$($report.external_evidence.physical.required_session_count) sessions |") | Out-Null
    $markdown.Add("| Moderated usability | $(if ($report.external_evidence.usability.ready) { 'PASS' } else { 'BLOCKED' }) | $($report.external_evidence.usability.passed_session_count)/$($report.external_evidence.usability.required_session_count) sessions |") | Out-Null
    $markdown.Add("") | Out-Null
    $markdown.Add("Overall: **$(if ($report.release_ready) { 'READY' } else { 'BLOCKED' })**") | Out-Null
    $markdown.Add("") | Out-Null
    $markdown.Add("## Exact next actions") | Out-Null
    $markdown.Add("") | Out-Null
    if ($blockers.Count -eq 0) {
        $markdown.Add("- No release blockers remain for this exact candidate.") | Out-Null
    }
    else {
        foreach ($blocker in $blockers) {
            $markdown.Add("- **$($blocker.id):** $($blocker.detail) $($blocker.next_action)") | Out-Null
        }
    }
    $markdown | Set-Content -LiteralPath $absoluteMarkdown -Encoding utf8

    Write-Output "RELEASE_READINESS ready=$releaseReady blockers=$($blockers.Count) report=$absoluteOutput dashboard=$absoluteMarkdown"
    if ($RequireReleaseReady -and -not $releaseReady) {
        exit 1
    }
}
finally {
    Pop-Location
}
