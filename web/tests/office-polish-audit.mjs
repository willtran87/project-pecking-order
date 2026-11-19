import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const props = process.argv.includes('--props');
const output = path.resolve(`../output/web-game/office-polish${props ? '-props' : ''}`);
const before = path.resolve('../output/office-polish-before-runtime');
fs.mkdirSync(output, { recursive: true });
const evidence = [];
for (const build of ['before', 'after']) {
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
  const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
  const errors = [];
  page.on('pageerror', e => errors.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  if (build === 'before') await page.route('**/game/*', route => {
    const name = new URL(route.request().url()).pathname.split('/').pop();
    const file = path.join(before, name);
    if (!fs.existsSync(file)) return route.continue();
    return route.fulfill({ body: fs.readFileSync(file), contentType: name.endsWith('.wasm') ? 'application/wasm' : name.endsWith('.js') ? 'text/javascript' : name.endsWith('.html') ? 'text/html' : 'application/octet-stream' });
  });
  const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
  const until = async predicate => {
    const deadline = Date.now() + 120000;
    while (Date.now() < deadline) { const s = await state(); if (predicate(s)) return s; await page.waitForTimeout(60); }
    throw new Error('Expected playable preview state');
  };
  const capture = async name => page.screenshot({ path: path.join(output, `${build}-${name}.png`), fullPage: true });
  try {
    await page.goto(`http://localhost:3001/?preview=${props ? 'office-props' : 'work-progress'}`, { waitUntil: 'domcontentloaded' });
    const ready = await until(s => s.loaded && s.dispatch?.work_progress?.desks?.some(d => d.peck_ready && d.caption_visible));
    await page.waitForTimeout(props ? 1600 : 700);
    await capture('01-office');
    if (props) {
      await page.keyboard.down('ArrowUp');
      await page.waitForTimeout(450);
      await page.keyboard.up('ArrowUp');
      await page.keyboard.down('ArrowRight');
      await page.waitForTimeout(200);
      await page.keyboard.up('ArrowRight');
      await page.waitForTimeout(500);
      await capture('02-window-detail');
      assert.deepEqual(errors, []);
      evidence.push({ build, errors, final: await state() });
      continue;
    }
    await page.keyboard.press('KeyE');
    await until(s => s.production?.peck_assists_remaining === ready.production.peck_assists_remaining - 1);
    await page.waitForTimeout(180);
    await capture('02-contact');
    await page.waitForTimeout(180);
    await capture('03-resolve');
    await until(s => s.hen_intents?.some(h => h.expression?.last_reaction === 'proud'));
    if ((await state()).clock_speed_index !== 0) await page.keyboard.press('Space');
    await page.setViewportSize({ width: 1440, height: 900 });
    await capture('04-reward');
    await page.waitForTimeout(2400);
    await capture('05-desk-detail');
    await page.setViewportSize({ width: 900, height: 800 });
    await page.waitForTimeout(500);
    await capture('06-compact');
    assert.deepEqual(errors, []);
    evidence.push({ build, errors, final: await state() });
  } finally { await browser.close(); }
}
fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify({ passed: true, evidence }, null, 2));
console.log(props ? 'OFFICE_PROPS_AUDIT_PASSED before+after windows+room-detail' : 'OFFICE_POLISH_AUDIT_PASSED before+after contact+reward+settle viewports=2560+1440+900');
