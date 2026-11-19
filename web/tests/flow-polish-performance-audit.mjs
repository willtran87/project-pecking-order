import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

// Compare exported packages in isolated browser processes against the same
// wrapper. Identical interception keeps asset transport comparable; these are
// local regression samples, not representative-device performance claims.
const before = path.resolve(process.argv[2] ?? '../output/flow-before-runtime');
const after = path.resolve('../docs');
const output = path.resolve(process.argv[3] ?? '../output/web-game/flow-polish-performance');
const sampleArg = process.argv.find(arg => arg.startsWith('--sample-ms='));
const sampleMs = sampleArg ? Number(sampleArg.split('=')[1]) : 5000;
assert.ok(Number.isFinite(sampleMs) && sampleMs >= 1000 && sampleMs <= 15000);
fs.mkdirSync(output, { recursive: true });
const runs = [];
const profileCosts = process.argv.includes('--profile-costs');
// Diagnostic traces perturb timings; keep them opt-in and separate from ABBA results.
const traceFrames = process.argv.includes('--trace-frames');
const profileEngine = process.argv.includes('--profile-engine');
const profileShaders = process.argv.includes('--profile-shaders');
const warmupMs = Number(process.argv.find(arg => arg.startsWith('--warmup-ms='))?.split('=')[1] ?? 1500);
assert.ok(Number.isFinite(warmupMs) && warmupMs >= 0 && warmupMs <= 30000);
const laterShift = process.argv.includes("--later-shift");
const earnedOffice = process.argv.includes('--earned-office');
assert.ok(!(laterShift && earnedOffice), 'Select one live office scenario');
const labels = process.argv.find(arg => arg.startsWith('--runs='))?.split('=')[1].split(',') ?? ['before', 'after', 'after', 'before'];
assert.ok(labels.length > 0 && labels.every(label => ['before', 'after'].includes(label)));
for (const label of labels) {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
  const errors = [];
  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
    const preferencesPath = process.argv.find(arg => arg.startsWith('--preferences='))?.slice('--preferences='.length);
    if (preferencesPath) await page.addInitScript(value => localStorage.setItem('pecking-order.player-preferences', value), fs.readFileSync(path.resolve(preferencesPath), 'utf8'));
    page.on('pageerror', e => errors.push(String(e)));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    if (profileShaders) await page.addInitScript(() => {
      const shaders = new WeakMap(), records = new WeakMap();
      window.__gameplayShaderCapture = { programs: [], checks: [] };
      const createShader = WebGL2RenderingContext.prototype.createShader;
      WebGL2RenderingContext.prototype.createShader = function (type) {
        const shader = createShader.call(this, type);
        if (shader) shaders.set(shader, { type, source: '' });
        return shader;
      };
      const info = program => {
        if (!records.has(program)) records.set(program, { stages: [], attributes: [], feedback: null, index: -1 });
        return records.get(program);
      };
      for (const name of ['shaderSource', 'attachShader', 'bindAttribLocation', 'transformFeedbackVaryings', 'linkProgram', 'getProgramParameter']) {
        const original = WebGL2RenderingContext.prototype[name];
        WebGL2RenderingContext.prototype[name] = function (object, ...args) {
          if (name === 'shaderSource') shaders.get(object).source = args[0];
          else if (name === 'attachShader') info(object).stages.push(shaders.get(args[0]));
          else if (name === 'bindAttribLocation') info(object).attributes.push(args);
          else if (name === 'transformFeedbackVaryings') info(object).feedback = args;
          else if (name === 'linkProgram') {
            const record = info(object);
            record.index = window.__gameplayShaderCapture.programs.length;
            window.__gameplayShaderCapture.programs.push({ sources: record.stages.map(s => s.source), vertex: record.stages.find(s => s.type === this.VERTEX_SHADER)?.source, fragment: record.stages.find(s => s.type === this.FRAGMENT_SHADER)?.source, attributes: record.attributes, feedback: record.feedback, at: performance.now() });
          }
          const started = performance.now();
          const result = original.call(this, object, ...args);
          if (name === 'getProgramParameter' && args[0] === this.LINK_STATUS) {
            window.__gameplayShaderCapture.checks.push({ index: info(object).index, at: started, ms: performance.now() - started, success: !!result });
          }
          return result;
        };
      }
    });
    await page.route('**/game/*', route => {
      const name = new URL(route.request().url()).pathname.split('/').pop();
      const file = path.join(label === 'before' ? before : after, name);
      if (!fs.existsSync(file)) return route.continue();
      return route.fulfill({ body: fs.readFileSync(file), contentType: name.endsWith('.wasm') ? 'application/wasm' : name.endsWith('.js') ? 'text/javascript' : name.endsWith('.html') ? 'text/html' : 'application/octet-stream' });
    });
    const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text()));
    const wait = async predicate => {
      const end = Date.now() + 120000;
      while (Date.now() < end) { const s = await state(); if (predicate(s)) return s; await page.waitForTimeout(100); }
      fs.writeFileSync(path.join(output, `${runs.length}-${label}-failure.json`), JSON.stringify({ state: await state(), errors }, null, 2));
      await page.screenshot({ path: path.join(output, `${runs.length}-${label}-failure.png`) });
      throw new Error('Gameplay did not reach expected state');
    };
    const start = Date.now();
    const url = new URL(earnedOffice ? 'http://localhost:3001/?preview=hen-social&identity=earned' : laterShift ? 'http://localhost:3001/?preview=workshop-tactics' : 'http://localhost:3001/');
    if (profileCosts) url.searchParams.set('profile_costs', '1');
    await page.goto(url.href, { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => JSON.parse(window.render_game_to_text?.() ?? '{}').loaded === true, null, { timeout: 120000 });
    const bootMs = Date.now() - start;
    if (earnedOffice) {
      await wait(s => s.clock_speed_index === 0 && s.dispatch?.work_progress?.desks?.[0]?.career_seals === 1 && s.hen_social?.pending >= 1);
      await page.locator('canvas').focus();
      // The art fixture clears dialogue; closing Settings restores floor input.
      await page.keyboard.press('F10'); await wait(s => s.settings.visible);
      await page.keyboard.press('Escape'); await wait(s => !s.settings.visible && s.camera.input_enabled);
      // Let modal input settle and hold the key across a rendered frame. A
      // zero-duration down/up can be missed by the paused engine under load.
      await page.waitForTimeout(200);
      await page.keyboard.press('Space', { delay: 100 }); await wait(s => s.clock_speed_index === 1);
    } else if (laterShift) {
      await wait(s => s.shift_challenge?.visible && s.shift_challenge.workshop.day === 5);
      await page.keyboard.press('Escape');
      await wait(s => !s.shift_challenge.visible);
      if ((await state()).clock_speed_index === 0) await page.keyboard.press('Space');
      await wait(s => s.clock_speed_index === 1);
    } else {
    await page.keyboard.press('KeyN'); await wait(s => s.first_clutch?.first_hen_prelude);
    await page.keyboard.press('Enter'); await wait(s => s.pending_decision_kind === 'directive');
    await page.keyboard.press('Digit3'); await page.keyboard.press('Enter');
    const route = await wait(s => s.first_clutch?.stage === 'specialty_route' && !s.pending_decision_kind);
    const r = route.first_clutch.primary_button.rect, b = await page.locator('canvas').boundingBox();
    await page.mouse.click(b.x + b.width * (r.x + r.width / 2) / 1280, b.y + b.height * (r.y + r.height / 2) / 720);
    await wait(s => s.first_clutch?.stage === 'delivery' && s.clock_speed_index === 1);
    }
    // Isolate presentation from operational ticks when investigating noisy
    // frame tails. Hen poses and desk effects continue while the clock is held.
    const paused = process.argv.includes('--paused');
    if (paused) {
      await page.keyboard.press('Space');
      await wait(s => s.clock_speed_index === 0);
    }
    await page.waitForTimeout(warmupMs);
    const initial = await state();
    const cpuSession = profileEngine ? await page.context().newCDPSession(page) : null;
    if (cpuSession) {
      await cpuSession.send('Profiler.enable');
      await cpuSession.send('Profiler.setSamplingInterval', { interval: 1000 });
      await cpuSession.send('Profiler.start');
    }
    const traceSession = traceFrames ? await page.context().newCDPSession(page) : null;
    if (traceSession) await traceSession.send('Tracing.start', {
      categories: 'devtools.timeline,v8,blink.user_timing,disabled-by-default-devtools.timeline.frame',
      transferMode: 'ReturnAsStream',
    });
    const frames = await page.evaluate(sampleMs => new Promise(resolve => {
      const values = []; let previous = performance.now(); const end = previous + sampleMs;
      const step = now => { values.push(now - previous); previous = now; if (now < end) requestAnimationFrame(step); else resolve(values.slice(1)); };
      requestAnimationFrame(step);
    }), paused ? 10000 : sampleMs);
    frames.sort((a, b) => a - b);
    const final = await state();
    if (profileShaders) {
      const capture = await page.evaluate(() => ({ ...window.__gameplayShaderCapture, runtimeKey: window.__pecking_order_shader_runtime_key, warmup: window.__pecking_order_shader_metrics }));
      fs.writeFileSync(path.join(output, `${runs.length}-${label}-shaders.json`), JSON.stringify({ ...capture, quality: final.settings.visual_quality, errors }));
    }
    if (cpuSession) {
      const { profile } = await cpuSession.send('Profiler.stop');
      fs.writeFileSync(path.join(output, `${runs.length}-${label}.cpuprofile`), JSON.stringify(profile));
      await cpuSession.detach();
    }
    if (traceSession) {
      const complete = new Promise(resolve => traceSession.once('Tracing.tracingComplete', resolve));
      await traceSession.send('Tracing.end');
      const { stream } = await complete;
      const chunks = [];
      for (;;) {
        const chunk = await traceSession.send('IO.read', { handle: stream });
        chunks.push(Buffer.from(chunk.data, chunk.base64Encoded ? 'base64' : 'utf8'));
        if (chunk.eof) break;
      }
      await traceSession.send('IO.close', { handle: stream });
      await traceSession.detach();
      fs.writeFileSync(path.join(output, `${runs.length}-${label}-trace.json`), Buffer.concat(chunks));
    }
    if (final.performance.hen_identity_resources) {
      assert.deepEqual(final.performance.hen_identity_resources, initial.performance.hen_identity_resources, 'Live identities and installed hardware must reuse their warmed resources');
    }
    if (earnedOffice) {
      const occupied = final.dispatch.work_progress.desks.filter(d => d.worker_id >= 0);
      assert.ok(occupied.length >= 4 && occupied.every(d => d.career_seals === Math.min(d.worker_id + 1, 3)), 'Earned career displays must persist through live ticks');
    }
    if (!paused) {
      assert.equal(final.clock_speed_index, 1, 'live sample must not silently become a paused measurement');
      assert.ok(final.performance.authoritative_tick_revision > initial.performance.authoritative_tick_revision, 'simulation must advance during the sample');
    }
    const result = {
      label, laterShift, earnedOffice, paused, profileCosts, traceFrames, profileEngine, profileShaders, warmupMs, bootMs, sampleMs: paused ? 10000 : sampleMs,
      frameMedianMs: frames[Math.floor(frames.length / 2)],
      frameP95Ms: frames[Math.floor(frames.length * .95)],
      frameP99Ms: frames[Math.floor(frames.length * .99)],
      frameMaxMs: frames.at(-1),
      framesOver50Ms: frames.filter(ms => ms > 50.5).length,
      framesOver100Ms: frames.filter(ms => ms > 100.5).length,
      stallTimeOver50Ms: frames.reduce((sum, ms) => sum + Math.max(0, ms - 50), 0),
      frames: frames.length, quality: final.settings.visual_quality,
      initialPerformance: initial.performance, performance: final.performance, errors,
    };
    if (process.argv.includes('--capture')) await page.screenshot({ path: path.join(output, `${runs.length}-${label}.png`) });
    assert.deepEqual(errors, []);
    runs.push(result);
    fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify({ runs }, null, 2));
    console.log(JSON.stringify({ label, bootMs, median: result.frameMedianMs, p95: result.frameP95Ms, p99: result.frameP99Ms, max: result.frameMaxMs, over50: result.framesOver50Ms }));
  } finally { await browser.close(); }
}
