import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

// The existing local art fixture supplies three real claims at different
// stages. All selection, peck, pause, and resize actions below use public input.
const url = process.argv[2] ?? "http://localhost:3001/?preview=work-progress";
const output = path.resolve(process.argv[3] ?? "../output/web-game/desk-display");
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ["--use-gl=angle", `--use-angle=${process.env.WEBGL_BACKEND === 'd3d11' ? 'd3d11' : 'swiftshader'}`] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
page.setDefaultTimeout(120_000);
const errors = [];
const evidence = { errors, viewports: [] };
page.on("pageerror", error => errors.push(String(error)));
page.on("console", message => { if (message.type() === "error") errors.push(message.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? "{}"));
async function waitFor(predicate, label) {
  const deadline = Date.now() + 120_000;
  let snapshot;
  while (Date.now() < deadline) {
    snapshot = await state();
    if (predicate(snapshot)) return snapshot;
    await page.waitForTimeout(150);
  }
  throw new Error(`${label}: ${JSON.stringify(snapshot?.dispatch?.work_progress)}`);
}
async function capture(name) {
  await page.screenshot({ path: path.join(output, `${name}.png`), fullPage: true, timeout: 120_000 });
}
try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  const ready = await waitFor(s => s.loaded && s.dispatch?.work_progress?.desks?.some(d => d.peck_ready && d.caption_visible), "ready desk display");
  assert.ok(ready.dispatch.work_progress.desks.some(d => d.status === "paused"));
  assert.ok(ready.dispatch.work_progress.desks.some(d => d.status === "deadline_risk"));
  const candidate = ready.dispatch.work_progress.desks.find(d => d.peck_ready);
  assert.equal(candidate.caption, "PECK");
  evidence.before = ready.dispatch.work_progress;
  await capture("01-high-desk-displays");
  await page.keyboard.press("KeyE");
  const landed = await waitFor(s => s.production?.last_peck_assist?.worker_id === candidate.worker_id, "overview peck lands");
  assert.equal(landed.focused_worker_id, candidate.worker_id);
  const peck = landed.production;
  assert.equal(peck.peck_assists_remaining, ready.production.peck_assists_remaining - 1);
  evidence.landed = { focused_worker_id: landed.focused_worker_id, peck, focus: landed.priority_peck_focus };
  await page.keyboard.press("Space");
  await waitFor(s => s.clock_speed_index === 0, "pause after peck");
  await page.keyboard.press("KeyE");
  const held = await state();
  assert.equal(held.focused_worker_id, candidate.worker_id, "a second peck must stay on the selected hen");
  assert.equal(held.clock_speed_index, 0, "a used file must not resume the clock");
  assert.equal(held.production.peck_assists_remaining, peck.peck_assists_remaining, "a held request must not spend another charge");
  for (const [width, height] of [[2560, 1600], [1440, 900], [900, 800]]) {
    await page.setViewportSize({ width, height });
    await page.waitForTimeout(750);
    await capture(`02-focused-${width}x${height}`);
    evidence.viewports.push({ width, height, state: (await state()).routing_lifecycle });
  }
  assert.deepEqual(errors, []);
  evidence.passed = true;
} finally {
  fs.writeFileSync(path.join(output, "audit.json"), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log("DESK_DISPLAY_AUDIT_PASSED overview=ready+paused+urgent peck=selected pause=stable sizes=2560+1440+900");
