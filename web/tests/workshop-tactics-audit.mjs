import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/workshop-tactics');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
const evidence = { errors: [], screens: [] };
page.on('pageerror', e => evidence.errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') evidence.errors.push(m.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
async function waitFor(predicate, label) {
  const end = Date.now() + 120000;
  let latest;
  while (Date.now() < end) { latest = await state(); if (predicate(latest)) return latest; await page.waitForTimeout(150); }
  throw new Error(label + ': ' + JSON.stringify(latest?.shift_challenge));
}
async function shot(name) {
  await page.waitForTimeout(750);
  await page.screenshot({ path: path.join(output, name + '.png'), fullPage: true });
  const s = await state();
  evidence.screens.push({ name, choice: s.shift_challenge, playbook: s.gameplay_pulse?.active_playbook });
}
try {
  await page.goto('http://localhost:3001/?preview=workshop-tactics', { waitUntil: 'domcontentloaded' });
  await waitFor(s => s.loaded && s.shift_challenge?.visible && s.shift_challenge.workshop.day === 5, 'later workshop');
  await page.keyboard.press('Digit2'); await page.keyboard.press('KeyT');
  const preview = await waitFor(s => s.shift_challenge.tuning === 'precision', 'preview precision');
  assert.deepEqual(preview.gameplay_pulse.active_playbook.workshop.owned, [], 'tuning preview must not spend or equip');
  assert.match(preview.shift_challenge.detail, /PERFECT/);
  for (const [width, height] of [[2560, 1600], [900, 800]]) {
    await page.setViewportSize({ width, height });
    await shot(`01-precision-${width}`);
    const s = await state();
    for (const r of [s.shift_challenge.tuning_rect, s.shift_challenge.confirm_rect, ...s.shift_challenge.card_rects]) {
      assert.ok(r.x >= 0 && r.y >= 0 && r.x + r.width <= 1281 && r.y + r.height <= 721, 'choice controls fit canvas');
    }
  }
  await page.keyboard.press('Escape');
  assert.deepEqual((await state()).gameplay_pulse.active_playbook.workshop.owned, [], 'cancel preview is free');
  await page.keyboard.press('KeyQ');
  await waitFor(s => s.shift_challenge.visible, 'plan or workshop');
  // The explicit workshop destination remains reachable from the Plan screen.
  let s = await state();
  if (s.shift_challenge.mode !== 'workshop') {
    const r = s.shift_challenge.workshop_rect, b = await page.locator('canvas').boundingBox();
    await page.mouse.click(b.x + b.width * (r.x + r.width / 2) / 1280, b.y + b.height * (r.y + r.height / 2) / 720);
    await waitFor(s => s.shift_challenge.mode === 'workshop', 'reopen workshop');
  }
  await page.keyboard.press('Digit2'); await page.keyboard.press('KeyT'); await page.keyboard.press('Enter');
  await waitFor(s => s.gameplay_pulse?.active_playbook?.workshop?.tuning === 'precision', 'equip precision');
  assert.equal((await state()).gameplay_pulse.active_playbook.workshop.stamps, 2);
  await page.keyboard.press('KeyQ');
  const plans = await waitFor(s => s.shift_challenge?.mode === 'preset' && s.shift_challenge.visible, 'new challenges');
  assert.deepEqual(plans.shift_challenge.options.map(o => o.contract_id), ['mixed_basket', 'deadline_rescue', 'team_coaching']);
  await page.keyboard.press('Digit2'); await shot('02-deadline-choice-900');
  await page.setViewportSize({ width: 1440, height: 900 }); await shot('02-deadline-choice-1440');
  await page.keyboard.press('Enter');
  await waitFor(s => s.gameplay_pulse.active_playbook.contract.id === 'deadline_rescue', 'commit rescue plan');
  await page.keyboard.press('KeyE');
  const peck = await waitFor(s => s.gameplay_pulse.active_playbook.workshop.uses === 1, 'precision protects actual perfect Peck');
  assert.equal(peck.gameplay_pulse.active_playbook.workshop.protected_count, 1);
  assert.equal(peck.gameplay_pulse.active_playbook.contract.progress, 0, 'unfinished egg earns no rescue progress');
  await shot('03-protected-work');
  if ((await state()).clock_speed_index === 0) await page.keyboard.press('Space');
  const finished = await waitFor(s => s.gameplay_pulse.active_playbook.contract.progress === 1, 'clean on-time rescue finishes');
  assert.equal(finished.gameplay_pulse.active_playbook.workshop.protected_count, 0);
  await shot('04-earned-rescue');
  await page.keyboard.press('KeyQ');
  await waitFor(s => s.shift_challenge.visible && s.shift_challenge.mode === 'workshop', 'locked loadout');
  await page.keyboard.press('Digit2');
  const locked = await state();
  assert.equal(locked.shift_challenge.tuning_enabled, false);
  assert.equal(locked.shift_challenge.confirm_enabled, false);
  await shot('05-locked-mode');
  assert.deepEqual(evidence.errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error); evidence.final = await state(); await shot('failure'); throw error;
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('WORKSHOP_TACTICS_AUDIT_PASSED previews=free modes=committed+locked challenges=3 rescue=actual-egg layout=2560+1440+900');
