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

const url = process.argv[2] ?? "http://localhost:3000/?build=audio-momentum-audit";
const outputDirectory = path.resolve(
  process.argv[3] ?? "../output/web-game/audio-momentum-audit",
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

const startedAt = Date.now();

try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitForState("snapshot => snapshot.loaded === true", 90_000);
  const canvas = page.locator("#canvas");
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

  const baseline = await state();
  assert.equal(baseline.audio?.director?.player_count, 4);
  assert.equal(baseline.audio?.director?.raw_pcm_bytes, 1_024_000);
  assert.ok((baseline.audio?.director?.momentum_target ?? 1) <= 0.01);

  let productive = null;
  while (Date.now() - startedAt < 240_000) {
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
    assert.equal(snapshot.campaign_stage, "active", "momentum should become audible during the live shift");
    assert.equal(snapshot.shift_phase, 1, "momentum should become audible before farmer review");
    if (snapshot.clock_speed_index !== 3) await page.keyboard.press("Digit3");
    const quota = Math.max(1, Number(snapshot.quota_target ?? 1));
    const progress = Number(snapshot.eggs_today ?? 0) / quota;
    if (progress >= 0.70 && (snapshot.audio?.director?.momentum_target ?? 0) >= 0.65) {
      await waitForState(
        "candidate => candidate.audio?.director?.momentum_blend >= 0.45 && candidate.audio?.director?.momentum_db > -30",
        15_000,
      );
      productive = await state();
      break;
    }
    await page.waitForTimeout(250);
  }

  assert.ok(productive, "a real seated-worker clutch must activate the positive momentum stem");
  assert.ok(productive.eggs_today > 0);
  assert.equal(productive.audio?.director?.running, true);
  assert.ok(productive.audio?.director?.momentum_target >= 0.65);
  assert.ok(productive.audio?.director?.momentum_blend >= 0.45);
  assert.ok(productive.audio?.director?.momentum_db > -30);
  assert.deepEqual(browserErrors, []);

  await page.screenshot({
    path: path.join(outputDirectory, "productive-clutch-momentum.png"),
    fullPage: true,
  });
  const report = {
    passed: true,
    url,
    elapsedMsec: Date.now() - startedAt,
    baseline: {
      eggs: baseline.eggs_today,
      quota: baseline.quota_target,
      playerCount: baseline.audio?.director?.player_count,
      rawPcmBytes: baseline.audio?.director?.raw_pcm_bytes,
      pressureTarget: baseline.audio?.director?.pressure_target,
      momentumTarget: baseline.audio?.director?.momentum_target,
    },
    productive: {
      eggs: productive.eggs_today,
      quota: productive.quota_target,
      pressureTarget: productive.audio?.director?.pressure_target,
      pressureDb: productive.audio?.director?.pressure_db,
      momentumTarget: productive.audio?.director?.momentum_target,
      momentumBlend: productive.audio?.director?.momentum_blend,
      momentumDb: productive.audio?.director?.momentum_db,
      ambientDb: productive.audio?.director?.ambient_db,
    },
    browserErrors,
  };
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(report, null, 2));
} finally {
  await browser.close();
}
