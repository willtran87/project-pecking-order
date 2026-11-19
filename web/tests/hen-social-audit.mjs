import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/hen-social');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
page.setDefaultTimeout(180000);
const evidence = { errors: [], frames: [] };
page.on('pageerror', e => evidence.errors.push(String(e)));
page.on('console', m => { if (m.type() === 'error') evidence.errors.push(m.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? '{}'));
async function waitFor(predicate, label) {
  const deadline = Date.now() + 180000;
  let latest;
  while (Date.now() < deadline) {
    latest = await state();
    fs.writeFileSync(path.join(output, 'progress.json'), JSON.stringify({label, clock:latest?.clock_speed_index, social:latest?.hen_social, ui:latest?.hen_social_ui, dialogue:latest?.character_dialogue, errors:evidence.errors}, null, 2));
    if (predicate(latest)) return latest;
    await page.waitForTimeout(100);
  }
  throw new Error(`${label}: ${JSON.stringify({social: latest?.hen_social, ui: latest?.hen_social_ui, dialogue:latest?.character_dialogue, errors:evidence.errors})}`);
}
async function capture(name) {
  console.log('capture', name);
  await page.screenshot({ path: path.join(output, `${name}.png`), fullPage: true });
  const s = await state();
  evidence.frames.push({ name, state: s });
  assert.equal(s.hen_social_ui.blocks_input, false);
  assert.equal(s.hen_social_ui.visible, true);
  assert.ok(s.hen_social_ui.rect.height < 180, 'speech balloon hugs its text');
  console.log('captured', name);
}
try {
  await page.goto('http://localhost:3001/?preview=hen-social', { waitUntil: 'domcontentloaded' });
  const ready = await waitFor(s => s.loaded && s.hen_social_ui?.visible, 'nearby support conversation');
  assert.equal(ready.hen_social.current.kind, 'comfort');
  assert.equal(ready.hen_social.current.second_id, 1);
  assert.equal(ready.clock_speed_index, 0);
  assert.notEqual(ready.hen_intents.find(h => h.worker_id === 0).expression.personality, ready.hen_intents.find(h => h.worker_id === 1).expression.personality);
  await capture('01-support-2560x1600');
  const held = await state();
  await page.waitForTimeout(400);
  assert.equal((await state()).hen_social.elapsed, held.hen_social.elapsed, 'pause preserves reading time');
  await page.keyboard.press('Space');
  console.log('resume sent');
  await waitFor(s => s.clock_speed_index !== 0 || s.character_dialogue?.visible, 'resume accepted');
  await waitFor(s => s.hen_social?.replying && s.hen_social_ui?.visible, 'coworker reply');
  await page.keyboard.press('Space');
  await waitFor(s => s.clock_speed_index === 0, 'pause conversation');
  // A real first-egg aside may briefly own the reading surface. Let that
  // higher-priority receipt retire while the paused conversation is preserved.
  await waitFor(s => s.hen_social_ui?.visible && s.hen_social?.replying, 'reply resumes after earned aside');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.waitForTimeout(500);
  await capture('02-reply-1440x900');
  const reply = await state();
  assert.match(reply.hen_social_ui.reply, /^Pip:/);
  assert.ok(reply.hen_intents.some(h => h.expression?.social_attention));
  await page.setViewportSize({ width: 900, height: 800 });
  await page.waitForTimeout(500);
  await capture('03-compact-900x800');
  await page.keyboard.press('Space');
  await waitFor(s => !s.hen_social_ui?.visible && s.hen_social?.serial >= 1 && !s.hen_social.current.first_name, 'conversation retires');
  await page.keyboard.press('Space');
  await waitFor(s => s.clock_speed_index === 0, 'clock remains controllable');
  assert.deepEqual(evidence.errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error);
  await page.screenshot({ path: path.join(output, 'failure.png'), fullPage: true });
  throw error;
} finally {
  fs.writeFileSync(path.join(output, 'audit.json'), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log('HEN_SOCIAL_AUDIT_PASSED support=real reply=paired pause=held input=unblocked viewports=2560+1440+900');
