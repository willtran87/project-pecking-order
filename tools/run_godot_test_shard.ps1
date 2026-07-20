param(
    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 2047)]
    [int]$Shard,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 2048)]
    [int]$Modulo,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [int]$TimeoutSeconds = 90,

    [string[]]$TestNames = @(),

    [string]$Godot = "$env:LOCALAPPDATA\Programs\Godot\4.7\Godot_v4.7-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$output = Join-Path $root $OutputDirectory
New-Item -ItemType Directory -Path $output -Force | Out-Null

$tests = @(Get-ChildItem -LiteralPath (Join-Path $root "tests") -Filter "*.gd" | Sort-Object FullName)
$selected = @()
for ($index = 0; $index -lt $tests.Count; $index++) {
    $explicitlySelected = $TestNames.Count -gt 0 -and $TestNames -contains $tests[$index].Name
    $selectedByShard = $TestNames.Count -eq 0 -and ($index % $Modulo) -eq $Shard
    if ($explicitlySelected -or $selectedByShard) {
        $selected += [pscustomobject]@{
            Index = $index
            File = $tests[$index]
        }
    }
}

$results = @()
$startedUtc = [DateTime]::UtcNow
foreach ($entry in $selected) {
    $relative = "tests/$($entry.File.Name)"
    $stem = "{0:D3}-{1}" -f $entry.Index, $entry.File.BaseName
    $stdoutPath = Join-Path $output "$stem.stdout.log"
    $stderrPath = Join-Path $output "$stem.stderr.log"

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Godot
    $startInfo.Arguments = "--headless --path `"$root`" --script `"$relative`""
    $startInfo.WorkingDirectory = $root
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    [void]$process.Start()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $exited = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $exited) {
        try {
            # Godot's console launcher starts the engine as a child process on
            # Windows. Killing only the launcher leaves that child holding the
            # redirected output handles open, which deadlocks ReadToEndAsync and
            # strands an invisible headless test indefinitely. Terminate the
            # complete process tree so the timeout is genuinely bounded.
            $process.Kill($true)
        } catch {
            try {
                $process.Kill()
            } catch {
            }
        }
        $process.WaitForExit()
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $watch.Stop()

    [System.IO.File]::WriteAllText($stdoutPath, $stdout)
    [System.IO.File]::WriteAllText($stderrPath, $stderr)

    $exitCode = if ($exited) { $process.ExitCode } else { $null }
    $combined = "$stdout`n$stderr"
    $hasPassMarker = $combined -match "(?m)^.*_PASSED(?:\s.*)?$"
    $errorMatches = @([regex]::Matches($combined, "(?im)^.*(?:SCRIPT ERROR:|Parse Error:|ERROR:).*$") | ForEach-Object { $_.Value.Trim() } | Select-Object -Unique)
    $status = "PASS"
    $reasons = @()
    if (-not $exited) {
        $status = "TIMEOUT"
        $reasons += "exceeded $TimeoutSeconds seconds"
    } elseif ($exitCode -ne 0) {
        $status = "FAIL"
        $reasons += "exit code $exitCode"
    }
    if (-not $hasPassMarker) {
        if ($status -ne "TIMEOUT") {
            $status = "FAIL"
        }
        $reasons += "missing explicit _PASSED marker"
    }
    if ($errorMatches.Count -gt 0) {
        if ($status -ne "TIMEOUT") {
            $status = "FAIL"
        }
        $reasons += "engine error signature"
    }

    $results += [pscustomobject]@{
        index = $entry.Index
        test = $relative
        status = $status
        duration_seconds = [Math]::Round($watch.Elapsed.TotalSeconds, 3)
        exit_code = $exitCode
        passed_marker = $hasPassMarker
        error_signatures = $errorMatches
        reasons = $reasons
        stdout_log = [System.IO.Path]::GetFileName($stdoutPath)
        stderr_log = [System.IO.Path]::GetFileName($stderrPath)
    }
    Write-Output ("[{0}] {1} ({2:N3}s)" -f $status, $relative, $watch.Elapsed.TotalSeconds)
}

$summary = [ordered]@{
    shard = $Shard
    modulo = $Modulo
    total_discovered = $tests.Count
    selected_count = $selected.Count
    completed_count = $results.Count
    pass_count = @($results | Where-Object status -eq "PASS").Count
    fail_count = @($results | Where-Object status -eq "FAIL").Count
    timeout_count = @($results | Where-Object status -eq "TIMEOUT").Count
    started_utc = $startedUtc.ToString("o")
    completed_utc = [DateTime]::UtcNow.ToString("o")
    godot = $Godot
    timeout_seconds = $TimeoutSeconds
    results = $results
}
$summaryPath = Join-Path $output "shard-summary.json"
[System.IO.File]::WriteAllText($summaryPath, ($summary | ConvertTo-Json -Depth 8))

Write-Output ("SHARD_SUMMARY shard={0} selected={1} pass={2} fail={3} timeout={4}" -f $Shard, $summary.selected_count, $summary.pass_count, $summary.fail_count, $summary.timeout_count)
if ($summary.fail_count -gt 0 -or $summary.timeout_count -gt 0) {
    exit 1
}
