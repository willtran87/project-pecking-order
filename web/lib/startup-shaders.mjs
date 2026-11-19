// The bounded warm-up pool owns these programs until first use. Once adopted, the engine owns the actual
// WebGLProgram (including its uniforms and deletion), with no rendering proxy.
export const GODOT_CONTEXT_ATTRIBUTES = Object.freeze({
  alpha: false, depth: true, stencil: false, antialias: false,
  premultipliedAlpha: true, preserveDrawingBuffer: false,
  powerPreference: 'default', failIfMajorPerformanceCaveat: false,
});

export async function fetchStartupShaders(signal) {
  if (typeof DecompressionStream === 'undefined') return null;
  try {
    const response = await fetch('/game/index.startup-shaders.json.gz', { signal });
    if (!response.ok || !response.body) return null;
    return await new Response(response.body.pipeThrough(new DecompressionStream('gzip'))).json();
  } catch { return null; }
}

function programKey(vertex, fragment, attributes, feedback) {
  return JSON.stringify([vertex, fragment, [...attributes].sort((a, b) => a[1].localeCompare(b[1])), feedback]);
}

export function prepareStartupShaders(canvas, manifest, runtimeKey, quality = 'balanced') {
  try { return prepare(canvas, manifest, runtimeKey, quality); }
  catch { return null; }
}

function prepare(canvas, manifest, runtimeKey, quality) {
  if (manifest?.qualityPrograms) {
    const selected = manifest.qualityPrograms[quality];
    if (!Array.isArray(selected)) return null;
    manifest = { ...manifest, programs: selected };
  } else if (quality !== 'balanced') return null;
  if (typeof runtimeKey !== 'string' || !runtimeKey || !manifest
    || ![1, 2].includes(manifest.schema) || manifest.runtimeKey !== runtimeKey
    || !Array.isArray(manifest.programs) || manifest.programs.length > 96) return null;
  if (manifest.schema === 2) {
    if (!Array.isArray(manifest.strings) || manifest.strings.length > 30000
      || manifest.strings.some(s => typeof s !== 'string')
      || manifest.strings.reduce((n, s) => n + s.length, 0) > 2 * 1024 * 1024) return null;
    const decode = indices => {
      if (!Array.isArray(indices) || indices.length > 20000
        || indices.some(i => !Number.isInteger(i) || i < 0 || i >= manifest.strings.length)) return null;
      return indices.map(i => manifest.strings[i]).join('');
    };
    manifest = { ...manifest, programs: manifest.programs.map(p => ({
      ...p, vertex: decode(p.vertex), fragment: decode(p.fragment),
    })) };
  }
  let bytes = 0;
  if (manifest.programs.some(p => !Number.isInteger(p?.copies ?? 1) || (p.copies ?? 1) < 1 || (p.copies ?? 1) > 4)
    || manifest.programs.reduce((n, p) => n + (p.copies ?? 1), 0) > 96
    || manifest.programs.filter(p => p?.gameplay === true).reduce((n, p) => n + (p.copies ?? 1), 0) > 24) return null;
  for (const p of manifest.programs) {
    if (typeof p.vertex !== 'string' || typeof p.fragment !== 'string'
      || !Array.isArray(p.attributes) || p.attributes.some(a => !Array.isArray(a)
        || !Number.isInteger(a[0]) || a[0] < 0 || typeof a[1] !== 'string')
      || (p.feedback !== null && (!Array.isArray(p.feedback) || !Array.isArray(p.feedback[0])
        || p.feedback[0].some(v => typeof v !== 'string') || ![35980, 35981].includes(p.feedback[1])))) return null;
    bytes += (p.vertex.length + p.fragment.length) * (p.copies ?? 1);
  }
  if (bytes > 16 * 1024 * 1024) return null;
  const gl = canvas.getContext('webgl2', GODOT_CONTEXT_ATTRIBUTES);
  if (!gl || gl.isContextLost() || !gl.getExtension('KHR_parallel_shader_compile')) return null;
  const rendererInfo = gl.getExtension('WEBGL_debug_renderer_info');
  const renderer = Number.isInteger(rendererInfo?.UNMASKED_RENDERER_WEBGL)
    ? String(gl.getParameter(rendererInfo.UNMASKED_RENDERER_WEBGL)) : '';
  // CPU renderers share the same CPU budget as WASM initialization. Matched
  // cold tests are faster with their normal on-demand compilation path.
  if (/swiftshader|llvmpipe|softpipe|software rasterizer|basic render driver/i.test(renderer)) return null;
  const pool = new Map(), originals = new Map();
  const poolSize = () => [...pool.values()].reduce((n, copies) => n + copies.length, 0);
  const shaders = new WeakMap(), records = new WeakMap();
  const pendingStages = new Set();
  const knownSources = new Map([[gl.VERTEX_SHADER, new Set()], [gl.FRAGMENT_SHADER, new Set()]]);
  const compile = gl.compileShader.bind(gl);
  const metrics = { prepared: 0, hits: 0, misses: 0, rejected: 0, released: 0, closed: false, gameplayHits: 0, retained: 0 };
  let startupFinished = false;
  const info = p => {
    if (!records.has(p)) records.set(p, { shaders: new Map(), attributes: new Map(), feedback: null });
    return records.get(p);
  };
  function wrap(name, callback) {
    const own = Object.getOwnPropertyDescriptor(gl, name);
    const original = gl[name];
    const replacement = callback(original.bind(gl));
    originals.set(name, { own, replacement });
    gl[name] = replacement;
  }
  function close() {
    if (metrics.closed) return;
    metrics.closed = true;
    // A stage created before cleanup may be linked by Godot later. Compile
    // these unmatched stages before removing the optional bridge.
    if (!gl.isContextLost()) for (const stage of pendingStages) compile(stage.shader);
    pendingStages.clear(); knownSources.clear();
    for (const copies of pool.values()) for (const p of copies) {
      gl.deleteProgram(p.program); gl.deleteShader(p.vertex); gl.deleteShader(p.fragment); metrics.released++;
    }
    pool.clear();
    metrics.retained = 0;
    for (const [name, { own, replacement }] of originals) {
      if (gl[name] !== replacement) continue;
      if (own) Object.defineProperty(gl, name, own); else delete gl[name];
    }
    originals.clear();
    canvas.removeEventListener('webglcontextlost', close);
  }
  try {
    for (const p of manifest.programs) {
      const key = programKey(p.vertex, p.fragment, p.attributes, p.feedback);
      if (pool.has(key)) continue;
      const copies = [];
      pool.set(key, copies);
      // Equal source does not imply shared uniforms: every engine program
      // receives its own prepared program and shader handles.
      for (let copy = 0; copy < (p.copies ?? 1); copy++) {
        const vertex = gl.createShader(gl.VERTEX_SHADER), fragment = gl.createShader(gl.FRAGMENT_SHADER);
        const program = gl.createProgram();
        if (!vertex || !fragment || !program) {
          if (vertex) gl.deleteShader(vertex);
          if (fragment) gl.deleteShader(fragment);
          if (program) gl.deleteProgram(program);
          close(); return null;
        }
        gl.shaderSource(vertex, p.vertex); gl.compileShader(vertex);
        gl.shaderSource(fragment, p.fragment); gl.compileShader(fragment);
        gl.attachShader(program, vertex); gl.attachShader(program, fragment);
        for (const [index, name] of p.attributes) gl.bindAttribLocation(program, index, name);
        if (p.feedback) gl.transformFeedbackVaryings(program, ...p.feedback);
        gl.linkProgram(program);
        copies.push({ program, vertex, fragment, gameplay: p.gameplay === true, vertexSource: p.vertex, fragmentSource: p.fragment }); metrics.prepared++;
      }
      knownSources.get(gl.VERTEX_SHADER).add(p.vertex);
      knownSources.get(gl.FRAGMENT_SHADER).add(p.fragment);
    }
    gl.flush();
    wrap('createShader', original => type => {
      const shader = original(type);
      if (shader) shaders.set(shader, { type, source: '', shader, id: undefined });
      return shader;
    });
    wrap('shaderSource', original => (shader, source) => {
      const record = shaders.get(shader);
      if (record) record.source = source;
      return original(shader, source);
    });
    for (const name of ['getShaderParameter', 'getShaderInfoLog']) {
      wrap(name, original => (shader, ...args) => {
        const stage = shaders.get(shader);
        if (stage && pendingStages.delete(stage)) compile(shader);
        return original(shader, ...args);
      });
    }
    wrap('attachShader', original => (p, shader) => {
      const record = shaders.get(shader);
      if (record) info(p).shaders.set(shader, record);
      return original(p, shader);
    });
    wrap('detachShader', original => (p, shader) => {
      records.get(p)?.shaders.delete(shader);
      return original(p, shader);
    });
    wrap('bindAttribLocation', original => (p, index, name) => {
      info(p).attributes.set(name, index);
      return original(p, index, name);
    });
    wrap('transformFeedbackVaryings', original => (p, varyings, mode) => {
      info(p).feedback = [[...varyings], mode];
      return original(p, varyings, mode);
    });
    canvas.addEventListener('webglcontextlost', close);
    return {
      metrics, close,
      finishStartup() {
        if (metrics.closed || startupFinished) return;
        startupFinished = true;
        // First-use gameplay programs must survive the loading screen. Release
        // unused opening variants immediately; the retained pool never grows.
        for (const [key, copies] of pool) {
          if (copies[0]?.gameplay) continue;
          for (const p of copies) {
            gl.deleteProgram(p.program); gl.deleteShader(p.vertex); gl.deleteShader(p.fragment);
            metrics.released++;
          }
          pool.delete(key);
        }
        for (const sources of knownSources.values()) sources.clear();
        for (const copies of pool.values()) for (const p of copies) {
          knownSources.get(gl.VERTEX_SHADER).add(p.vertexSource);
          knownSources.get(gl.FRAGMENT_SHADER).add(p.fragmentSource);
        }
        metrics.retained = poolSize();
        if (!pool.size) close();
      },
      deferCompile(context, shader, id) {
        if (metrics.closed || context !== gl || gl.isContextLost()) return false;
        const stage = shaders.get(shader);
        if (!stage) return false;
        stage.id = id;
        if (!knownSources.get(stage.type)?.has(stage.source)) return false;
        pendingStages.add(stage);
        return true;
      },
      take(context, originalProgram) {
        if (metrics.closed || context !== gl || gl.isContextLost()) return null;
        const record = records.get(originalProgram);
        if (!record) return null;
        const stages = [...record.shaders.values()];
        const fallback = () => {
          for (const stage of stages) if (pendingStages.delete(stage)) compile(stage.shader);
          return null;
        };
        if (stages.length !== 2) return fallback();
        const vertex = stages.find(s => s.type === gl.VERTEX_SHADER);
        const fragment = stages.find(s => s.type === gl.FRAGMENT_SHADER);
        if (!vertex || !fragment) return fallback();
        const key = programKey(vertex.source, fragment.source,
          [...record.attributes].map(([name, index]) => [index, name]), record.feedback);
        const copies = pool.get(key);
        const prepared = copies?.shift();
        records.delete(originalProgram);
        if (!prepared) { metrics.misses++; return fallback(); }
        if (!copies.length) pool.delete(key);
        if (startupFinished) metrics.retained = poolSize();
        if (startupFinished && !pool.size) queueMicrotask(close);
        // A failed warm-up must fall back to Godot's original compile/link and
        // error-reporting path. Godot also validates every adopted program.
        if (!gl.getProgramParameter(prepared.program, gl.LINK_STATUS)) {
          gl.deleteProgram(prepared.program); gl.deleteShader(prepared.vertex); gl.deleteShader(prepared.fragment);
          metrics.rejected++; return fallback();
        }
        // Transfer stage handles as well as the program. This prevents duplicate
        // compilation and preserves Godot's later shader queries/deletion.
        if (stages.every(stage => Number.isInteger(stage.id))) {
          prepared.program.__pecking_order_shader_stages = stages.map(stage => ({
            id: stage.id, original: stage.shader,
            shader: stage.type === gl.VERTEX_SHADER ? prepared.vertex : prepared.fragment,
          }));
          for (const stage of stages) pendingStages.delete(stage);
        } else {
          fallback();
          gl.deleteShader(prepared.vertex); gl.deleteShader(prepared.fragment);
        }
        metrics.hits++;
        if (prepared.gameplay) metrics.gameplayHits++;
        return prepared.program;
      },
    };
  } catch {
    close(); return null;
  }
}
