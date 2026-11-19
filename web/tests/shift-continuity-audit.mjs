import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { chromium } from 'playwright';

// Starts at an authored closing report; all subsequent actions use public input.
const largeText = process.argv.includes('--large-text');
const output = fileURLToPath(new URL(`../../output/web-game/shift-continuity${largeText ? '-large-text' : ''}`, import.meta.url));
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=d3d11'] });
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const errors = [], evidence = { fixture: 'probation-report-risk', errors };
page.on('pageerror', e => errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
async function until(predicate, label) {
  const deadline = Date.now() + 120000;
  let current;
  while (Date.now() < deadline) {
    current = await state();
    if (predicate(current)) return current;
    await page.waitForTimeout(250);
  }
  throw new Error(label + ': ' + JSON.stringify({ stage: current.campaign_stage, decision: current.pending_decision_kind, clock: current.clock_speed_index }));
}
async function shot(name) {
  await page.waitForTimeout(500);
  await page.screenshot({ path: path.join(output, name + '.png'), fullPage: true });
}
try {
  if (largeText) {
    const preferences = JSON.parse(fs.readFileSync(new URL('./fixtures/startup-preferences.json', import.meta.url), 'utf8'));
    preferences.preferences.ui_scale = 1.5;
    await page.addInitScript(value => localStorage.setItem('pecking-order.player-preferences', JSON.stringify(value)), preferences);
  }
  await page.goto('http://localhost:3001/?preview=probation-report-risk', { waitUntil: 'domcontentloaded' });
  evidence.review = await until(s => s.loaded && s.campaign_stage === 'probation', 'campaign review');
  assert.equal(evidence.review.shift_continuity.day, 2);
  assert.equal(evidence.review.shift_continuity.source_day, 1);
  assert.match(evidence.review.shift_continuity.target, new RegExp(`${evidence.review.quota_target} eggs`));
  await shot('01-review');
  await page.keyboard.press('KeyC');
  evidence.morning = await until(s => s.campaign_stage === 'active' && s.pending_decision_kind === 'directive', 'next morning');
  assert.deepEqual(evidence.morning.shift_continuity, evidence.review.shift_continuity);
  assert.equal(evidence.morning.clock_speed_index, 0);
  assert.equal(evidence.morning.campaign_day, 2);
  await shot('02-morning');
  await page.setViewportSize({ width: 900, height: 800 });
  await shot('03-morning-compact');
  await page.keyboard.press('Digit3');
  await page.keyboard.press('Enter');
  evidence.playing = await until(s => s.pending_decision_kind === '' && s.clock_speed_index === 1, 'authorized shift');
  assert.equal(evidence.playing.campaign_day, 2);
  assert.equal(evidence.playing.quota_target, evidence.morning.quota_target);
  await shot('04-playing');
  await page.keyboard.press('Space');
  await until(s => s.clock_speed_index === 0, 'pause');
  await page.keyboard.press('Space');
  await until(s => s.clock_speed_index === 1, 'resume');
  assert.deepEqual(errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error);
  await shot('failure');
  throw error;
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('SHIFT_CONTINUITY_AUDIT_PASSED');
