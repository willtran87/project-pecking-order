import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve(process.argv[2] ?? '../output/web-game/management-startup');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', `--use-angle=${process.env.WEBGL_BACKEND === 'd3d11' ? 'd3d11' : 'swiftshader'}`] });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
page.setDefaultTimeout(120000);
const errors = [];
page.on('pageerror', error => errors.push(String(error)));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
if (process.env.STARTUP_GAME_DIR) {
  const directory = path.resolve(process.env.STARTUP_GAME_DIR);
  await page.route('**/game/*', route => {
    const file = path.join(directory, new URL(route.request().url()).pathname.split('/').pop());
    if (!fs.existsSync(file)) return route.continue();
    return route.fulfill({ body: fs.readFileSync(file), contentType: file.endsWith('.wasm') ? 'application/wasm' : file.endsWith('.js') ? 'text/javascript' : file.endsWith('.html') ? 'text/html' : 'application/octet-stream' });
  });
}
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
async function until(predicate, label) {
  const deadline = Date.now() + 120000;
  while (Date.now() < deadline) {
    const value = await state();
    if (predicate(value)) return value;
    await page.waitForTimeout(150);
  }
  throw new Error(label);
}
const evidence = { errors };
try {
  await page.goto('http://localhost:3001/?preview=work-progress', { waitUntil: 'domcontentloaded' });
  await until(s => s.loaded && s.dispatch?.work_progress?.desks?.some(d => d.peck_ready && d.caption_visible), 'prepared office');
  await page.locator('canvas').focus();
  const before = await state();
  await page.keyboard.press('F10');
  const settings = await until(s => s.settings?.visible, 'first settings open');
  assert.match(settings.settings.accessible_text, /Coop Settings and Controls/);
  await page.screenshot({ path: path.join(output, 'settings-first-open.png'), fullPage: true });
  await page.keyboard.press('Escape');
  await until(s => !s.settings?.visible, 'settings closed');
  await page.keyboard.press('KeyV');
  const ledger = await until(s => s.flockwatch?.visible, 'first ledger open');
  assert.ok(ledger.flockwatch.available_pages.includes('flock'));
  assert.match(ledger.flockwatch.accessible_text, /10 sections filed/);
  await page.screenshot({ path: path.join(output, 'ledger-first-open.png'), fullPage: true });
  await page.keyboard.press('F10');
  await until(s => s.settings?.visible, 'settings over ledger');
  await page.keyboard.press('Escape');
  await until(s => !s.settings?.visible && s.flockwatch?.visible, 'return to ledger');
  await page.keyboard.press('KeyV');
  const closed = await until(s => !s.flockwatch?.visible, 'ledger closed');
  assert.equal(closed.clock_speed_index, before.clock_speed_index, 'Opening management must preserve pause ownership');
  await page.setViewportSize({ width: 900, height: 800 });
  await page.keyboard.press('F10');
  await until(s => s.settings?.visible, 'settings reopen compact');
  await page.screenshot({ path: path.join(output, 'settings-compact.png'), fullPage: true });
  assert.deepEqual(errors, []);
  Object.assign(evidence, { passed: true, settings: settings.settings, ledger: ledger.flockwatch });
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('MANAGEMENT_STARTUP_AUDIT_PASSED settings=first+reopen ledger=all-sections pause=preserved');
