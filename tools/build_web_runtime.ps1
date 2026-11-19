param(
    [int]$Jobs = 24,
    [ValidateSet('size', 'speed')][string]$Optimize = 'size'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildRoot = Join-Path $projectRoot 'output/engine-build'
$godotRoot = Join-Path $buildRoot 'godot'
$sdkRoot = Join-Path $buildRoot 'emsdk'
$pythonLib = Join-Path $buildRoot 'pythonlib'
$templateRoot = Join-Path $projectRoot 'builds/web-runtime'
$patch = Join-Path $PSScriptRoot 'web-runtime/on-demand-variants.patch'
$godotCommit = '5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88'
$sdkCommit = '1693ce7359fc9694f198694f902a2cc061239b86'

function Check-NativeExit([string]$Step) {
    if ($LASTEXITCODE -ne 0) { throw "$Step failed ($LASTEXITCODE)" }
}

New-Item -ItemType Directory -Force -Path $buildRoot, $templateRoot | Out-Null
# Keep the build checkout and toolchain out of Godot's resource importer.
foreach ($ignoredDirectory in @('output', 'builds')) {
    $ignoreFile = Join-Path $projectRoot "$ignoredDirectory/.gdignore"
    if (-not (Test-Path -LiteralPath $ignoreFile)) {
        Set-Content -LiteralPath $ignoreFile -Value ''
    }
}
if (-not (Test-Path -LiteralPath $godotRoot)) {
    git clone --depth 1 --branch 4.7-stable https://github.com/godotengine/godot.git $godotRoot
    Check-NativeExit 'Godot checkout'
}
if ((git -C $godotRoot rev-parse HEAD) -ne $godotCommit) { throw 'Unexpected Godot source revision' }
if (-not (Test-Path -LiteralPath $sdkRoot)) {
    git clone https://github.com/emscripten-core/emsdk.git $sdkRoot
    Check-NativeExit 'Emsdk checkout'
    git -C $sdkRoot checkout $sdkCommit
    Check-NativeExit 'Emsdk revision'
}
if ((git -C $sdkRoot rev-parse HEAD) -ne $sdkCommit) { throw 'Unexpected Emsdk revision' }

git -C $godotRoot apply --reverse --check $patch 2>$null
if ($LASTEXITCODE -ne 0) {
    git -C $godotRoot apply --check $patch
    Check-NativeExit 'Patch validation'
    git -C $godotRoot apply $patch
    Check-NativeExit 'Web shader patch'
}
uv pip install --target $pythonLib scons==4.10.1
Check-NativeExit 'SCons installation'
python (Join-Path $sdkRoot 'emsdk.py') install 4.0.23
Check-NativeExit 'Emscripten installation'
python (Join-Path $sdkRoot 'emsdk.py') activate 4.0.23
Check-NativeExit 'Emscripten activation'
& (Join-Path $sdkRoot 'emsdk_env.ps1')
Check-NativeExit 'Emscripten environment'
$env:PYTHONPATH = $pythonLib
Push-Location $godotRoot
try {
    python -m SCons platform=web target=template_release threads=no lto=thin "optimize=$Optimize" "-j$Jobs"
    Check-NativeExit 'Web runtime compilation'
    $template = Get-ChildItem -LiteralPath (Join-Path $godotRoot 'bin') -Filter 'godot.web.template_release*.zip'
    if (@($template).Count -ne 1) { throw 'Expected exactly one Web release template' }
    Copy-Item -LiteralPath $template.FullName -Destination (Join-Path $templateRoot 'pecking-order.web.template_release.zip')
} finally { Pop-Location }
Write-Output "Web template ready: $templateRoot"
