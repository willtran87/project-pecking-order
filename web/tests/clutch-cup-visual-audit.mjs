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

const url = process.argv[2] ?? "http://localhost:3000/?build=clutch-cup-visual-audit";
const outputDirectory = path.resolve(process.argv[3] ?? "../output/web-game/clutch-cup-visual-audit");
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

  const deadline = Date.now() + 150_000;
  while (Date.now() < deadline) {
    const snapshot = await state();
    if (snapshot.pending_decision_kind) {
      const priorKind = snapshot.pending_decision_kind;
      await page.keyboard.press("Digit1");
      await page.keyboard.press("Enter");
      await waitForState(
        `candidate => candidate.pending_decision_kind !== '${priorKind}' || candidate.shift_phase !== 1`,
        15_000,
      );
      const resumed = await state();
      if (resumed.shift_phase === 1) await page.keyboard.press("Digit3");
      continue;
    }
    if (Number(snapshot.eggs_today ?? 0) >= 4) break;
    await page.waitForTimeout(250);
  }

  let occupied = await state();
  assert.equal(occupied.shift_phase, 1, "the occupied clutch should be inspected during the live shift");
  assert.ok(occupied.eggs_today >= 4, "at least four real eggs should occupy the living clutch");
  await page.locator("#canvas").focus();
  await page.keyboard.press("Space");
  await waitForState("snapshot => snapshot.clock_speed_index === 0");
  occupied = await state();
  assert.equal(occupied.pending_decision_kind, "");
  assert.deepEqual(browserErrors, []);

  await page.screenshot({ path: path.join(outputDirectory, "occupied-clutch-office.png"), fullPage: true });
  const bounds = await page.locator("#canvas").boundingBox();
  assert.ok(bounds, "the occupied clutch close-up requires the live canvas");
  await page.screenshot({
    path: path.join(outputDirectory, "occupied-clutch-closeup.png"),
    clip: {
      x: bounds.x + bounds.width * 0.68,
      y: bounds.y + bounds.height * 0.26,
      width: bounds.width * 0.30,
      height: bounds.height * 0.42,
    },
  });
  const report = {
    passed: true,
    url,
    eggsToday: occupied.eggs_today,
    quotaTarget: occupied.quota_target,
    shiftPhase: occupied.shift_phase,
    clockSpeedIndex: occupied.clock_speed_index,
    pendingDecisionKind: occupied.pending_decision_kind,
    browserErrors,
  };
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(report, null, 2));
} finally {
  await browser.close();
}
