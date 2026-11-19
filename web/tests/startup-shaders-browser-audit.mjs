import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { gzipSync, gunzipSync } from 'node:zlib';
import { chromium } from 'playwright';

const output = path.resolve(process.env.STARTUP_SHADER_OUTPUT ?? '../output/web-game/cold-start-fallbacks');
fs.mkdirSync(output, { recursive: true });
const manifest = JSON.parse(gunzipSync(fs.readFileSync('public/game/index.startup-shaders.json.gz')));
const preferences = JSON.parse(fs.readFileSync(new URL('./fixtures/startup-preferences.json', import.meta.url), 'utf8'));
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
const results = [];
try {
  for (const scenario of process.env.STARTUP_SHADER_SCENARIOS?.split(',') ?? ['prepared', 'high', 'low', 'warm-failure', 'stale', 'unavailable', 'unsupported']) {
    const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    if (scenario === 'warm-failure') await page.addInitScript(() => {
      const original = WebGL2RenderingContext.prototype.shaderSource;
      let injected = false;
      WebGL2RenderingContext.prototype.shaderSource = function(shader, source) {
        if (!injected && source.includes('#define MODE_SIMPLE_COPY')) {
          source += '\n deliberately_invalid_shader_syntax !!!\n'; injected = true;
        }
        return original.call(this, shader, source);
      };
    });
    if (['high', 'low'].includes(scenario)) await page.addInitScript(({ payload, quality }) => {
      payload.preferences.visual_quality = quality;
      localStorage.setItem('pecking-order.player-preferences', JSON.stringify(payload));
    }, { payload: preferences, quality: scenario });
    if (scenario === 'stale') await page.route('**/game/index.startup-shaders.json.gz', route => route.fulfill({
      body: gzipSync(JSON.stringify({ ...manifest, runtimeKey: 'old-export' })), contentType: 'application/octet-stream',
    }));
    if (scenario === 'unavailable') await page.route('**/game/index.startup-shaders.json.gz', route => route.abort());
    if (scenario === 'unsupported') await page.addInitScript(() => {
      const original = WebGL2RenderingContext.prototype.getExtension;
      WebGL2RenderingContext.prototype.getExtension = function(name) {
        return name === 'KHR_parallel_shader_compile' ? null : original.call(this, name);
      };
    });
    await page.goto('http://localhost:3001/', { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(() => {
      const state = JSON.parse(window.render_game_to_text?.() ?? '{}');
      return state.loaded && state.boot?.ready > 0;
    }, null, { timeout: 120000 });
    await page.evaluate(() => new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve))));
    await page.waitForTimeout(750);
    const metrics = await page.evaluate(() => ({
      warmup: window.__pecking_order_shader_metrics,
      hookRemoved: !window.__pecking_order_shader_startup,
      title: JSON.parse(window.render_game_to_text()).campaign_stage,
      quality: JSON.parse(window.render_game_to_text()).settings.visual_quality,
    }));
    if (['prepared', 'high', 'low'].includes(scenario)) {
      const quality = scenario === 'prepared' ? 'balanced' : scenario;
      const retained = manifest.qualityPrograms[quality].filter(p => p.gameplay).reduce((n, p) => n + (p.copies ?? 1), 0);
      assert.equal(metrics.quality, quality);
      assert.equal(metrics.warmup.hits, manifest.qualityPrograms[quality].filter(p => !p.gameplay).length);
      assert.equal(metrics.warmup.retained, retained);
      assert.equal(metrics.warmup.closed, retained === 0);
      assert.equal(metrics.warmup.rejected, 0);
    } else if (scenario === 'warm-failure') {
      const retained = manifest.qualityPrograms.balanced.filter(p => p.gameplay).reduce((n, p) => n + (p.copies ?? 1), 0);
      assert.equal(metrics.warmup.rejected, 1);
      assert.equal(metrics.warmup.hits, manifest.qualityPrograms.balanced.filter(p => !p.gameplay).length - 1);
      assert.equal(metrics.warmup.retained, retained);
      assert.equal(metrics.warmup.closed, retained === 0);
    } else assert.equal(metrics.warmup, undefined, 'fallback must not adopt stale/unsupported programs');
    assert.equal(metrics.hookRemoved, !metrics.warmup?.retained, 'only bounded first-use gameplay programs may retain the bridge');
    assert.ok((metrics.warmup?.retained ?? 0) <= 24);
    assert.equal(metrics.title, 'title');
    const png = await page.locator('canvas').screenshot({ path: path.join(output, `${scenario}.png`) });
    // Read the compositor screenshot, not a discarded WebGL backbuffer. This
    // catches missing Emscripten uniform metadata even when gameplay state runs.
    const visibleFraction = await page.evaluate(async encoded => {
      const img = new Image(); img.src = `data:image/png;base64,${encoded}`; await img.decode();
      const canvas = document.createElement('canvas'); canvas.width = img.width; canvas.height = img.height;
      const ctx = canvas.getContext('2d'); ctx.drawImage(img, 0, 0);
      const pixels = ctx.getImageData(0, 0, img.width, img.height).data;
      let visible = 0, count = 0;
      for (let i = 0; i < pixels.length; i += 64) { count++; if (Math.max(pixels[i], pixels[i + 1], pixels[i + 2]) > 32) visible++; }
      return visible / count;
    }, png.toString('base64'));
    assert.ok(visibleFraction > 0.15, `${scenario}: actual office/title must render, not an empty canvas (${visibleFraction})`);
    assert.deepEqual(errors, []);
    await page.evaluate(() => window.__pecking_order_shader_startup?.close());
    assert.equal(await page.evaluate(() => Object.hasOwn(document.querySelector('canvas').getContext('webgl2'), 'shaderSource')), false, 'teardown removes shader wrappers');
    results.push({ scenario, metrics, visibleFraction, errors });
    await page.close();
  }
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(results, null, 2));
  await browser.close();
}
console.log(`STARTUP_SHADERS_BROWSER_AUDIT_PASSED ${results.map(result => result.scenario).join('+')}; real pixels and cleanup verified`);
