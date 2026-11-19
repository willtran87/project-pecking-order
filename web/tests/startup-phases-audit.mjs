import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import { chromium } from 'playwright';

const output = path.resolve(process.argv[2] ?? '../output/web-game/startup-phases');
fs.mkdirSync(output, { recursive: true });
const backend = process.env.WEBGL_BACKEND === 'd3d11' ? 'd3d11' : 'swiftshader';
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', `--use-angle=${backend}`] });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const errors = [];
page.on('pageerror', error => errors.push(String(error)));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
if (process.env.STARTUP_PREFERENCES) {
  const payload = fs.readFileSync(path.resolve(process.env.STARTUP_PREFERENCES), 'utf8');
  await page.addInitScript(value => localStorage.setItem('pecking-order.player-preferences', value), payload);
}
if (process.env.STARTUP_GAME_DIR) {
  const directory = path.resolve(process.env.STARTUP_GAME_DIR);
  await page.route('**/game/*', route => {
    const name = new URL(route.request().url()).pathname.split('/').pop();
    const asset = path.join(directory, name);
    if (!fs.existsSync(asset)) return route.continue();
    const type = name.endsWith('.wasm') ? 'application/wasm'
      : name.endsWith('.js') ? 'text/javascript'
      : name.endsWith('.html') ? 'text/html' : 'application/octet-stream';
    return route.fulfill({ body: fs.readFileSync(asset), contentType: type });
  });
}
// Compare exported packages against the same wrapper and engine without
// replacing the user's running preview or changing the gameplay entry point.
if (process.env.STARTUP_PCK_PATH) {
  const body = fs.readFileSync(path.resolve(process.env.STARTUP_PCK_PATH));
  await page.route('**/game/index.pck', route => route.fulfill({
    body, headers: { 'content-type': 'application/octet-stream' },
  }));
}
await page.addInitScript(() => {
  window.__startupPhases = [];
  window.__graphicsStartup = {};
  window.__shaderFailures = [];
  window.__startupShaderSources = [];
  window.__startupPrograms = [];
  const sourcesByShader = new WeakMap(), programInfo = new WeakMap();
  const info = program => { if (!programInfo.has(program)) programInfo.set(program, { sources: [], attributes: [], feedback: null }); return programInfo.get(program); };
  for (const name of ['attachShader', 'bindAttribLocation', 'transformFeedbackVaryings', 'linkProgram']) {
    const method = WebGL2RenderingContext.prototype[name];
    WebGL2RenderingContext.prototype[name] = function(program, ...args) {
      const record = info(program);
      if (name === 'attachShader') record.sources.push(sourcesByShader.get(args[0]));
      if (name === 'bindAttribLocation') record.attributes.push(args);
      if (name === 'transformFeedbackVaryings') record.feedback = args;
      if (name === 'linkProgram') window.__startupPrograms.push(structuredClone(record));
      return method.call(this, program, ...args);
    };
  }
  const shaderSource = WebGL2RenderingContext.prototype.shaderSource;
  WebGL2RenderingContext.prototype.shaderSource = function (shader, source) {
    sourcesByShader.set(shader, source);
    window.__startupShaderSources.push(source);
    return shaderSource.call(this, shader, source);
  };
  for (const name of ['compileShader', 'linkProgram', 'getProgramParameter', 'getShaderParameter', 'texImage2D', 'bufferData', 'drawElements', 'drawArrays', 'drawElementsInstanced', 'drawArraysInstanced', 'finish', 'getUniformLocation']) {
    const original = WebGL2RenderingContext.prototype[name];
    WebGL2RenderingContext.prototype[name] = function (...args) {
      const start = performance.now();
      try {
        const value = original.apply(this, args);
        if ((name === 'getShaderParameter' && args[1] === this.COMPILE_STATUS && !value)
          || (name === 'getProgramParameter' && args[1] === this.LINK_STATUS && !value)) {
          window.__shaderFailures.push(name);
        }
        return value;
      }
      finally {
        const elapsed = performance.now() - start;
        const metric = window.__graphicsStartup[name] ??= { calls: 0, totalMs: 0, maxMs: 0 };
        metric.calls++; metric.totalMs += elapsed; metric.maxMs = Math.max(metric.maxMs, elapsed);
      }
    };
  }
  for (const name of ['compile', 'compileStreaming', 'instantiate', 'instantiateStreaming']) {
    const original = WebAssembly[name];
    WebAssembly[name] = async function (...args) {
      const start = performance.now();
      try { return await original.apply(WebAssembly, args); }
      finally { window.__startupPhases.push({ name, start, end: performance.now() }); }
    };
  }
  new PerformanceObserver(list => {
    for (const entry of list.getEntries()) window.__startupPhases.push({ name: 'longtask', start: entry.startTime, end: entry.startTime + entry.duration });
  }).observe({ type: 'longtask', buffered: true });
});
try {
  await page.goto(process.env.STARTUP_URL ?? 'http://localhost:3001/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text?.() ?? '{}').loaded === true, null, { timeout: 120000 });
  const result = await page.evaluate(() => ({
    ready: performance.now(), shaderWarmup: window.__pecking_order_shader_metrics, phases: window.__startupPhases, engineInit: window.__engineInitProbe, graphics: window.__graphicsStartup,
    state: JSON.parse(window.render_game_to_text()),
    renderer: (() => {
      const gl = document.querySelector('canvas')?.getContext('webgl2');
      const debug = gl?.getExtension('WEBGL_debug_renderer_info');
      return debug ? gl.getParameter(debug.UNMASKED_RENDERER_WEBGL) : null;
    })(),
    shaders: window.__startupShaderSources, programs: window.__startupPrograms,
    shaderFailures: window.__shaderFailures,
    resources: performance.getEntriesByType('resource').filter(e => e.name.includes('/game/')).map(e => ({ name: e.name, start: e.startTime, end: e.responseEnd, bytes: e.transferSize })),
  }));
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify({ ...result, errors }, null, 2));
  console.log(JSON.stringify({ ready: result.ready, phases: result.phases, engineInit: result.engineInit, graphics: result.graphics, boot: result.state.boot, resources: result.resources, errors }, null, 2));
  assert.deepEqual(errors, [], 'Engine startup must have no browser or engine errors');
  assert.deepEqual(result.shaderFailures, [], 'Every requested shader must compile and link successfully');
  assert.ok(result.state.boot?.ready > 0, 'Ready must mean the actual office initialized');
  if (process.env.STARTUP_SCREENSHOT) {
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(output, 'ready.png'), fullPage: true });
  }
} finally { await browser.close(); }
