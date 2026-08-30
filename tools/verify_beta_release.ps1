param(
    [string]$OutputPath = "output\release\beta-release-gate.json",
    [string]$Godot = "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe",
    [string]$NodeDirectory = "",
    [switch]$SkipGodot,
    [switch]$SkipWeb
)

$ErrorActionPreference = "Stop"
# Native tools legitimately use stderr for non-fatal diagnostics (for example,
# Rolldown's plugin timing advisory). Invoke-CheckedCommand records merged output
# and judges the command by its exit code, so stderr must not be promoted to a
# terminating PowerShell error before that contract can run.
if (Test-Path Variable:\PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$root = Split-Path -Parent $PSScriptRoot
$started = Get-Date
$checks = [ordered]@{}

# Normalize an optional portable runtime before any nested Push-Location call.
# A relative NodeDirectory is documented and useful for CI caches, but leaving
# it relative made the Web phase resolve it underneath web/ after every native
# contract had already passed.
if (-not [string]::IsNullOrWhiteSpace($NodeDirectory)) {
    if (-not [IO.Path]::IsPathRooted($NodeDirectory)) {
        $NodeDirectory = Join-Path $root $NodeDirectory
    }
    $NodeDirectory = [IO.Path]::GetFullPath($NodeDirectory)
}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )
    $commandStarted = Get-Date
    # Windows PowerShell can still promote a native child's stderr record to a
    # terminating error even when PSNativeCommandUseErrorActionPreference is
    # disabled (for example Rolldown's non-fatal plugin timing advisory). Keep
    # the surrounding release script strict, but judge this bounded native
    # process by its exit code after capturing both streams.
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = "Continue"
        $output = @(& $Command 2>&1 | ForEach-Object { $_.ToString() })
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    $checks[$Name] = [ordered]@{
        passed = $exitCode -eq 0
        exit_code = $exitCode
        duration_seconds = [Math]::Round(((Get-Date) - $commandStarted).TotalSeconds, 3)
        output_tail = @($output | Select-Object -Last 20)
    }
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode."
    }
}

Push-Location $root
try {
    if (-not $SkipGodot) {
        if (-not (Test-Path -LiteralPath $Godot)) {
            throw "Godot console executable not found: $Godot"
        }
        $nativeTests = @(
            "active_playbook_test.gd",
			"engagement_advancement_test.gd",
			"intuitive_engagement_completion_test.gd",
			"complete_game_loop_test.gd",
			"mastery_replay_completion_test.gd",
			"professional_intuitive_loop_test.gd",
			"rewarding_game_loop_test.gd",
			"compelling_game_loop_test.gd",
			"strategic_flow_loop_test.gd",
			"tactical_route_planner_test.gd",
			"tactile_reward_loop_test.gd",
			"experiential_management_loop_test.gd",
			"intuitive_reward_loop_test.gd",
			"consolidated_game_loop_test.gd",
			"professional_gameplay_completion_test.gd",
            "guided_strategy_feedback_test.gd",
            "gameplay_pulse_director_test.gd",
            "personnel_career_test.gd",
            "chicken_render_hot_path_test.gd",
            "opening_experience_progression_test.gd",
			"first_session_funnel_test.gd",
			"probation_campaign_ui_test.gd",
			"campaign_ending_ui_test.gd",
            "career_sponsorship_ui_test.gd",
            "career_sponsorship_integration_test.gd",
            "incident_docket_variety_test.gd",
            "manager_roster_economy_test.gd",
            "manager_recruitment_ui_test.gd",
            "feed_procurement_ui_test.gd",
            "farmgate_dispatch_ui_contract_test.gd",
            "audio_feedback_test.gd",
			"office_audio_director_test.gd",
            "office_storytelling_test.gd",
            "character_dialogue_portrait_test.gd",
            "character_dialogue_ui_test.gd",
            "temperament_work_style_test.gd",
            "claimant_resolution_test.gd",
            "claim_routing_ui_test.gd",
            "flock_relations_case_ui_test.gd",
            "flock_relations_office_integration_test.gd",
            "farmer_relations_gallery_ui_test.gd",
            "farmer_relations_gallery_office_integration_test.gd",
            "interaction_safety_contract_test.gd",
            "staffing_ui_test.gd",
            "economic_briefing_test.gd",
            "farm_mutual_contract_board_ui_test.gd",
            "commissioning_reveal_ui_test.gd",
            "campus_portfolio_reveal_ui_test.gd",
            "campus_portfolio_ui_test.gd",
            "capital_blueprint_ui_test.gd",
            "campus_expansion_ui_test.gd",
            "settings_office_integration_test.gd",
            "ui_text_expansion_resilience_test.gd",
            "campaign_intake_safety_test.gd",
            "final_hearing_and_replay_structure_test.gd",
            "career_portfolio_and_identity_test.gd",
            "campaign_save_store_test.gd",
            "campaign_semantic_recovery_test.gd",
            "checkpoint_office_integration_test.gd",
            "simulation_persistence_test.gd",
            "operations_economy_test.gd",
            "campaign_balance_playthrough_test.gd"
        )
        foreach ($testName in $nativeTests) {
            Invoke-CheckedCommand -Name "godot/$testName" -Command {
                & $Godot --headless --path $root --script (Join-Path "tests" $testName)
            }
        }
    }

    if (-not $SkipWeb) {
        $nodeExecutable = "node.exe"
        if (-not [string]::IsNullOrWhiteSpace($NodeDirectory)) {
            $nodeExecutable = Join-Path $NodeDirectory "node.exe"
            if (-not (Test-Path -LiteralPath $nodeExecutable)) {
                throw "Node executable not found in: $NodeDirectory"
            }
            $env:PATH = "$NodeDirectory;$env:PATH"
        }
        $nodeVersion = (& $nodeExecutable --version).TrimStart("v")
        if ([version]$nodeVersion -lt [version]"22.13.0") {
            throw "Node 22.13+ is required for the Web gate; found $nodeVersion. Pass -NodeDirectory with a supported runtime."
        }
        $npmCommand = Get-Command "npm.cmd" -ErrorAction Stop
        $npmCli = Join-Path (Split-Path -Parent $npmCommand.Source) "node_modules\npm\bin\npm-cli.js"
        if (-not (Test-Path -LiteralPath $npmCli)) {
            throw "npm CLI not found beside npm.cmd: $npmCli"
        }
        $checks["web/toolchain"] = [ordered]@{
            passed = $true
            node_version = $nodeVersion
            node_executable = $nodeExecutable
            npm_cli = $npmCli
        }
        Push-Location (Join-Path $root "web")
        try {
            Invoke-CheckedCommand -Name "web/lint" -Command { & $nodeExecutable $npmCli run lint }
            Invoke-CheckedCommand -Name "web/rendered-tests" -Command { & $nodeExecutable $npmCli test }
            Invoke-CheckedCommand -Name "web/production-server" -Command { & $nodeExecutable $npmCli run "test:production" }
        }
        finally {
            Pop-Location
        }
    }

    $powershellExecutable = (Get-Process -Id $PID).Path
    Invoke-CheckedCommand -Name "release/physical-evidence-contract" -Command {
        & $powershellExecutable `
            -NoLogo `
            -NoProfile `
            -NonInteractive `
            -File (Join-Path $root "tools\verify_physical_release_evidence.ps1") `
            -SelfTest `
            -ReportPath "output\release\physical-release-validator-self-test.json"
    }
    Invoke-CheckedCommand -Name "release/physical-evidence-handoff" -Command {
        & $powershellExecutable `
            -NoLogo `
            -NoProfile `
            -NonInteractive `
            -File (Join-Path $root "tools\verify_physical_release_handoff.ps1") `
            -ReportPath "output\release\physical-release-handoff-self-test.json"
    }
    Invoke-CheckedCommand -Name "release/usability-playtest-contract" -Command {
        & $powershellExecutable `
            -NoLogo `
            -NoProfile `
            -NonInteractive `
            -File (Join-Path $root "tools\verify_usability_playtest_evidence.ps1") `
            -SelfTest `
            -ReportPath "output\release\usability-playtest-validator-self-test.json"
    }
    Invoke-CheckedCommand -Name "release/usability-playtest-handoff" -Command {
        & $powershellExecutable `
            -NoLogo `
            -NoProfile `
            -NonInteractive `
            -File (Join-Path $root "tools\verify_usability_playtest_handoff.ps1") `
            -ReportPath "output\release\usability-playtest-handoff-self-test.json"
    }
    Invoke-CheckedCommand -Name "release/readiness-report-contract" -Command {
        & $powershellExecutable `
            -NoLogo `
            -NoProfile `
            -NonInteractive `
            -File (Join-Path $root "tools\write_release_readiness_report.ps1") `
            -SelfTest `
            -OutputPath "output\release\release-readiness-self-test.json" `
            -MarkdownPath "output\release\release-readiness-self-test.md"
    }

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
    $parity = @()
    foreach ($relativePath in $releaseFiles) {
        $docsPath = Join-Path (Join-Path $root "docs") $relativePath
        $webPath = Join-Path (Join-Path $root "web\public\game") $relativePath
        if (-not (Test-Path -LiteralPath $docsPath) -or -not (Test-Path -LiteralPath $webPath)) {
            throw "Missing release payload: $relativePath"
        }
        $docsHash = (Get-FileHash -LiteralPath $docsPath -Algorithm SHA256).Hash
        $webHash = (Get-FileHash -LiteralPath $webPath -Algorithm SHA256).Hash
        if ($docsHash -ne $webHash) {
            throw "Release payload mismatch: $relativePath"
        }
        $parity += [ordered]@{
            path = $relativePath
            bytes = (Get-Item -LiteralPath $docsPath).Length
            sha256 = $docsHash
        }
    }
    $checks["release/artifact-parity"] = [ordered]@{
        passed = $true
        file_count = $parity.Count
        files = $parity
    }

    $result = [ordered]@{
        passed = $true
        generated_at = (Get-Date).ToUniversalTime().ToString("o")
        duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
        checks = $checks
    }
}
catch {
    $result = [ordered]@{
        passed = $false
        generated_at = (Get-Date).ToUniversalTime().ToString("o")
        duration_seconds = [Math]::Round(((Get-Date) - $started).TotalSeconds, 3)
        error = $_.Exception.Message
        checks = $checks
    }
    $failed = $true
}
finally {
    Pop-Location
}

$absoluteOutput = Join-Path $root $OutputPath
New-Item -ItemType Directory -Path (Split-Path -Parent $absoluteOutput) -Force | Out-Null
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $absoluteOutput -Encoding utf8
Write-Output "BETA_RELEASE_GATE passed=$($result.passed) report=$absoluteOutput"
if ($failed) {
    exit 1
}
