function Get-PhysicalSessionBundleIssues {
    param(
        [Parameter(Mandatory = $true)][string]$BundlePath,
        [Parameter(Mandatory = $true)]
        [ValidateSet("touch", "screen-reader", "audio", "gpu")]
        [string]$SessionKind
    )

    $issues = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $BundlePath -PathType Leaf)) {
        [void]$issues.Add("bundle file does not exist")
        return $issues.ToArray()
    }
    if ([IO.Path]::GetExtension($BundlePath) -ne ".zip") {
        [void]$issues.Add("bundle must be a .zip archive")
        return $issues.ToArray()
    }

    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = $null
    try {
        $archive = [IO.Compression.ZipFile]::OpenRead($BundlePath)
        $fileCount = 0
        $recordingCount = 0
        $logCount = 0
        $screenshotCount = 0
        $recordingExtensions = @(
            ".mp4", ".webm", ".mov", ".mkv", ".m4a", ".wav", ".aac", ".flac"
        )
        $logExtensions = @(".txt", ".md", ".json", ".csv")
        $screenshotExtensions = @(".png", ".jpg", ".jpeg", ".webp")

        foreach ($entry in $archive.Entries) {
            $entryPath = $entry.FullName.Replace("\", "/")
            $segments = @($entryPath.Split("/") | Where-Object { $_ -ne "" })
            if (
                $entryPath.StartsWith("/") -or
                $entryPath -match "^[A-Za-z]:" -or
                $segments -contains ".."
            ) {
                [void]$issues.Add("archive contains an unsafe path: $entryPath")
                continue
            }
            if ([string]::IsNullOrEmpty($entry.Name)) {
                continue
            }

            $fileCount += 1
            if ($entry.Length -le 0) {
                [void]$issues.Add("archive contains an empty evidence file: $entryPath")
                continue
            }
            $extension = [IO.Path]::GetExtension($entry.Name).ToLowerInvariant()
            if ($extension -in $recordingExtensions) {
                $recordingCount += 1
            }
            if ($extension -in $logExtensions) {
                $logCount += 1
            }
            if ($extension -in $screenshotExtensions) {
                $screenshotCount += 1
            }
        }

        if ($fileCount -eq 0) {
            [void]$issues.Add("archive contains no evidence files")
        }
        if ($recordingCount -lt 1) {
            [void]$issues.Add("archive must contain a video or audio recording")
        }
        if ($logCount -lt 1) {
            [void]$issues.Add("archive must contain a text or JSON session log")
        }
        if ($SessionKind -eq "gpu" -and $screenshotCount -lt 1) {
            [void]$issues.Add("GPU archive must contain a renderer/performance screenshot")
        }
    }
    catch {
        [void]$issues.Add("bundle is not a readable ZIP archive: $($_.Exception.Message)")
    }
    finally {
        if ($null -ne $archive) {
            $archive.Dispose()
        }
    }

    return $issues.ToArray()
}
