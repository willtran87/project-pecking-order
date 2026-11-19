import test from 'node:test';
import assert from 'node:assert/strict';
import vm from 'node:vm';
import { prepareStartupShaders, GODOT_CONTEXT_ATTRIBUTES } from '../lib/startup-shaders.mjs';
import { adoptedLink, deferredCompile, addGameplayPrograms } from '../../tools/prepare_web_startup.mjs';

function fixture({ supported = true, failed = false } = {}) {
  const deleted = [], deletedShaders = [], listeners = new Map();
  const gl = {
    VERTEX_SHADER: 35633, FRAGMENT_SHADER: 35632, LINK_STATUS: 35714,
    isContextLost: () => false, getExtension: () => supported ? {} : null,
    createShader: type => ({ type }), shaderSource: (s, source) => { s.source = source; },
    compileShader: shader => { shader.compiled = true; }, deleteShader: shader => deletedShaders.push(shader),
    getShaderParameter: shader => Boolean(shader.compiled), getShaderInfoLog: () => '',
    createProgram: () => ({ attached: [], links: 0 }),
    attachShader: (p, s) => p.attached.push(s), detachShader() {},
    bindAttribLocation() {}, transformFeedbackVaryings() {}, flush() {},
    linkProgram: p => { p.links++; p.valid = !failed; },
    getProgramParameter: p => p.valid, deleteProgram: p => deleted.push(p),
  };
  let contexts = 0;
  const canvas = {
    getContext(type, attributes) { contexts++; assert.equal(type, 'webgl2'); assert.deepEqual(attributes, GODOT_CONTEXT_ATTRIBUTES); return gl; },
    addEventListener: (type, fn) => listeners.set(type, fn),
    removeEventListener: type => listeners.delete(type),
  };
  const item = { vertex: 'vertex', fragment: 'fragment', attributes: [[0, 'position']], feedback: [['out_position'], 35980] };
  const manifest = { schema: 1, runtimeKey: 'same-runtime', programs: [item] };
  function request({ fragment = 'fragment', index = 0, feedback = 'out_position', startup } = {}) {
    const vertex = gl.createShader(gl.VERTEX_SHADER), frag = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(vertex, 'vertex'); gl.shaderSource(frag, fragment);
    if (startup) vm.runInNewContext(deferredCompile + '_emscripten_glCompileShader(11);_emscripten_glCompileShader(12)', {
      GL: { shaders: { 11: vertex, 12: frag } }, GLctx: gl, __pecking_order_shader_startup: startup,
    });
    const p = gl.createProgram(); gl.attachShader(p, frag); gl.attachShader(p, vertex);
    gl.bindAttribLocation(p, index, 'position');
    gl.transformFeedbackVaryings(p, [feedback], 35980);
    return p;
  }
  return { gl, canvas, manifest, request, deleted, deletedShaders, listeners, contexts: () => contexts };
}

test('first-use gameplay programs survive startup and transfer ownership exactly once', async () => {
  const f = fixture();
  f.manifest.programs.push({ ...f.manifest.programs[0], fragment: 'reward-fragment', gameplay: true });
  const startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
  startup.finishStartup(); startup.finishStartup();
  assert.equal(startup.metrics.released, 1);
  assert.equal(startup.metrics.retained, 1);
  assert.equal(startup.metrics.closed, false);
  const request = f.request({ startup, fragment: 'reward-fragment' });
  assert.ok(request.attached.every(s => !s.compiled), 'prepared gameplay stages must not compile twice');
  const adopted = startup.take(f.gl, request);
  assert.ok(adopted && adopted.links === 1);
  assert.equal(startup.metrics.gameplayHits, 1);
  assert.equal(startup.metrics.retained, 0);
  await Promise.resolve();
  assert.equal(startup.metrics.closed, true, 'drained pools remove their hooks after the engine adopts the last program');
  assert.ok(!f.deleted.includes(adopted), 'cleanup must not delete engine-owned programs');
  assert.equal(startup.take(f.gl, f.request({ fragment: 'reward-fragment' })), null);
});

test('retained gameplay pool is bounded and released on teardown or context loss', () => {
  for (const contextLoss of [false, true]) {
    const f = fixture(); f.manifest.programs[0].gameplay = true;
    const startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
    startup.finishStartup();
    if (contextLoss) f.listeners.get('webglcontextlost')(); else startup.close();
    assert.equal(startup.metrics.closed, true);
    assert.equal(startup.metrics.retained, 0);
    assert.equal(startup.metrics.released, 1);
    assert.equal(f.deletedShaders.length, 2);
    assert.equal(f.listeners.size, 0);
  }
  const f = fixture();
  f.manifest.programs = Array.from({ length: 25 }, (_, i) => ({ ...f.manifest.programs[0], fragment: `f${i}`, gameplay: true }));
  assert.equal(prepareStartupShaders(f.canvas, f.manifest, 'same-runtime'), null);
  assert.equal(f.contexts(), 0);
});

test('identical gameplay sources keep independent program, shader and uniform ownership', async () => {
  const f = fixture(); f.manifest.programs[0] = { ...f.manifest.programs[0], gameplay: true, copies: 2 };
  const startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
  startup.finishStartup();
  assert.equal(startup.metrics.retained, 2);
  const first = startup.take(f.gl, f.request({ startup }));
  first.uniformLocsById = { 3: 'first-program-location' };
  assert.equal(startup.metrics.retained, 1);
  const second = startup.take(f.gl, f.request({ startup }));
  assert.notEqual(first, second);
  assert.notEqual(first.attached[0], second.attached[0]);
  assert.equal(second.uniformLocsById, undefined);
  assert.equal(startup.metrics.gameplayHits, 2);
  await Promise.resolve();
  assert.equal(startup.metrics.closed, true);
  assert.equal(f.deleted.length, 0, 'both copies now belong to the engine');
});

test('gameplay captures match runtime and quality, deduplicate sources and reject failed linking', () => {
  const item = { vertex: 'gl_Position = position;', fragment: 'fragment', attributes: [], feedback: null };
  const capture = { runtimeKey: 'runtime', quality: 'balanced', errors: [], programs: [
    { ...item, sources: [item.fragment, item.vertex] },
    { ...item, fragment: 'reward', sources: [item.vertex, 'reward'] },
  ], checks: [{ index: 0, success: true }, { index: 1, success: true }] };
  const qualities = { balanced: [item] };
  addGameplayPrograms(qualities, [capture, capture], 'runtime');
  assert.equal(qualities.balanced.length, 2);
  assert.equal(qualities.balanced[1].gameplay, true);
  assert.equal(qualities.balanced[1].fragment, 'reward');
  const repeated = { ...capture, programs: [...capture.programs, capture.programs[1]], checks: [...capture.checks, { index: 2, success: true }] };
  addGameplayPrograms(qualities, [repeated, repeated], 'runtime');
  assert.equal(qualities.balanced[1].copies, 2, 'capture repeats set maximum copies, not an ever-growing sum');
  for (const changed of [{ runtimeKey: 'stale' }, { quality: 'unknown' }, { errors: ['compile failed'] }, { checks: [{ index: 1, success: false }] }]) {
    assert.throws(() => addGameplayPrograms({ balanced: [item] }, [{ ...capture, ...changed }], 'runtime'));
  }
  assert.throws(() => addGameplayPrograms({ balanced: [item] }, [{ ...capture, programs: [{ sources: ['fragment', item.vertex] }] }], 'runtime'));
});

test('adoption transfers the actual program to Emscripten with its handle and uniforms intact', () => {
  const f = fixture(), startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
  const original = f.request({ startup }); original.name = 7;
  original.uniformIdCounter = 1;
  original.maxUniformLength = original.maxAttributeLength = original.maxUniformBlockNameLength = 0;
  const originalVertex = original.attached.find(s => s.type === f.gl.VERTEX_SHADER);
  const originalFragment = original.attached.find(s => s.type === f.gl.FRAGMENT_SHADER);
  const GL = { programs: { 7: original }, shaders: { 11: originalVertex, 12: originalFragment } };
  assert.equal(originalVertex.compiled, undefined, 'known stages must not compile twice');
  const scope = { GL, GLctx: f.gl, __pecking_order_shader_startup: startup };
  vm.runInNewContext(adoptedLink + '_emscripten_glLinkProgram(7)', scope);
  const adopted = GL.programs[7];
  assert.notEqual(adopted, original);
  assert.equal(adopted.name, 7);
  assert.equal(adopted.uniformIdCounter, 1);
  assert.equal(adopted.maxUniformLength, 0);
  assert.equal(adopted.maxAttributeLength, 0);
  assert.equal(adopted.maxUniformBlockNameLength, 0);
  assert.equal(adopted.links, 1, 'prepared program must never be relinked');
  assert.equal(adopted.uniformLocsById, 0);
  assert.deepEqual(Object.keys(adopted.uniformSizeAndIdsByName), []);
  assert.deepEqual(f.deleted, [original]);
  assert.equal(startup.metrics.hits, 1);
  assert.notEqual(GL.shaders[11], originalVertex);
  assert.notEqual(GL.shaders[12], originalFragment);
  assert.equal(GL.shaders[11].compiled, true);
  assert.equal(GL.shaders[12].compiled, true);
  assert.deepEqual(f.deletedShaders, [originalFragment, originalVertex]);
  startup.close(); startup.close();
  assert.deepEqual(f.deleted, [original], 'cleanup must not delete engine-owned programs');
  assert.equal(startup.metrics.closed, true);
});

test('deferred stages compile on cache misses, explicit diagnostics, or cleanup', () => {
  for (const mode of ['miss', 'diagnostic', 'cleanup']) {
    const f = fixture(), startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
    const original = f.request({ startup, index: mode === 'miss' ? 2 : 0 });
    const vertex = original.attached.find(s => s.type === f.gl.VERTEX_SHADER);
    assert.equal(vertex.compiled, undefined);
    if (mode === 'miss') assert.equal(startup.take(f.gl, original), null);
    if (mode === 'diagnostic') assert.equal(f.gl.getShaderParameter(vertex, 35713), true);
    if (mode === 'cleanup') startup.close();
    assert.equal(vertex.compiled, true);
    startup.close();
  }
});

test('changed source, bindings, feedback and contexts take the normal path', () => {
  const f = fixture(), startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
  for (const change of [{ fragment: 'changed' }, { index: 2 }, { feedback: 'different' }]) {
    assert.equal(startup.take(f.gl, f.request(change)), null);
  }
  assert.equal(startup.take({}, f.request()), null);
  assert.equal(startup.metrics.hits, 0);
  startup.close(); assert.equal(startup.metrics.released, 1);
});

test('failed preparation falls back to native linking and retains error checks', () => {
  const f = fixture({ failed: true }), startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
  const original = f.request({ startup }), GL = { programs: { 1: original } };
  vm.runInNewContext(adoptedLink + '_emscripten_glLinkProgram(1)', { GL, GLctx: f.gl, __pecking_order_shader_startup: startup });
  assert.equal(GL.programs[1], original); assert.equal(original.links, 1);
  assert.ok(original.attached.every(shader => shader.compiled), 'failed warm-up must compile the original stages before linking');
  assert.equal(f.gl.getProgramParameter(original, f.gl.LINK_STATUS), false);
  assert.equal(startup.metrics.rejected, 1); startup.close();
});

test('unpatched pages, stale manifests, malformed data and unsupported browsers safely fall back', () => {
  const f = fixture();
  for (const manifest of [null, { ...f.manifest, runtimeKey: 'stale' }, { ...f.manifest, programs: [{}] },
    { ...f.manifest, programs: [null] },
    { schema: 2, runtimeKey: 'same-runtime', strings: ['v'], programs: [{ vertex: [99], fragment: [0], attributes: [], feedback: null }] }]) {
    assert.equal(prepareStartupShaders(f.canvas, manifest, 'same-runtime'), null);
  }
  assert.equal(f.contexts(), 0);
  assert.equal(prepareStartupShaders(f.canvas, f.manifest, undefined), null);
  const p = f.request(), GL = { programs: { 1: p } };
  vm.runInNewContext(adoptedLink + '_emscripten_glLinkProgram(1)', { GL, GLctx: f.gl });
  assert.equal(p.links, 1);
  const unsupported = fixture({ supported: false });
  assert.equal(prepareStartupShaders(unsupported.canvas, unsupported.manifest, 'same-runtime'), null);
});

test('unused resources and hooks are released on context loss', () => {
  const f = fixture(), original = f.gl.shaderSource;
  const startup = prepareStartupShaders(f.canvas, f.manifest, 'same-runtime');
  assert.notEqual(f.gl.shaderSource, original);
  f.listeners.get('webglcontextlost')();
  assert.equal(f.gl.shaderSource, original);
  assert.equal(startup.metrics.released, 1);
  assert.equal(startup.take(f.gl, f.request()), null);
  assert.equal(f.listeners.size, 0);
});

test('only the selected quality programs are prepared; missing quality stays on the normal path', () => {
  const f = fixture();
  const high = { ...f.manifest.programs[0], fragment: 'high detail' };
  const manifest = { ...f.manifest, qualityPrograms: { balanced: f.manifest.programs, high: [high] } };
  assert.equal(prepareStartupShaders(f.canvas, manifest, 'same-runtime', 'low'), null);
  const startup = prepareStartupShaders(f.canvas, manifest, 'same-runtime', 'high');
  assert.equal(startup.metrics.prepared, 1);
  assert.equal(startup.take(f.gl, f.request()), null);
  assert.ok(startup.take(f.gl, f.request({ fragment: 'high detail' })));
  assert.equal(startup.metrics.hits, 1); startup.close();
});

test('software rendering keeps the measured faster on-demand path', () => {
  const f = fixture();
  f.gl.getExtension = name => name === 'WEBGL_debug_renderer_info' ? { UNMASKED_RENDERER_WEBGL: 37446 } : {};
  f.gl.getParameter = () => 'ANGLE (Google, Vulkan SwiftShader Device, SwiftShader driver)';
  let programs = 0; f.gl.createProgram = () => { programs++; return {}; };
  assert.equal(prepareStartupShaders(f.canvas, f.manifest, 'same-runtime'), null);
  assert.equal(programs, 0);
});
