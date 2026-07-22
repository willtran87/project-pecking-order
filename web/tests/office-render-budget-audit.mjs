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

const url = process.argv[2] ?? "http://localhost:3000/?build=office-render-budget-audit";
const outputDirectory = path.resolve(process.argv[3] ?? "../output/web-game/office-render-budget-audit");
const baselinePath = process.argv[4] ? path.resolve(process.argv[4]) : null;
const baseline = baselinePath ? JSON.parse(fs.readFileSync(baselinePath, "utf8")) : null;
const minimumNodeReduction = Number(process.env.OFFICE_RENDER_MIN_NODE_REDUCTION ?? 10);
const minimumDrawCallReduction = Number(process.env.OFFICE_RENDER_MIN_DRAW_REDUCTION ?? 10);
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

async function sampleFrames(durationMsec = 2_000) {
  return page.evaluate((duration) => new Promise((resolve) => {
    const intervals = [];
    let previous = performance.now();
    const started = previous;
    function frame(now) {
      intervals.push(now - previous);
      previous = now;
      if (now - started < duration) {
        requestAnimationFrame(frame);
        return;
      }
      const sorted = [...intervals].sort((left, right) => left - right);
      const percentile = (ratio) => sorted[
        Math.min(sorted.length - 1, Math.floor(sorted.length * ratio))
      ] ?? 0;
      resolve({
        elapsedMsec: now - started,
        frames: intervals.length,
        averageFps: intervals.length * 1_000 / Math.max(1, now - started),
        medianFrameMsec: percentile(0.5),
        p95FrameMsec: percentile(0.95),
        worstFrameMsec: sorted.at(-1) ?? 0,
      });
    }
    requestAnimationFrame(frame);
  }), durationMsec);
}

try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitForState("snapshot => snapshot.loaded === true", 90_000);
  await waitForState(
    "snapshot => snapshot.boot?.optional_visuals?.ready === true || snapshot.boot?.optional_visuals?.deferred !== true",
    60_000,
  );
  await page.keyboard.press("KeyN");
  await waitForState("snapshot => snapshot.campaign_stage === 'active'");
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
  await page.keyboard.press("Digit1");
  await page.keyboard.press("Enter");
  await waitForState(
    "snapshot => snapshot.pending_decision_kind === '' && snapshot.shift_phase === 1",
  );
  const opening = await state();
  if (opening.first_clutch?.visible === true) {
    await clickAuthored(557, 168);
    await waitForState("snapshot => snapshot.first_clutch?.visible === false");
  }
  await page.keyboard.press("Escape");
  await waitForState("snapshot => snapshot.camera?.input_enabled === true");
  await page.waitForTimeout(1_000);

  const snapshot = await state();
  const performance = snapshot.performance ?? {};
  const frames = await sampleFrames();
  assert.equal(snapshot.campaign_stage, "active");
  assert.equal(snapshot.shift_phase, 1);
  assert.ok(Number(performance.node_count) > 0);
  assert.ok(Number(performance.draw_calls) > 0);
  const comparison = baseline ? {
    baselinePath,
    nodeCountDelta: Number(performance.node_count) - Number(baseline.native.nodeCount),
    drawCallsDelta: Number(performance.draw_calls) - Number(baseline.native.drawCalls),
    renderedObjectsDelta: Number(performance.rendered_objects) - Number(baseline.native.renderedObjects),
    renderedPrimitivesDelta: Number(performance.rendered_primitives) - Number(baseline.native.renderedPrimitives),
  } : null;
  if (comparison) {
    assert.ok(
      comparison.nodeCountDelta <= -minimumNodeReduction,
      `batching should remove at least ${minimumNodeReduction} live scene nodes`,
    );
    assert.ok(
      comparison.drawCallsDelta <= -minimumDrawCallReduction,
      `batching should remove at least ${minimumDrawCallReduction} renderer draw calls`,
    );
  }
  assert.deepEqual(browserErrors, []);

  await page.screenshot({ path: path.join(outputDirectory, "active-office.png"), fullPage: true });
  const report = {
    passed: true,
    url,
    renderer: "headless Chromium / ANGLE SwiftShader; render counts are authoritative, frame timing is informational",
    budgets: { minimumNodeReduction, minimumDrawCallReduction },
    office: {
      campaignDay: snapshot.campaign_day,
      eggsToday: snapshot.eggs_today,
      quotaTarget: snapshot.quota_target,
      cameraMode: snapshot.camera?.mode,
    },
    native: {
      fps: performance.fps,
      processUsec: performance.process_usec,
      physicsProcessUsec: performance.physics_process_usec,
      objectCount: performance.object_count,
      nodeCount: performance.node_count,
      orphanNodeCount: performance.orphan_node_count,
      drawCalls: performance.draw_calls,
      renderedObjects: performance.rendered_objects,
      renderedPrimitives: performance.rendered_primitives,
    },
    frames,
    comparison,
    browserErrors,
  };
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(report, null, 2));
} finally {
  await browser.close();
}
