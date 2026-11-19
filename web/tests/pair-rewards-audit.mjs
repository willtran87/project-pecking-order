import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/pair-rewards');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
const evidence = { errors: [], screens: [] };
page.on('pageerror', e => evidence.errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') evidence.errors.push(m.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
async function waitFor(predicate, label) {
  const end = Date.now() + 90000;
  while (Date.now() < end) { const s = await state(); if (predicate(s)) return s; await page.waitForTimeout(100); }
  throw new Error(label + ': ' + JSON.stringify(await state()));
}
async function shot(name) {
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(output, name + '.png'), fullPage: true });
  const s = await state();
  evidence.screens.push({ name, ties: s.flock_ties, social: s.hen_social, social_ui: s.hen_social_ui });
  if (s.flock_ties?.visible) {
    const p = s.flock_ties.panel_rect;
    assert.ok(p.y >= 0 && p.y + p.height <= 721, 'panel fits logical canvas');
    for (const r of [s.flock_ties.break_rect, s.flock_ties.repair_rect, s.flock_ties.contest_rect]) {
      assert.ok(r.y >= p.y && r.y + r.height <= p.y + p.height + 1, 'actions stay inside panel');
      assert.ok(r.x >= p.x && r.x + r.width <= p.x + p.width + 1, 'actions stay inside width');
    }
  }
}
async function clickRect(r) {
  const b = await page.locator('#canvas').boundingBox();
  await page.mouse.click(b.x + b.width * (r.x + r.width / 2) / 1280, b.y + b.height * (r.y + r.height / 2) / 720);
}
try {
  await page.goto('http://localhost:3001/?preview=pair-rewards', { waitUntil: 'domcontentloaded' });
  const start = await waitFor(s => s.loaded && s.flock_ties?.visible && s.flock_ties.contest_available, 'rival choices');
  assert.equal(start.flock_ties.pair.affinity, -14);
  assert.match(start.flock_ties.benefit, /Starting adds \+3 stress/);
  await shot('01-rival-choice-2560');
  await page.setViewportSize({ width: 900, height: 800 });
  await shot('02-rival-choice-900');
  // Real pointer activation, not a simulation/debug shortcut.
  await clickRect((await state()).flock_ties.contest_rect);
  const accepted = await waitFor(s => s.flock_ties?.pair?.reward?.contest, 'public contest action');
  assert.equal(accepted.flock_ties.pair.reward.earned, false);
  assert.equal(accepted.flock_ties.pair.reward.progress, 0);
  assert.equal(accepted.flock_ties.break_available, false);
  assert.equal(accepted.flock_ties.repair_available, false);
  assert.equal(accepted.flock_ties.contest_available, false);
  assert.match(accepted.flock_ties.receipt, /\+3 stress each now/);
  await page.keyboard.press('Digit3');
  assert.equal((await state()).flock_ties.receipt, accepted.flock_ties.receipt, 'duplicate keyboard input cannot reapply');
  await shot('03-contest-accepted-900');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.keyboard.press('Escape');
  await waitFor(s => !s.flock_ties.visible, 'close');
  await page.keyboard.press('Space');
  await waitFor(s => s.hen_social?.current?.relationship_label === 'CONTEST COMPLETE' && s.hen_social_ui?.visible, 'actual clean-egg reward reaction');
  await waitFor(s => /\+6 warmth/.test(s.hen_social_ui?.reply ?? ''), 'reply explains trust reward');
  await page.keyboard.press('Space');
  await shot('04-contest-reaction-1440');
  await page.keyboard.press('KeyB');
  const earned = await waitFor(s => s.flock_ties?.visible && s.flock_ties.pair.reward.earned, 'durable earned reward');
  assert.equal(earned.flock_ties.pair.reward.xp, 6);
  assert.equal(earned.flock_ties.pair.reward.progress, 2);
  assert.match(earned.flock_ties.benefit, /PAIR REWARD EARNED/);
  await shot('05-contest-earned-1440');
  await clickRect(earned.flock_ties.second_selector_rect);
  await page.waitForTimeout(200);
  for (let i = 0; i < 3; i++) await page.keyboard.press('ArrowDown');
  await page.keyboard.press('Enter');
  const friend = await waitFor(s => s.flock_ties?.partner_id === 2 && s.flock_ties.pair.reward.earned, 'friend reward also settles from real production');
  assert.equal(friend.flock_ties.pair.reward.xp, 2);
  assert.equal(friend.flock_ties.pair.reward.relief, 3);
  await page.setViewportSize({ width: 900, height: 800 });
  await shot('06-friend-earned-900');
  assert.deepEqual(evidence.errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error); evidence.final = await state();
  await page.screenshot({ path: path.join(output, 'failure.png'), fullPage: true });
  throw error;
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('PAIR_REWARDS_AUDIT_PASSED choice=public rewards=real-production reactions=causal layout=2560+1440+900');
