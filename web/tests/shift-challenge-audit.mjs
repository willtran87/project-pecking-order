import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/shift-challenge');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
page.setDefaultTimeout(120000);
const errors = [];
const evidence = { errors, screens: [] };
page.on('pageerror', error => errors.push(String(error)));
page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
async function waitFor(predicate, label, timeout = 120000) {
  const deadline = Date.now() + timeout;
  let current;
  while (Date.now() < deadline) {
    current = await state();
    if (predicate(current)) return current;
    await page.waitForTimeout(200);
  }
  throw new Error(`${label}: ${JSON.stringify(current?.shift_challenge)}`);
}
async function capture(name) {
  await page.screenshot({ path: path.join(output, `${name}.png`), fullPage: true });
  evidence.screens.push({ name, state: await state() });
}
try {
  // The art fixture stages real claims; all choices below use public keyboard input.
  await page.goto('http://localhost:3001/?preview=work-progress&build=shift-challenge', { waitUntil: 'domcontentloaded' });
  await waitFor(s => s.loaded && s.dispatch?.work_progress?.desks?.some(d => d.peck_ready), 'boot');
  await page.keyboard.press('KeyQ');
  const first = await waitFor(s => s.shift_challenge?.visible, 'open plan');
  assert.equal(first.shift_challenge.mode, 'preset');
  assert.equal(first.clock_interaction_hold_active, true);
  const originalPlan = first.gameplay_pulse.active_playbook.strategy_preset_id;
  await page.keyboard.press('Digit3');
  await waitFor(s => s.shift_challenge?.selected === 2, 'preview flock');
  assert.equal((await state()).gameplay_pulse.active_playbook.strategy_preset_id, originalPlan);
  await capture('01-plan-comparison-2560x1600');
  for (const [width, height] of [[1440, 900], [900, 800]]) {
    await page.setViewportSize({ width, height });
    await page.waitForTimeout(1000);
    const current = await state();
    for (const rect of [...current.shift_challenge.card_rects, current.shift_challenge.confirm_rect, current.shift_challenge.later_rect]) {
      assert.ok(rect.x >= 0 && rect.y >= 0 && rect.x + rect.width <= 1281 && rect.y + rect.height <= 721, 'choices fit the game canvas');
    }
    await capture(`02-plan-comparison-${width}x${height}`);
  }
  await page.keyboard.press('Escape');
  const canceled = await waitFor(s => !s.shift_challenge?.visible, 'cancel');
  assert.equal(canceled.clock_interaction_hold_active, false);
  assert.equal(canceled.gameplay_pulse.active_playbook.strategy_preset_id, originalPlan);
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.keyboard.press('KeyQ');
  await waitFor(s => s.shift_challenge?.visible, 'reopen');
  await page.keyboard.press('Digit2');
  await page.keyboard.press('Enter');
  const committed = await waitFor(s => s.gameplay_pulse?.active_playbook?.strategy_preset_id === 'safe', 'commit safe plan');
  assert.equal(committed.shift_challenge.visible, false);
  assert.equal(committed.clock_interaction_hold_active, false);
  await capture('03-active-goal');
  // Play forward at the player's normal speed until real clean eggs earn the goal.
  if (committed.clock_speed_index === 0) await page.keyboard.press('Space');
  await waitFor(s => s.gameplay_pulse?.active_playbook?.contract?.complete, 'earn clean goal', 300000);
  await page.keyboard.press('Space');
  await page.keyboard.press('KeyQ');
  const reward = await waitFor(s => s.shift_challenge?.visible && s.shift_challenge.mode === 'reward', 'reward choice');
  assert.equal(reward.clock_interaction_hold_active, true);
  await page.setViewportSize({ width: 2560, height: 1600 });
  await page.keyboard.press('Digit1');
  await capture('04-earned-reward-2560x1600');
  await page.keyboard.press('Enter');
  const claimed = await waitFor(s => s.gameplay_pulse?.active_playbook?.contract?.reward_claimed, 'claim reward');
  assert.equal(claimed.gameplay_pulse.active_playbook.contract.reward_id, 'fund');
  await capture('05-reward-receipt');
  assert.deepEqual(errors, []);
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
console.log('SHIFT_CHALLENGE_AUDIT_PASSED preview=nonmutating cancel=restores choices=keyboard reward=earned viewports=2560+1440+900');
