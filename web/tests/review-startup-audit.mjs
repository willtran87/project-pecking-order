import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve(process.argv[2] ?? '../output/web-game/review-startup');
fs.mkdirSync(output, { recursive: true });
const preferences = JSON.parse(fs.readFileSync(new URL('./fixtures/startup-preferences.json', import.meta.url), 'utf8'));
preferences.preferences.ui_scale = 1.5;
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', `--use-angle=${process.env.WEBGL_BACKEND === 'd3d11' ? 'd3d11' : 'swiftshader'}`] });
const results = [], errors = [];
try {
  for (const [preview, stage] of [['probation-report', 'probation'], ['probation-final', 'final']]) {
    const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
    page.on('pageerror', e => errors.push(String(e)));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    await page.addInitScript(value => localStorage.setItem('pecking-order.player-preferences', JSON.stringify(value)), preferences);
    await page.goto(`http://localhost:3001/?preview=${preview}`, { waitUntil: 'domcontentloaded' });
    await page.waitForFunction(expected => {
      const s = JSON.parse(window.render_game_to_text?.() ?? '{}');
      return s.loaded && s.boot?.ready > 0 && s.campaign_stage === expected;
    }, stage, { timeout: 120000 });
    await page.waitForTimeout(1200);
    const state = await page.evaluate(() => JSON.parse(window.render_game_to_text()));
    assert.equal(state.settings.ui_scale, 1.5);
    assert.equal(state.settings.visual_quality, 'high');
    for (const [width, height] of [[2560, 1600], [900, 800]]) {
      await page.setViewportSize({ width, height });
      await page.waitForTimeout(400);
      await page.screenshot({ path: path.join(output, `${preview}-${width}.png`), fullPage: true });
      await page.mouse.move(width / 2, height / 2);
      await page.mouse.wheel(0, 2400);
      await page.waitForTimeout(350);
      await page.screenshot({ path: path.join(output, `${preview}-${width}-actions.png`), fullPage: true });
      await page.mouse.wheel(0, -4000);
    }
    results.push({ preview, state });
    await page.close();
  }
  assert.deepEqual(errors, []);
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify({ results, errors }, null, 2));
  console.log('REVIEW_STARTUP_AUDIT_PASSED first-use=report+final scale=150% quality=high viewports=2560+900');
} finally { await browser.close(); }
