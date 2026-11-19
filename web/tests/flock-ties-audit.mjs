import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { chromium } from 'playwright';

const output = path.resolve('../output/web-game/flock-ties');
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader'] });
const compactReplay = process.argv.includes('--compact-replay');
const page = await browser.newPage({ viewport: compactReplay ? { width: 1440, height: 900 } : { width: 2560, height: 1600 } });
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
    fs.writeFileSync(path.join(output, 'progress.json'), JSON.stringify({ label, ties: latest?.flock_ties, errors: evidence.errors }, null, 2));
    if (predicate(latest)) return latest;
    await page.waitForTimeout(150);
  }
  throw new Error(`${label}: ${JSON.stringify({ ties: latest?.flock_ties, errors: evidence.errors })}`);
}
async function capture(name) {
  console.log('capture', name);
  await page.screenshot({ path: path.join(output, `${name}.png`), fullPage: true });
  const s = await state();
  evidence.frames.push({ name, state: s });
  const panel = s.flock_ties.panel_rect;
  const action = s.flock_ties.repair_rect;
  assert.ok(action.y + action.height <= panel.y + panel.height + 1, 'actions stay in panel');
  assert.equal(s.clock_interaction_hold_active, true, 'reading holds the shift');
  console.log('captured', name);
}
async function clickRect(rect) {
	const canvas = await page.locator('#canvas').boundingBox();
  const s = await state();
  const view = s.viewport_size ?? s.viewport;
  // Godot UI scales from the logical viewport published in diagnostics.
  console.log('viewport', JSON.stringify(view), 'canvas', JSON.stringify(canvas));
  const logical = await page.evaluate(() => {
		const canvas = document.querySelector('#canvas');
    return { width: canvas.width, height: canvas.height };
  });
  // The game uses canvas_items stretch with a 1280x720 reference and expand.
  const scale = Math.min(logical.width / 1280, logical.height / 720);
  await page.mouse.click(canvas.x + (rect.x + rect.width / 2) * scale * canvas.width / logical.width,
    canvas.y + (rect.y + rect.height / 2) * scale * canvas.height / logical.height);
}
try {
  await page.goto('http://localhost:3001/?preview=flock-ties', { waitUntil: 'domcontentloaded' });
  const ready = await waitFor(s => s.loaded && s.flock_ties?.visible && s.flock_ties.pair?.tier === 'rivals', 'shared rivalry history');
  assert.equal(ready.flock_ties.pair.affinity, -14);
  assert.equal(ready.flock_ties.pair.memories.length, 3);
  if (!compactReplay) await capture('01-rivalry-2560x1600');
  await page.keyboard.press('Digit2');
  const repaired = await waitFor(s => s.flock_ties?.pair?.tier === 'mending', 'public clear-air action');
  assert.equal(repaired.flock_ties.pair.affinity, 0);
  assert.equal(repaired.flock_ties.pair.memories.at(-1).kind, 'clear_air');
  assert.equal(repaired.flock_ties.break_available, false);
  assert.equal(repaired.flock_ties.repair_available, false);
  await page.keyboard.press('Digit2');
  assert.equal((await state()).flock_ties.pair.affinity, 0, 'duplicate input cannot farm trust');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.waitForTimeout(600);
  if (!compactReplay) await capture('02-reconciliation-1440x900');
  await page.keyboard.press('Escape');
  await waitFor(s => !s.flock_ties?.visible && !s.clock_interaction_hold_active, 'close releases hold');
  await page.keyboard.press('KeyB');
  await waitFor(s => s.flock_ties?.visible && s.flock_ties.pair?.tier === 'mending', 'reopening remembers relationship');
  const reopened = await state();
  await clickRect(reopened.flock_ties.second_selector_rect);
  await page.waitForTimeout(500);
  // PopupMenu opens without a focused item; first Down focuses item zero.
  for (let item = 0; item < 3; item++) {
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(150);
  }
  await page.keyboard.press('Enter');
  await waitFor(s => s.flock_ties?.partner_id === 2 && s.flock_ties.pair?.tier === 'friends', 'select friend pair');
  await page.setViewportSize({ width: 900, height: 800 });
  await page.waitForTimeout(600);
  await capture('03-friends-900x800');
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.keyboard.press('Escape');
  await waitFor(s => !s.flock_ties?.visible, 'return to office');
  await page.keyboard.press('Space');
  await waitFor(s => s.hen_social?.current?.relationship_label === 'MENDING' && s.hen_social_ui?.visible, 'earned reconciliation conversation');
  await page.keyboard.press('Space');
  await waitFor(s => s.clock_speed_index === 0, 'hold reconciled exchange for reading');
  await page.screenshot({ path: path.join(output, '04-reconciled-coworkers.png'), fullPage: true });
  evidence.frames.push({ name: '04-reconciled-coworkers', state: await state() });
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
console.log(`FLOCK_TIES_AUDIT_PASSED history=readable repair=public+exact selection=public pause=held replay=${compactReplay ? 'compact' : 'full'}`);
