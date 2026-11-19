# Web runtime build

## Frame presentation state

`prepare_web_startup.mjs` also applies `frame-state.mjs` to the pinned JS glue.
The WebGL2 offscreen framebuffer presenter used to query `SCISSOR_TEST` and
`DRAW_FRAMEBUFFER_BINDING` on every frame commit. A release CPU profile found
these synchronous reads dominating engine-frame samples. The bridge tracks
the renderer's valid enable/disable, framebuffer binding and deletion commands
instead, then issues the exact original blit and state restoration. It reads
initial state once and reinitializes it after context restoration. It does not
change shaders, draw commands, framebuffer sizes, filtering, audio or game data.
Unrecognized presenter code fails preparation rather than silently patching a
different engine. Repeated preparation is idempotent.

Run `node --test web/tests/frame-state.test.mjs web/tests/startup-shaders.test.mjs`
from the project root, and `node tests/frame-state-webgl-audit.mjs` from `web`.
The latter compares real WebGL2 pixels and state before/after the bridge,
including canvas resize and context restoration. The performance audit supports
`--profile-engine` to write a Chrome `.cpuprofile`; those instrumented samples
must be kept separate from ordinary frame-pacing comparisons. Eliminating a
synchronous read can move GPU backpressure to later draw calls, so do not equate
the old query's sampled time with a guaranteed frame-time saving.

## Building the template

Run `pwsh -File tools/build_web_runtime.ps1` from this project. Git, Python and uv
must be available. The script pins Godot 4.7 to the installed editor's exact
commit, Emscripten 4.0.23, the SDK installer revision and SCons 4.10.1. It keeps
sources/toolchains in ignored `output/engine-build`, and produces the custom
release template in ignored `builds/web-runtime`. The first build downloads the
compiler toolchain; subsequent runs reuse compiled objects.
Pass `-Optimize speed` to compare execution-speed optimization (`-O3`) with
the Web default `-Optimize size` (`-Os`). Changing optimization rebuilds the
runtime; compare complete matched exports with the same game pack before
choosing a default. Both retain all rendering features and ThinLTO.
The default remains `size`: the 2026-11-07 matched-export comparison measured
12.82s / 12.12s for `size` versus 13.39s / 12.96s for `speed` in fresh
Chromium software-renderer sessions. The speed build also increased WASM from
39.5 MB to 55.3 MB, so it was rejected. Shader sources and the game pack were
identical. Do not assume a higher compiler optimization level improves startup.

`on-demand-variants.patch` changes only the Web build of the GLES3 shader loader.
`ShaderGLES3::_initialize_version` allocates every variant's map without
compiling its default specialization. The existing `_version_bind_shader` then
compiles the requested variant/specialization synchronously before use, checks
its compile/link status, caches it and binds it. No shader source, material,
lighting feature, quality setting or gameplay code is removed. Native shader
caching and compilation are unchanged. Future variants compile when needed,
so verify first-use gameplay and quality changes as well as the title screen.

The Web renderer also skips the constructor-only bind of
`scene_globals.shader_default_version`. This RID is created and freed but is
never used by the scene draw path; actual default materials have their own
shader versions. Binding it compiled a large unused 3D program and blocked
engine initialization on LINK_STATUS before scene loading could overlap the
remaining shader compilation. Native behavior and validation of drawn shaders
are unchanged.

The patch also submits both vertex and fragment stages before checking link
status, avoiding the synchronous compile-status round trip between stages.
Successful linking validates both stages. A failed link still prints the stage
compiler logs with their source, prints the program log, deletes the failed
objects and leaves the specialization invalid; it cannot be bound for rendering.
Native compilation checks are unchanged. This follows the
[WebGL shader compilation guidance](https://developer.mozilla.org/en-US/docs/Web/API/WebGL_API/WebGL_best_practices#dont_check_shader_compile_status_unless_linking_fails).
`web/tests/shader-failure-audit.mjs` injects invalid vertex and fragment source in
separate browser sessions to verify diagnostics and rejection of failed programs.

The standard export template remains the reference for visual comparisons.
After rebuilding, export with the matching Godot 4.7 editor and publish the
entire generated Web runtime together (JS, WASM, audio worklets, HTML and PCK).
Do not mix JS and WASM from different builds. The generated runtime retains
Godot's MIT license and third-party notices; upstream source/license:
https://github.com/godotengine/godot/tree/5b4e0cb0fd279832bbdd69fed5354d4e5ad26f88

Verification tools: `web/tests/startup-phases-audit.mjs` records browser engine,
shader and link timings; `tests/web_boot_performance_audit.mjs` measures full
cold/reload readiness. Gameplay is covered by `web/tests/smooth-opening-audit.mjs`
and the native game/expansion suites. Use a software renderer for comparable
measurements, and report those separately from real hardware performance.

## Parallel first-frame shader preparation

The Web wrapper fetches `index.startup-shaders.json.gz` concurrently with the
engine. It reconstructs the exact captured GLSL (shared lines keep this asset
around 111 KB for all three quality settings), creates the same WebGL2 context attributes as Godot, and submits
all opening programs before script/scene initialization. Preparation is optional
and never awaited by engine startup. KHR_parallel_shader_compile is required.
Known CPU renderers (SwiftShader, llvmpipe/softpipe and software/basic render
drivers) retain ordinary on-demand compilation: matched SwiftShader cold tests
were 12.09s prepared versus 10.51s on-demand. Hardware GPU preparation avoids
serial driver linking stalls; CPU preparation instead competes with WASM startup.

`web/lib/startup-shaders.mjs` matches complete vertex/fragment source, attribute
bindings, and transform-feedback configuration. Small post-export bridges in
Emscripten's glCompileShader and glLinkProgram avoid duplicate compilation and transfer a validated prepared WebGLProgram into the
engine's own GL.programs table. It preserves the engine handle, uniform ID
counter and name-length bookkeeping. Prepared shader stages also transfer into
GL.shaders under the original handles. Known stages defer compilation until
linking: a miss, failed warm-up, explicit shader diagnostic or early cleanup
compiles the original stages before continuing. This avoids doing stage
compilation twice while preserving native errors and resource ownership.
Godot still checks LINK_STATUS; there are
no rendering proxies or changed shader sources. Failed preparation, cache
misses, missing data, unsupported browsers and stale runtime keys all use the
original compile/link/error path. Unused opening programs are released after the
first presented frames; the bounded gameplay pool described below survives until
first use or teardown. Adopted programs are owned by Godot.

After exporting a new runtime:

1. Capture an **unprepared** normal opening with
   `node tests/startup-phases-audit.mjs ../output/web-game/shader-capture` from
   `web`. For a separate export, set STARTUP_GAME_DIR to its directory. An
   ordinary fresh Godot export has no adoption key and therefore captures the
   original path even if an older manifest is present.
2. From the project root run
   `node tools/prepare_web_startup.mjs docs output/web-game/shader-capture/audit.json`.
   This validates the capture, hashes WASM+PCK, writes the compressed manifest,
   and patches only the exact supported Emscripten link bridge. Add High and Low
   audit paths as additional arguments (capture them with STARTUP_PREFERENCES);
   the wrapper selects only the saved quality setting's programs. It is idempotent
   and rejects unknown glue/bookkeeping. Re-exporting overwrites the hook and
   safely returns to normal startup until this step is run again.
3. Copy the complete export, including the compressed manifest, to
   `web/public/game` and rebuild the wrapper. Keep docs/public/served assets in
   sync. The wrapper's program matcher is authoritative even for quality modes
   with different shaders: unmatched programs compile normally.

Tests: `node --test web/tests/startup-shaders.test.mjs` from the root;
`node tests/startup-shaders-browser-audit.mjs` from web checks rendered pixels,
program cleanup and stale/unavailable/unsupported fallbacks. Also run the shader
failure audit, complete opening, desk display and high-quality browser checks.
A first integration omitted uniform bookkeeping and rendered a black canvas
while gameplay diagnostics advanced; the fixed bridge preserves all four
Emscripten fields, and both the unit and real-pixel browser checks cover it.

## Opening scene resources

Office surface textures are baked losslessly, including their mipmaps:
`Godot --headless --path . --script tools/bake_office_surfaces.gd`.
Run `tests/office_surface_bank_test.gd` to compare every baked byte with the
procedural source. Runtime generation remains the fallback for missing resources.
Web review panels are constructed on first display and reused; the Office
applies the current explicit font scale through `review_surface_built`.
`tests/probation_campaign_ui_test.gd` exercises the lazy policy by default,
and `tests/office_startup_residency_test.gd` verifies first-use scaling and reuse.

The 2026-11-07 constructor-bind fix reduced measured engine entry from 3.05s to
1.08s and program-query waits from about 2.2s to 0.13s. Three isolated local
RTX 3090/D3D11 cold-browser runs improved from a 9.61s median to 7.65s; final
samples were 8.51s, 7.58s, 7.65s. Reload medians were effectively unchanged.
The production wrapper primes its existing gzip response cache before listening,
so the first player does not wait for on-demand compression of WASM and PCK.
These measurements do not imply the same timings on other devices or renderers.

## First-use gameplay shader preparation

The manifest also contains validated `gameplay` programs captured during live
play with `flow-polish-performance-audit.mjs --profile-shaders`. The shader audit
records actual vertex/fragment types, exact sources, attribute bindings,
transform feedback, and existing link-status checks; it performs no extra GPU
queries. Prepare the opening manifest first so live captures record the current
runtime key, then pass each successful capture to `prepare_web_startup.mjs` using
`--gameplay=PATH`. Captures must match the exported WASM+PCK hash and quality.

These programs compile in parallel with startup alongside the opening shaders.
`finishStartup()` releases unused opening programs but keeps the small gameplay
pool until first use. Identical source requested by separate engine programs
gets independently owned program/stage copies with independent uniforms, based
on the maximum observed multiplicity across captures. Limits are four copies
per variant, 24 retained gameplay programs and 96 total prepared programs per
quality. The pool never refills or grows during play. A drained pool removes its
hooks after the current adoption; context loss and teardown release all unused
resources. Unknown or exhausted variants still use native checked compilation.
No shader source, material, visual effect or gameplay behavior is changed.

The previous startup-only pool was discarded after the first frames. Traces
showed later color-batch lighting and reward-label variants blocking game frames
in LINK_STATUS for 75-254ms. Preparing these exact first-use programs addresses
those stalls rather than reducing image quality. Keep shader capture and CPU
profiling runs separate from uninstrumented frame-pacing comparisons.
