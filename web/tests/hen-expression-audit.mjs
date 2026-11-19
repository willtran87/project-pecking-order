import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve(process.argv[2] ?? '../output/web-game/hen-expression');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', `--use-angle=${process.env.WEBGL_BACKEND ?? 'swiftshader'}`] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
page.setDefaultTimeout(120000);
const evidence = { errors: [], frames: [] };
page.on('pageerror', e => evidence.errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') evidence.errors.push(m.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
const expression = (s, id = 1) => s.hen_intents?.find(h => h.worker_id === id)?.expression;
async function waitFor(predicate, label) {
  const deadline = Date.now() + 180000;
  let latest;
  while (Date.now() < deadline) {
    latest = await state();
    if (predicate(latest)) return latest;
    await page.waitForTimeout(100);
  }
  throw new Error(`${label}: ${JSON.stringify(latest?.hen_intents)}`);
}
async function capture(name) {
  await page.screenshot({ path: path.join(output, `${name}.png`), fullPage: true });
  evidence.frames.push({ name, state: await state() });
}
try {
  // Only preconditions are staged: a strained working hen and an eligible file.
  // The flourish below must come from a public Priority Peck, not a debug trigger.
  await page.goto('http://localhost:3001/?preview=hen-expression', { waitUntil: 'domcontentloaded' });
  const ready = await waitFor(s => s.loaded && s.focused_worker_id === 1 && expression(s)?.strain > 0.9, 'strained seated hen');
  assert.equal(expression(ready).available, true);
  assert.ok(expression(ready, 0).strain < 0.1, 'calm hen has no invented stress');
  await page.waitForTimeout(1000);
  if ((await state()).character_dialogue?.visible) await page.keyboard.press('Enter');
  await waitFor(s => !s.character_dialogue?.visible, 'physical hen is unobscured');
  await capture('01-stressed-2560x1600');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.waitForTimeout(400);
  await capture('02-working-1440x900');
  await page.keyboard.press('KeyE');
  await waitFor(s => expression(s)?.last_reaction === 'proud', 'earned Peck flourish');
  // Keep production held while the causal body reaction completes normally.
  if ((await state()).clock_speed_index !== 0) await page.keyboard.press('Space');
  await capture('03-earned-reaction');
  const reacted = await state();
  assert.equal(reacted.production.last_peck_assist.worker_id, 1);
  assert.equal(reacted.production.peck_assists_remaining, ready.production.peck_assists_remaining - 1);
  evidence.reaction = expression(reacted);
  await page.waitForTimeout(300);
  await capture('04-reaction-follow-through');
  await waitFor(s => expression(s)?.reaction === '', 'reaction settles back to work');
  await page.setViewportSize({ width: 900, height: 800 });
  await page.waitForTimeout(500);
  await capture('05-settled-900x800');
  assert.deepEqual(evidence.errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error);
  await capture('failure');
  throw error;
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('HEN_EXPRESSION_AUDIT_PASSED stress=real calm=distinct peck=earned reaction=settles viewports=2560+1440+900');
