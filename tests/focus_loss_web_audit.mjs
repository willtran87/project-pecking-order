import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const bundledPlaywright = path.join(
  os.homedir(), ".codex", "skills", "develop-web-game", "node_modules", "playwright", "index.mjs",
);
const playwrightModule = process.env.PLAYWRIGHT_MODULE_URL
  ?? (fs.existsSync(bundledPlaywright) ? pathToFileURL(bundledPlaywright).href : "playwright");
const { chromium } = await import(playwrightModule);

const url = process.argv[2] ?? "http://localhost:3000/?build=focus-loss-safety-audit";
const outputDirectory = path.resolve(
  process.argv[3] ?? "output/web-game/focus-loss-safety-audit",
);
fs.mkdirSync(outputDirectory, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const page = await context.newPage();
const browserErrors = [];
page.on("console", (message) => {
  if (message.type() === "error") browserErrors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => browserErrors.push(`page: ${String(error)}`));

async function state() {
  return JSON.parse(await page.evaluate(() => window.render_game_to_text?.() ?? "{}"));
}

async function waitForState(predicateSource, timeout = 30_000) {
  await page.waitForFunction((source) => {
    try {
      const snapshot = JSON.parse(window.render_game_to_text?.() ?? "{}");
      return Function("snapshot", `return (${source})(snapshot);`)(snapshot);
    } catch {
      return false;
    }
  }, predicateSource, { timeout });
}

async function clickAuthored(x, y) {
  const bounds = await page.locator("#canvas").boundingBox();
  assert.ok(bounds, "the Godot canvas must remain mounted");
  await page.mouse.click(
    bounds.x + bounds.width * x / 1280,
    bounds.y + bounds.height * y / 720,
  );
}

try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitForState("snapshot => snapshot.loaded === true", 90_000);
  const canvas = page.locator("#canvas");
  await canvas.focus();
  await canvas.click({ position: { x: 8, y: 8 } });
  await canvas.focus();

  await page.keyboard.press("KeyN");
  await waitForState("snapshot => snapshot.campaign_stage === 'active'");
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
  await page.keyboard.press("Digit1");
  await page.keyboard.press("Enter");
  await waitForState("snapshot => snapshot.pending_decision_kind === '' && snapshot.shift_phase === 1");
  const opening = await state();
  if (opening.first_clutch?.visible === true) {
    await clickAuthored(557, 168);
    await waitForState("snapshot => snapshot.first_clutch?.visible === false");
  }
  await page.keyboard.press("Escape");
  await page.keyboard.press("Digit3");
  await waitForState("snapshot => snapshot.clock_speed_index === 3");
  const running = await state();
  assert.equal(running.settings?.pause_when_unfocused, true);
  assert.equal(running.settings?.focus_pause_active, false);
  const revisionBefore = running.performance?.authoritative_tick_revision;

  // Headless Chromium's focus emulation does not dispatch the DOM events that a
  // real tab switch produces. Dispatch the public browser event so this still
  // exercises the wrapper listener and boolean-only Godot bridge end-to-end.
  await page.evaluate(() => window.dispatchEvent(new Event("blur")));
  await waitForState(
    "snapshot => snapshot.clock_speed_index === 0 && snapshot.settings?.focus_pause_active === true",
    15_000,
  );
  const held = await state();
  assert.equal(held.settings?.focus_pause_restore_speed, 3);
  await page.waitForTimeout(1_000);
  const heldAfterSettle = await state();
  assert.equal(
    heldAfterSettle.performance?.authoritative_tick_revision,
    held.performance?.authoritative_tick_revision,
    "focus-loss hold must stop authoritative simulation ticks once the browser event is handled",
  );

  await page.evaluate(() => window.dispatchEvent(new Event("focus")));
  await waitForState(
    "snapshot => snapshot.clock_speed_index === 3 && snapshot.settings?.focus_pause_active === false",
    15_000,
  );
  const restored = await state();
  assert.equal(restored.settings?.focus_pause_restore_speed, 0);
  await page.screenshot({
    path: path.join(outputDirectory, "focus-restored-running-office.png"),
    fullPage: true,
  });

  const report = {
    passed: browserErrors.length === 0,
    url,
    running: {
      speed: running.clock_speed_index,
      tickRevision: revisionBefore,
      pauseWhenUnfocused: running.settings?.pause_when_unfocused,
    },
    held: {
      speed: held.clock_speed_index,
      tickRevision: held.performance?.authoritative_tick_revision,
      settledTickRevision: heldAfterSettle.performance?.authoritative_tick_revision,
      active: held.settings?.focus_pause_active,
      restoreSpeed: held.settings?.focus_pause_restore_speed,
    },
    restored: {
      speed: restored.clock_speed_index,
      active: restored.settings?.focus_pause_active,
      restoreSpeed: restored.settings?.focus_pause_restore_speed,
    },
    browserErrors,
  };
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(report, null, 2));
  assert.deepEqual(browserErrors, []);
} finally {
  await browser.close();
}
