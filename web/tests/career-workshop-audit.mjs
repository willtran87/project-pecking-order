import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/career-workshop');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
page.setDefaultTimeout(120000);
const evidence = { errors: [], screens: [] };
page.on('pageerror', e => evidence.errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') evidence.errors.push(m.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
async function waitFor(predicate, label) {
  const deadline = Date.now() + 180000;
  let latest;
  while (Date.now() < deadline) {
    latest = await state();
    if (predicate(latest)) return latest;
    await page.waitForTimeout(180);
  }
  throw new Error(`${label}: ${JSON.stringify(latest?.shift_challenge)}`);
}
async function capture(name) {
  await page.screenshot({ path: path.join(output, `${name}.png`), fullPage: true });
  evidence.screens.push({ name, state: await state() });
}
try {
  // Seeded fourth-shift career; purchases, plan choice and Pecks use public input.
  await page.goto('http://localhost:3001/?preview=career-workshop', { waitUntil: 'domcontentloaded' });
  const ready = await waitFor(s => s.loaded && s.shift_challenge?.visible && s.shift_challenge.mode === 'workshop', 'fourth-shift workshop');
  assert.equal(ready.shift_challenge.workshop.stamps, 3);
  assert.equal(ready.clock_interaction_hold_active, true);
  await page.keyboard.press('Digit2');
  await waitFor(s => s.shift_challenge.selected === 1, 'inspect lens');
  assert.deepEqual((await state()).gameplay_pulse.active_playbook.workshop.owned, []);
  for (const [width, height] of [[2560, 1600], [1440, 900], [900, 800]]) {
    await page.setViewportSize({ width, height });
    await page.waitForTimeout(700);
    const snapshot = await state();
    for (const r of [...snapshot.shift_challenge.card_rects, snapshot.shift_challenge.confirm_rect]) {
      assert.ok(r.x >= 0 && r.y >= 0 && r.x + r.width <= 1281 && r.y + r.height <= 721, 'workshop choices fit the game canvas');
    }
    await capture(`01-workshop-${width}x${height}`);
  }
  await page.keyboard.press('Enter');
  const unlocked = await waitFor(s => s.gameplay_pulse?.active_playbook?.workshop?.equipped === 'shell_guard', 'unlock and equip lens');
  assert.equal(unlocked.gameplay_pulse.active_playbook.workshop.stamps, 2);
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.keyboard.press('KeyQ');
  const plans = await waitFor(s => s.shift_challenge?.visible && s.shift_challenge.mode === 'preset', 'later plan choices');
  assert.deepEqual(plans.shift_challenge.options.map(o => o.contract_id), ['route_circuit', 'precision_pair', 'flock_relay']);
  await page.keyboard.press('Digit2');
  await capture('02-later-challenges');
  await page.keyboard.press('Enter');
  await waitFor(s => s.gameplay_pulse?.active_playbook?.contract?.id === 'precision_pair', 'file Precision Pair');
  await page.keyboard.press('KeyE');
  const peck = await waitFor(s => s.gameplay_pulse?.active_playbook?.workshop?.uses === 1, 'lens triggers on actual strong Peck');
  assert.equal(peck.gameplay_pulse.active_playbook.workshop.protected_count, 1);
  assert.equal(peck.gameplay_pulse.active_playbook.contract.progress, 0, 'Peck alone does not fabricate a completed egg');
  if (peck.clock_speed_index !== 0) await page.keyboard.press('Space');
  await page.keyboard.press('KeyQ');
  await waitFor(s => s.shift_challenge?.visible && s.shift_challenge.mode === 'workshop', 'active loadout');
  await page.keyboard.press('Digit1');
  await page.keyboard.press('Enter');
  const second = await waitFor(s => s.gameplay_pulse?.active_playbook?.workshop?.owned?.length === 2, 'bank another permanent tool');
  assert.equal(second.gameplay_pulse.active_playbook.workshop.equipped, 'shell_guard', 'midshift unlock cannot swap the active tool');
  assert.equal(second.gameplay_pulse.active_playbook.workshop.stamps, 1);
  await page.keyboard.press('KeyQ');
  await waitFor(s => s.shift_challenge?.visible, 'inspect owned tool');
  await page.keyboard.press('Digit1');
  const locked = await waitFor(s => s.shift_challenge.selected === 0, 'inspect locked loadout');
  assert.equal(locked.shift_challenge.confirm_enabled, false);
  await capture('03-owned-next-shift');
  await page.keyboard.press('Escape');
  const paused = await state();
  if (paused.clock_speed_index === 0) await page.keyboard.press('Space');
  const finished = await waitFor(s => s.gameplay_pulse?.active_playbook?.contract?.progress >= 1, 'protected assisted egg finishes');
  assert.equal(finished.gameplay_pulse.active_playbook.workshop.protected_count, 0);
  await capture('04-protected-egg-progress');
  assert.deepEqual(evidence.errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error);
  evidence.final = await state();
  await capture('failure');
  throw error;
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('CAREER_WORKSHOP_AUDIT_PASSED unlock=preview+commit tool=lens-active swaps=shift-locked challenges=3 egg=actual-clean viewports=2560+1440+900');
