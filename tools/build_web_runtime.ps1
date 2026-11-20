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

# --ignore-whitespace tolerates CRLF checkouts of the patch (core.autocrlf).
# Windows PowerShell turns native stderr into a terminating error under
# 'Stop', so the probe runs with 'Continue' and is judged by its exit code.
$ErrorActionPreference = 'Continue'
git -C $godotRoot apply --ignore-whitespace --reverse --check $patch 2>&1 | Out-Null
$patchAlreadyApplied = $LASTEXITCODE -eq 0
$ErrorActionPreference = 'Stop'
if (-not $patchAlreadyApplied) {
    git -C $godotRoot apply --ignore-whitespace --check $patch
    Check-NativeExit 'Patch validation'
    git -C $godotRoot apply --ignore-whitespace $patch
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
    # Strip engine features the game never touches. Every flag below removes
    # code only: 2D physics/navigation, 3D navigation, XR, networking, video,
    # MP3, runtime glTF/FBX import, unused image codecs and the Jolt backend
    # (the project uses the default GodotPhysics3D for hen picking rays).
    # Rendering, text shaping (HarfBuzz/ICU), SVG, RegEx, Ogg/Vorbis and WebP
    # stay. Remove a flag here before using that feature in game code.
    $featureFlags = @(
        'disable_physics_2d=yes', 'disable_navigation_2d=yes',
        'disable_navigation_3d=yes', 'disable_xr=yes', 'graphite=no',
        'module_basis_universal_enabled=no', 'module_bmp_enabled=no',
        'module_camera_enabled=no', 'module_csg_enabled=no', 'module_dds_enabled=no',
        'module_enet_enabled=no', 'module_fbx_enabled=no', 'module_gltf_enabled=no',
        'module_gridmap_enabled=no', 'module_hdr_enabled=no',
        'module_interactive_music_enabled=no', 'module_jolt_physics_enabled=no',
        'module_jpg_enabled=no', 'module_jsonrpc_enabled=no', 'module_ktx_enabled=no',
        'module_mbedtls_enabled=no', 'module_mobile_vr_enabled=no',
        'module_mp3_enabled=no', 'module_msdfgen_enabled=no',
        'module_multiplayer_enabled=no', 'module_noise_enabled=no',
        'module_text_server_fb_enabled=no', 'module_tga_enabled=no',
        'module_theora_enabled=no', 'module_upnp_enabled=no',
        'module_visual_shader_enabled=no', 'module_webrtc_enabled=no',
        'module_websocket_enabled=no', 'module_webxr_enabled=no'
    )
    python -m SCons platform=web target=template_release threads=no lto=thin "optimize=$Optimize" "-j$Jobs" @featureFlags
    Check-NativeExit 'Web runtime compilation'
    $template = Get-ChildItem -LiteralPath (Join-Path $godotRoot 'bin') -Filter 'godot.web.template_release*.zip'
    if (@($template).Count -ne 1) { throw 'Expected exactly one Web release template' }
    Copy-Item -LiteralPath $template.FullName -Destination (Join-Path $templateRoot 'pecking-order.web.template_release.zip')
} finally { Pop-Location }
Write-Output "Web template ready: $templateRoot"
