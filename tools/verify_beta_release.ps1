param(
    [string]$OutputPath = "output\release\beta-release-gate.json",
    [string]$Godot = "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe",
    [string]$NodeDirectory = "",
    [switch]$SkipGodot,
    [switch]$SkipWeb
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$started = Get-Date
$checks = [ordered]@{}

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Command
    )
    $commandStarted = Get-Date
    $output = @(& $Command 2>&1 | ForEach-Object { $_.ToString() })
    $exitCode = $LASTEXITCODE
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
            "personnel_career_test.gd",
            "chicken_render_hot_path_test.gd",
            "opening_experience_progression_test.gd",
            "incident_docket_variety_test.gd",
            "manager_roster_economy_test.gd",
            "audio_feedback_test.gd",
            "office_storytelling_test.gd",
            "temperament_work_style_test.gd",
            "claimant_resolution_test.gd",
            "claim_routing_ui_test.gd",
            "simulation_persistence_test.gd"
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
