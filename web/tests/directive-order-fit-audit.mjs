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

const url = process.argv[2] ?? "http://localhost:3000/?build=directive-order-fit-audit";
const outputDirectory = path.resolve(process.argv[3] ?? "../output/web-game/directive-order-fit-audit");
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

async function waitForState(predicateSource, label, timeout = 30_000) {
  await page.waitForFunction((source) => {
    try {
      const snapshot = JSON.parse(window.render_game_to_text?.() ?? "{}");
      return Function("snapshot", `return (${source})(snapshot);`)(snapshot);
    } catch {
      return false;
    }
  }, predicateSource, { timeout }).catch((error) => {
    throw new Error(`Timed out waiting for ${label}: ${error.message}`);
  });
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
  await waitForState(
    "(snapshot) => snapshot.loaded === true && snapshot.campaign_stage === 'title'",
    "management intake",
    45_000,
  );
	await page.screenshot({ path: path.join(outputDirectory, "intake.png"), fullPage: true });
  await clickAuthored(640, 605);
	await page.waitForTimeout(1_000);
	await page.screenshot({ path: path.join(outputDirectory, "after-intake-click.png"), fullPage: true });
  await waitForState(
    "(snapshot) => snapshot.campaign_stage === 'active' && snapshot.first_clutch?.stage === 'inspect'",
    "Mabel's authored first-file orientation",
    20_000,
  );
  await page.keyboard.press("Enter");
  await waitForState(
    "(snapshot) => snapshot.pending_decision?.visible === true && snapshot.pending_decision?.kind === 'directive'",
    "Day 1 policy briefing after opening Mabel's file",
    20_000,
  );

  const briefing = await state();
  const options = briefing.pending_decision.options;
  assert.equal(options.length, 3, "the morning briefing should expose three policy choices");
  assert.deepEqual(
    options.map((option) => ({
      id: option.id,
      support: option.order_fit.support_count,
      watch: option.order_fit.risk_count,
    })),
    [
      { id: "record_harvest", support: 1, watch: 2 },
      { id: "shell_assurance", support: 1, watch: 1 },
      { id: "sustainable_flock", support: 1, watch: 1 },
    ],
    "browser diagnostics should match the authoritative Day 1 order-fit matrix",
  );
  assert.match(options[0].order_fit.detail, /directional; closing ledger decides/);
  await page.screenshot({ path: path.join(outputDirectory, "policy-fit-unselected.png"), fullPage: true });

  await page.keyboard.press("Digit1");
  await waitForState(
    "(snapshot) => snapshot.pending_decision?.selected_option_id === 'record_harvest' && snapshot.pending_decision?.confirm_enabled === true",
    "Record Harvest preview",
  );
  const selected = await state();
  assert.equal(selected.pending_decision.options[0].order_fit.supports[0], "OPENING CLUTCH");
  assert.deepEqual(selected.pending_decision.options[0].order_fit.risks, ["SOUND START", "SETTLED FLOCK"]);
  await page.screenshot({ path: path.join(outputDirectory, "policy-fit-selected.png"), fullPage: true });

  for (const viewport of [
    { width: 844, height: 390, name: "compact-landscape" },
    { width: 390, height: 844, name: "portrait" },
  ]) {
    await page.setViewportSize({ width: viewport.width, height: viewport.height });
    await page.waitForTimeout(500);
    const overflow = await page.evaluate(() => ({
      horizontal: document.documentElement.scrollWidth > document.documentElement.clientWidth + 1,
      canvasMounted: Boolean(document.querySelector("#canvas")),
    }));
    assert.equal(overflow.horizontal, false, `${viewport.name} should not introduce horizontal page overflow`);
    assert.equal(overflow.canvasMounted, true, `${viewport.name} should retain the game canvas`);
    await page.screenshot({
      path: path.join(outputDirectory, `policy-fit-${viewport.name}.png`),
      fullPage: true,
    });
  }
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.waitForTimeout(500);

  await page.keyboard.press("Enter");
  await waitForState(
    "(snapshot) => snapshot.pending_decision?.visible === false && snapshot.orders?.active_policy_fit?.support_count === 1",
    "authorized policy fit in the live office",
  );
  const authorized = await state();
  assert.deepEqual(authorized.orders.active_policy_fit.supports, ["OPENING CLUTCH"]);
  assert.deepEqual(authorized.orders.active_policy_fit.risks, ["SOUND START", "SETTLED FLOCK"]);
  assert.deepEqual(browserErrors, []);
  await page.screenshot({ path: path.join(outputDirectory, "authorized-office.png"), fullPage: true });
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify({
    passed: true,
    url,
    policyOptions: options.map((option) => ({ id: option.id, orderFit: option.order_fit })),
    selectedOptionId: selected.pending_decision.selected_option_id,
    activePolicyFit: authorized.orders.active_policy_fit,
    browserErrors,
  }, null, 2));
} finally {
  await browser.close();
}
