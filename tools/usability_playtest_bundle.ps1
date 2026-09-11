Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-UsabilityPlaytestBundleIssues {
    param(
        [Parameter(Mandatory = $true)][string]$BundlePath,
        [Parameter(Mandatory = $true)][string]$SessionId
    )
    $bundleIssues = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $BundlePath -PathType Leaf)) {
        [void]$bundleIssues.Add("bundle does not exist")
        return @($bundleIssues)
    }
    if ([IO.Path]::GetExtension($BundlePath) -ne ".zip") {
        [void]$bundleIssues.Add("bundle must be a ZIP archive")
        return @($bundleIssues)
    }
    if (
        [IO.Path]::GetFileNameWithoutExtension($BundlePath).IndexOf(
            $SessionId,
            [StringComparison]::OrdinalIgnoreCase
        ) -lt 0
    ) {
        [void]$bundleIssues.Add("bundle filename must include session ID '$SessionId'")
    }
    $archive = $null
    try {
        $archive = [IO.Compression.ZipFile]::OpenRead($BundlePath)
        $hasRecording = $false
        $hasMachineLog = $false
        $hasModeratorNotes = $false
        foreach ($entry in $archive.Entries) {
            $name = [string]$entry.FullName
            if (
                [string]::IsNullOrWhiteSpace($name) -or
                $name.StartsWith("/") -or
                $name.StartsWith("\") -or
                $name -match "^[A-Za-z]:" -or
                @($name -split "[\\/]" | Where-Object { $_ -eq ".." }).Count -gt 0
            ) {
                [void]$bundleIssues.Add("bundle contains unsafe archive path '$name'")
                continue
            }
            if ($name.EndsWith("/") -or $name.EndsWith("\")) {
                continue
            }
            if ($entry.Length -le 0) {
                [void]$bundleIssues.Add("bundle contains empty evidence file '$name'")
                continue
            }
            $extension = [IO.Path]::GetExtension($name).ToLowerInvariant()
            if ($extension -in @(".webm", ".mp4", ".mkv", ".mov", ".wav", ".m4a")) {
                $hasRecording = $true
            }
            if ($extension -in @(".json", ".csv")) {
                $hasMachineLog = $true
            }
            if ($extension -in @(".md", ".txt")) {
                $hasModeratorNotes = $true
            }
        }
    }
    catch {
        [void]$bundleIssues.Add("bundle is unreadable: $($_.Exception.Message)")
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
    }
    if (-not $hasRecording) {
        [void]$bundleIssues.Add("bundle needs a non-empty session recording")
    }
    if (-not $hasMachineLog) {
        [void]$bundleIssues.Add("bundle needs a non-empty JSON or CSV task log")
    }
    if (-not $hasModeratorNotes) {
        [void]$bundleIssues.Add("bundle needs non-empty Markdown or text moderator notes")
    }
    return @($bundleIssues)
}
