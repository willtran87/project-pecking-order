import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/loading-recovery');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
page.setDefaultTimeout(120000);
const errors = [];
page.on('pageerror', error => errors.push(String(error)));
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
const ready = () => page.waitForFunction(() => {
  const state = JSON.parse(window.render_game_to_text?.() ?? '{}');
  return state.loaded && state.settings && !document.querySelector('.loading-state');
}, null, { timeout: 120000 });
try {
  await page.route('**/game/index.js', route => route.abort());
  await page.goto(process.argv[2] ?? 'http://localhost:3001/', { waitUntil: 'domcontentloaded' });
  await page.getByText('Unable to load the browser game runtime.', { exact: true }).waitFor();
  await page.screenshot({ path: path.join(output, '01-download-retry-2560.png') });
  await page.unroute('**/game/index.js');
  await page.getByRole('button', { name: 'Retry loading', exact: true }).click();
  await ready();
  await page.locator('canvas').focus();
  await page.keyboard.press('F10');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).settings?.visible === true);
  await page.keyboard.press('Escape');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).settings?.visible === false);
  await page.keyboard.press('KeyN');
  await page.waitForFunction(() => JSON.parse(window.render_game_to_text()).campaign_stage === 'active');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.screenshot({ path: path.join(output, '02-recovered-play.png') });
  // Simulate the browser event, without changing the user's GPU or browser settings.
  await page.locator('canvas').evaluate(canvas => canvas.dispatchEvent(new Event('webglcontextlost', { cancelable: true })));
  await page.getByText(/browser lost its graphics connection/).waitFor();
  await page.setViewportSize({ width: 900, height: 800 });
  await page.screenshot({ path: path.join(output, '03-graphics-retry-900.png') });
  await page.getByRole('button', { name: 'Retry loading', exact: true }).click();
  await ready();
  assert.deepEqual(errors, []);
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify({ passed: true, errors, loaded: (await state()).loaded, checks: ['failed download retry', 'settings first open', 'quick start', 'graphics loss retry'] }, null, 2));
} finally {
  await browser.close();
}
console.log('LOADING_RECOVERY_AUDIT_PASSED');
