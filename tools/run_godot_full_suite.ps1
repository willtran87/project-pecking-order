param(
    [string]$OutputDirectory = "output\godot-full-suite-current",
    [ValidateRange(1, 32)]
    [int]$ShardCount = 3,
    [int]$TimeoutSeconds = 90
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$runner = Join-Path $PSScriptRoot "run_godot_test_shard.ps1"
$jobs = @()

for ($shard = 0; $shard -lt $ShardCount; $shard++) {
    $shardOutput = Join-Path $OutputDirectory "shard$shard"
    $jobs += Start-Job -ScriptBlock {
        param($Runner, $Shard, $ShardCount, $ShardOutput, $TimeoutSeconds)
        $lines = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $Runner `
            -Shard $Shard `
            -Modulo $ShardCount `
            -OutputDirectory $ShardOutput `
            -TimeoutSeconds $TimeoutSeconds 2>&1
        [pscustomobject]@{
            shard = $Shard
            exit_code = $LASTEXITCODE
            output = @($lines | ForEach-Object { $_.ToString() })
        }
    } -ArgumentList $runner, $shard, $ShardCount, $shardOutput, $TimeoutSeconds
}

$jobs | Wait-Job | Out-Null
$jobResults = @($jobs | Receive-Job)
$jobs | Remove-Job

foreach ($jobResult in $jobResults | Sort-Object shard) {
    foreach ($line in $jobResult.output) {
        Write-Output "[shard$($jobResult.shard)] $line"
    }
}

$summaries = @()
for ($shard = 0; $shard -lt $ShardCount; $shard++) {
    $summaryPath = Join-Path $root (Join-Path $OutputDirectory "shard$shard\shard-summary.json")
    if (-not (Test-Path -LiteralPath $summaryPath)) {
        throw "Missing shard summary: $summaryPath"
    }
    $summaries += Get-Content -LiteralPath $summaryPath -Raw | ConvertFrom-Json
}

$totalDiscovered = @($summaries | Select-Object -ExpandProperty total_discovered -Unique)
if ($totalDiscovered.Count -ne 1) {
    throw "Shards did not discover the same test count."
}
$selected = ($summaries | Measure-Object -Property selected_count -Sum).Sum
$completed = ($summaries | Measure-Object -Property completed_count -Sum).Sum
$passed = ($summaries | Measure-Object -Property pass_count -Sum).Sum
$failed = ($summaries | Measure-Object -Property fail_count -Sum).Sum
$timedOut = ($summaries | Measure-Object -Property timeout_count -Sum).Sum

$combined = [ordered]@{
    shard_count = $ShardCount
    total_discovered = [int]$totalDiscovered[0]
    selected_count = [int]$selected
    completed_count = [int]$completed
    pass_count = [int]$passed
    fail_count = [int]$failed
    timeout_count = [int]$timedOut
    completed_utc = [DateTime]::UtcNow.ToString("o")
    shards = $summaries
}
$combinedPath = Join-Path $root (Join-Path $OutputDirectory "full-suite-summary.json")
[System.IO.File]::WriteAllText($combinedPath, ($combined | ConvertTo-Json -Depth 10))

Write-Output ("FULL_SUITE_SUMMARY discovered={0} selected={1} completed={2} pass={3} fail={4} timeout={5}" -f $combined.total_discovered, $combined.selected_count, $combined.completed_count, $combined.pass_count, $combined.fail_count, $combined.timeout_count)
if ($combined.selected_count -ne $combined.total_discovered -or $combined.completed_count -ne $combined.total_discovered -or $combined.fail_count -gt 0 -or $combined.timeout_count -gt 0) {
    exit 1
}
