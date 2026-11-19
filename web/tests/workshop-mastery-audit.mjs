import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/workshop-mastery');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
const evidence = { fixture: 'authored mastered tools; real subsequent inputs and deliveries', errors: [], screens: [] };
page.on('pageerror', e => evidence.errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') evidence.errors.push(m.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
const book = s => s.gameplay_pulse?.active_playbook;
async function until(predicate, label) {
  const end = Date.now() + 120000;
  let latest;
  while (Date.now() < end) {
    latest = await state();
    if (predicate(latest)) return latest;
    await page.waitForTimeout(180);
  }
  throw new Error(label + ': ' + JSON.stringify(latest?.shift_challenge));
}
async function shot(name) {
  await page.waitForTimeout(700);
  await page.screenshot({ path: path.join(output, name + '.png'), fullPage: true });
  const s = await state();
  evidence.screens.push({ name, choice: s.shift_challenge, workshop: book(s)?.workshop });
}
async function openWorkshop() {
  const s = await state();
  if (s.shift_challenge.mode === 'workshop' && s.shift_challenge.visible) return;
  const r = s.shift_challenge.workshop_rect, b = await page.locator('canvas').boundingBox();
  await page.mouse.click(b.x + b.width * (r.x + r.width / 2) / 1280, b.y + b.height * (r.y + r.height / 2) / 720);
  await until(s => s.shift_challenge.visible && s.shift_challenge.mode === 'workshop', 'workshop');
}
try {
  await page.goto('http://localhost:3001/?preview=workshop-tactics&mastery=1', { waitUntil: 'domcontentloaded' });
  const initial = await until(s => s.loaded && s.shift_challenge?.visible && book(s)?.workshop?.mastered_tools?.length === 3, 'earned workshop');
  evidence.initial = book(initial).workshop;
  for (const [digit, mode, plan, challenge] of [
    ['1', 'handoff', 'fast', 'mixed_basket'],
    ['3', 'encourage', 'flock', 'care_circle'],
    ['2', 'triage', 'safe', 'precision_pair'],
  ]) {
    await openWorkshop();
    const before = book(await state()).workshop;
    await page.keyboard.press('Digit' + digit);
    await page.keyboard.press('KeyT');
    await page.keyboard.press('KeyT');
    const preview = await until(s => s.shift_challenge.tuning === mode, 'preview ' + mode);
    assert.deepEqual(book(preview).workshop, before, 'preview must not equip, spend or use a charge');
    assert.match(preview.shift_challenge.detail, /EARNED:/);
    await shot('01-' + mode + '-2560');
    await page.setViewportSize({ width: 900, height: 800 });
    await shot('02-' + mode + '-900');
    for (const r of [(await state()).shift_challenge.confirm_rect, (await state()).shift_challenge.tuning_rect]) {
      assert.ok(r.x >= 0 && r.y >= 0 && r.x + r.width <= 1281 && r.y + r.height <= 721, 'controls stay inside canvas');
    }
    await page.keyboard.press('Enter');
    await until(s => !s.shift_challenge.visible && book(s).workshop.tuning === mode, 'equip ' + mode);
    await page.keyboard.press('KeyQ');
    const plans = await until(s => s.shift_challenge.visible && s.shift_challenge.mode === 'preset', 'follow-up challenges');
    assert.equal(plans.shift_challenge.options.find(o => o.id === plan).contract_id, challenge);
    assert.equal(book(plans).workshop.stamps, 0, 'retuning existing tools is free');
    await page.setViewportSize({ width: 2560, height: 1600 });
  }
  await page.keyboard.press('Digit2');
  await shot('03-delivery-plan');
  await page.keyboard.press('Enter');
  await until(s => book(s).contract.id === 'precision_pair', 'commit assisted-delivery plan');
  await page.keyboard.press('KeyE');
  const assisted = await until(s => book(s).workshop.uses === 1, 'real Triage assist');
  assert.equal(book(assisted).workshop.protected_count, 1);
  assert.equal(book(assisted).contract.progress, 0, 'unfinished work is not a reward');
  await page.setViewportSize({ width: 1440, height: 900 });
  await shot('04-protected-file');
  if ((await state()).clock_speed_index === 0) await page.keyboard.press('Space');
  const delivered = await until(s => book(s).contract.progress >= 1, 'clean on-time rescued delivery');
  assert.equal(book(delivered).workshop.protected_count, 0);
  await page.keyboard.press('KeyQ');
  await until(s => s.shift_challenge.visible && s.shift_challenge.mode === 'workshop', 'locked loadout');
  await page.keyboard.press('Digit2');
  assert.equal((await state()).shift_challenge.tuning_enabled, false);
  assert.equal((await state()).shift_challenge.confirm_enabled, false);
  await shot('05-locked-after-use');
  assert.deepEqual(evidence.errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error);
  evidence.final = await state();
  await shot('failure');
  throw error;
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('WORKSHOP_MASTERY_AUDIT_PASSED modes=3 plans=causal preview=free rescue=actual-delivery');
