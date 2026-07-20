import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { pathToFileURL } from "node:url";

const bundledPlaywright = path.join(
  os.homedir(),
  ".codex",
  "skills",
  "develop-web-game",
  "node_modules",
  "playwright",
  "index.mjs",
);
const playwrightModule = process.env.PLAYWRIGHT_MODULE_URL
  ?? (fs.existsSync(bundledPlaywright) ? pathToFileURL(bundledPlaywright).href : "playwright");
const { chromium } = await import(playwrightModule);

const url = process.argv[2] ?? "http://localhost:3000/?build=runtime-soak-audit";
const outputDirectory = path.resolve(
  process.argv[3] ?? "../output/web-game/runtime-soak-audit",
);
const cycles = Math.max(2, Number(process.env.RUNTIME_SOAK_CYCLES ?? 4));
const frameSampleMsec = Math.max(1_000, Number(process.env.RUNTIME_SOAK_SAMPLE_MSEC ?? 1_500));
const maxNativeGrowthBytes = Number(process.env.RUNTIME_SOAK_NATIVE_GROWTH_BYTES ?? 8 * 1024 * 1024);
const maxWasmGrowthBytes = Number(process.env.RUNTIME_SOAK_WASM_GROWTH_BYTES ?? 16 * 1024 * 1024);
const maxJsGrowthBytes = Number(process.env.RUNTIME_SOAK_JS_GROWTH_BYTES ?? 8 * 1024 * 1024);
const maxObjectGrowth = Number(process.env.RUNTIME_SOAK_OBJECT_GROWTH ?? 256);
const maxNodeGrowth = Number(process.env.RUNTIME_SOAK_NODE_GROWTH ?? 64);
const maxOrphanGrowth = Number(process.env.RUNTIME_SOAK_ORPHAN_GROWTH ?? 4);
const maxInputResponseMsec = Number(process.env.RUNTIME_SOAK_INPUT_RESPONSE_MSEC ?? 2_500);
const maxDiagnosticBytes = Number(process.env.RUNTIME_SOAK_DIAGNOSTIC_BYTES ?? 64 * 1024);
const maxPortableBackupBytes = 8 * 1024 * 1024;

fs.mkdirSync(outputDirectory, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-gl=angle", "--use-angle=swiftshader", "--js-flags=--expose-gc"],
});
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 },
  acceptDownloads: true,
});
const page = await context.newPage();
const browserErrors = [];
page.on("console", (message) => {
  if (message.type() === "error") browserErrors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => browserErrors.push(`page: ${String(error)}`));

await page.addInitScript(() => {
  window.__peckingSoakLongTasks = [];
  if (typeof PerformanceObserver !== "undefined") {
    try {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          window.__peckingSoakLongTasks.push({
            startMsec: entry.startTime,
            durationMsec: entry.duration,
          });
        }
      });
      observer.observe({ entryTypes: ["longtask"] });
    } catch {
      // Long Task timing is optional. Frame and input-response gates remain.
    }
  }
});

const cdp = await page.context().newCDPSession(page);
await cdp.send("Performance.enable");
await cdp.send("HeapProfiler.enable");

function parseState(value) {
  return typeof value === "string" ? JSON.parse(value) : {};
}

async function state() {
  return parseState(await page.evaluate(() => window.render_game_to_text?.() ?? "{}"));
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

async function chromiumMetrics() {
  const response = await cdp.send("Performance.getMetrics");
  return Object.fromEntries(response.metrics.map(({ name, value }) => [name, value]));
}

async function collectGarbage() {
  await cdp.send("HeapProfiler.collectGarbage");
  await page.waitForTimeout(100);
}

function authoritativeDigest(snapshot) {
  return {
    campaignDay: snapshot.campaign_day,
    campaignScore: snapshot.campaign_score,
    tickRevision: snapshot.performance?.authoritative_tick_revision,
    eggsToday: snapshot.eggs_today,
    quotaTarget: snapshot.quota_target,
    economy: snapshot.economy,
    production: snapshot.production,
    challengeContractId: snapshot.challenge_contract?.id,
    probationDoctrine: snapshot.probation_doctrine,
  };
}

async function engineHealth(label) {
  await collectGarbage();
  const snapshot = await state();
  const metrics = await chromiumMetrics();
  const diagnosticBytes = Buffer.byteLength(await page.evaluate(() => window.render_game_to_text()), "utf8");
  const performance = snapshot.performance ?? {};
	const webAssembly = await page.evaluate(() => (
		window.__pecking_order_runtime_metrics?.() ?? { wasmMemoryBytes: 0 }
	));
  return {
    label,
    diagnosticBytes,
    campaignStage: snapshot.campaign_stage,
    checkpoint: snapshot.checkpoint,
    native: {
      fps: performance.fps,
      processUsec: performance.process_usec,
      physicsProcessUsec: performance.physics_process_usec,
      staticMemoryBytes: performance.static_memory_bytes,
      staticMemoryPeakBytes: performance.static_memory_peak_bytes,
      objectCount: performance.object_count,
      nodeCount: performance.node_count,
      orphanNodeCount: performance.orphan_node_count,
      drawCalls: performance.draw_calls,
      renderedObjects: performance.rendered_objects,
      renderedPrimitives: performance.rendered_primitives,
    },
    chromium: {
      jsHeapUsedBytes: metrics.JSHeapUsedSize ?? 0,
      jsHeapTotalBytes: metrics.JSHeapTotalSize ?? 0,
      nodes: metrics.Nodes ?? 0,
      documents: metrics.Documents ?? 0,
      eventListeners: metrics.JSEventListeners ?? 0,
    },
		webAssembly,
  };
}

async function sampleFrames(label) {
  return page.evaluate(({ sampleLabel, durationMsec }) => new Promise((resolve) => {
    const intervals = [];
    let previous = performance.now();
    const started = previous;
    function frame(now) {
      intervals.push(now - previous);
      previous = now;
      if (now - started < durationMsec) {
        requestAnimationFrame(frame);
        return;
      }
      const sorted = [...intervals].sort((left, right) => left - right);
      const percentile = (ratio) => sorted[
        Math.min(sorted.length - 1, Math.floor(sorted.length * ratio))
      ] ?? 0;
      resolve({
        label: sampleLabel,
        elapsedMsec: now - started,
        frames: intervals.length,
        averageFps: intervals.length * 1_000 / Math.max(1, now - started),
        medianFrameMsec: percentile(0.5),
        p95FrameMsec: percentile(0.95),
        worstFrameMsec: sorted.at(-1) ?? 0,
      });
    }
    requestAnimationFrame(frame);
  }), { sampleLabel: label, durationMsec: frameSampleMsec });
}

async function exerciseCamera(cycle) {
  await page.keyboard.press("Home");
  await page.waitForTimeout(300);
  const started = Date.now();
  const direction = cycle % 2 === 0 ? "ArrowRight" : "ArrowLeft";
  await page.keyboard.down(direction);
  await page.waitForTimeout(180);
  await page.keyboard.up(direction);
  try {
    await waitForState("snapshot => snapshot.camera?.mode === 'free_overview'", maxInputResponseMsec);
  } catch (error) {
    const observed = await state();
    throw new Error(`camera tap was not published: ${JSON.stringify({
      direction,
      campaignStage: observed.campaign_stage,
      settingsVisible: observed.settings?.visible,
      flockwatchVisible: observed.flockwatch?.visible,
      firstClutchVisible: observed.first_clutch?.visible,
      camera: observed.camera,
    })}`, { cause: error });
  }
  const responseMsec = Date.now() - started;
  const canvas = page.locator("#canvas");
  const bounds = await canvas.boundingBox();
  assert.ok(bounds, "the game canvas must remain available during camera input");
  await page.mouse.move(bounds.x + bounds.width * 0.55, bounds.y + bounds.height * 0.52);
  await page.mouse.wheel(0, cycle % 2 === 0 ? -120 : 120);
  await page.waitForTimeout(200);
  const snapshot = await state();
  assert.equal(snapshot.camera?.input_enabled, true, "the active floor must retain camera input");
  return {
    direction,
    responseMsec,
    mode: snapshot.camera?.mode,
    desiredSize: snapshot.camera?.desired_size,
  };
}

async function exerciseFlockwatch() {
  await page.keyboard.press("KeyV");
  await waitForState("snapshot => snapshot.flockwatch?.visible === true");
  await page.keyboard.press("KeyV");
  await waitForState("snapshot => snapshot.flockwatch?.visible === false");
}

async function checkpoint(reason) {
  const accepted = await page.evaluate((checkpointReason) => {
    if (typeof window.__pecking_order_request_checkpoint !== "function") return false;
    window.__pecking_order_request_checkpoint(checkpointReason);
    return true;
  }, reason);
  assert.equal(accepted, true, "the lifecycle checkpoint bridge must stay installed");
  await waitForState(`snapshot => snapshot.checkpoint?.last_saved_reason === '${reason}'`);
  const snapshot = await state();
  assert.equal(snapshot.checkpoint?.status, "saved");
  assert.equal(snapshot.checkpoint?.write_failure_count, 0);
}

async function openSettings() {
  await page.keyboard.press("F10");
  await waitForState("snapshot => snapshot.settings?.visible === true");
  await page.waitForTimeout(250);
}

async function closeSettings() {
  await page.keyboard.press("F10");
  await waitForState("snapshot => snapshot.settings?.visible === false");
}

async function pressHeld(key, holdMsec = 650) {
  await page.keyboard.down(key);
  await page.waitForTimeout(holdMsec);
  await page.keyboard.up(key);
}

async function portableRoundTrip(cycle) {
  const before = await state();
  const beforeDigest = authoritativeDigest(before);
  await openSettings();

  // Settings deliberately focuses its close button. Fourteen forward focus
  // steps traverse the eight audio controls, five comfort controls, then the
  // first Career Backup action. Focus traversal also scrolls the button into
  // view, keeping this an end-user path instead of a test-only bridge.
  for (let index = 0; index < 14; index += 1) await page.keyboard.press("Tab");
  const downloadPromise = page.waitForEvent("download", { timeout: 10_000 });
  await page.keyboard.press("Enter");
  const download = await downloadPromise;
  const backupPath = path.join(outputDirectory, `career-cycle-${cycle}.json`);
  await download.saveAs(backupPath);
  const backup = fs.readFileSync(backupPath);
  assert.ok(backup.byteLength > 1_000, "a portable backup must contain a composite career ledger");
  assert.ok(backup.byteLength <= maxPortableBackupBytes, "a portable backup must remain inside its import ceiling");
  const envelope = JSON.parse(backup.toString("utf8"));
  assert.equal(typeof envelope.schema_version, "number");

  await waitForState("snapshot => /downloaded/i.test(snapshot.settings?.accessible_text ?? '')");
  const fileInput = page.locator('input[type="file"][accept=".json,application/json"]');
  await fileInput.setInputFiles({
    name: `career-cycle-${cycle}.json`,
    mimeType: "application/json",
    buffer: backup,
  });
  await waitForState("snapshot => /awaiting replacement confirmation/i.test(snapshot.settings?.accessible_text ?? '')");
  await page.keyboard.press("Enter");
  await waitForState("snapshot => snapshot.campaign_stage === 'title' && snapshot.resume_available === true");
  await page.waitForTimeout(400);
  await pressHeld("KeyC");
  try {
    await waitForState("snapshot => snapshot.campaign_stage === 'active'");
  } catch (error) {
    const observed = await state();
    throw new Error(`verified Continue did not activate: ${JSON.stringify({
      cycle,
      campaignStage: observed.campaign_stage,
      intakePhase: observed.campaign_intake_phase,
      resumeAvailable: observed.resume_available,
      checkpoint: observed.checkpoint,
    })}`, { cause: error });
  }
  await page.waitForTimeout(350);

  const after = await state();
  assert.deepEqual(
    authoritativeDigest(after),
    beforeDigest,
    "export, validation, replacement, and Continue must preserve the authoritative career exactly",
  );
  assert.equal(after.checkpoint?.has_candidate, true);
  assert.equal(after.checkpoint?.has_checkpoint, true);
  assert.equal(await fileInput.inputValue(), "");
  return {
    bytes: backup.byteLength,
    schemaVersion: envelope.schema_version,
    tickRevision: after.performance?.authoritative_tick_revision,
  };
}

const samples = [];
const frameSamples = [];
const interactions = [];
const backups = [];
const auditFailures = [];

try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitForState("snapshot => snapshot.loaded === true", 90_000);
  await waitForState(
    "snapshot => snapshot.boot?.optional_visuals?.ready === true || snapshot.boot?.optional_visuals?.deferred !== true",
    60_000,
  );
  await page.keyboard.press("KeyN");
  await waitForState("snapshot => snapshot.campaign_stage === 'active'");

  // Complete the authored morning directive so the soak measures the live
  // management floor rather than a correctly input-locked onboarding filing.
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
  await page.keyboard.press("Digit1");
  await page.keyboard.press("Enter");
  await waitForState(
    "snapshot => snapshot.campaign_stage === 'active' && snapshot.pending_decision_kind === '' && snapshot.shift_phase === 1",
  );

  const opening = await state();
  if (opening.first_clutch?.visible === true) {
    const canvas = page.locator("#canvas");
    const bounds = await canvas.boundingBox();
    assert.ok(bounds, "the First Clutch coach requires the live canvas");
    await page.mouse.click(
      bounds.x + bounds.width * 0.435,
      bounds.y + bounds.height * (168 / 720),
    );
    await waitForState("snapshot => snapshot.first_clutch?.visible === false");
  }

  // Escape restores overview without clicking a hen and opening her required
  // First Clutch personnel file. The camera's pre-GUI path is focus-independent.
  await page.keyboard.press("Escape");
  await waitForState("snapshot => snapshot.camera?.input_enabled === true");

  await checkpoint("runtime_soak_warmup");
  await page.waitForTimeout(750);
  samples.push(await engineHealth("baseline"));

  for (let cycle = 1; cycle <= cycles; cycle += 1) {
    interactions.push(await exerciseCamera(cycle));
    await exerciseFlockwatch();
    await openSettings();
    await closeSettings();
    await checkpoint(`runtime_soak_cycle_${cycle}`);
    backups.push(await portableRoundTrip(cycle));
    frameSamples.push(await sampleFrames(`cycle-${cycle}`));
    samples.push(await engineHealth(`cycle-${cycle}`));
  }

  await page.screenshot({
    path: path.join(outputDirectory, "final-active-floor.png"),
    fullPage: true,
  });

  const baseline = samples[0];
  const final = samples.at(-1);
  const growth = {
    nativeStaticMemoryBytes: final.native.staticMemoryBytes - baseline.native.staticMemoryBytes,
		wasmMemoryBytes: final.webAssembly.wasmMemoryBytes - baseline.webAssembly.wasmMemoryBytes,
    nativeObjectCount: final.native.objectCount - baseline.native.objectCount,
    nativeNodeCount: final.native.nodeCount - baseline.native.nodeCount,
    nativeOrphanNodeCount: final.native.orphanNodeCount - baseline.native.orphanNodeCount,
    jsHeapUsedBytes: final.chromium.jsHeapUsedBytes - baseline.chromium.jsHeapUsedBytes,
    chromiumNodes: final.chromium.nodes - baseline.chromium.nodes,
    chromiumDocuments: final.chromium.documents - baseline.chromium.documents,
    chromiumEventListeners: final.chromium.eventListeners - baseline.chromium.eventListeners,
  };

  if (growth.nativeStaticMemoryBytes > maxNativeGrowthBytes) {
    auditFailures.push(`native static memory grew ${growth.nativeStaticMemoryBytes} bytes`);
  }
	if (baseline.webAssembly.wasmMemoryBytes <= 0) {
		auditFailures.push("the wrapper did not expose a live WebAssembly heap measurement");
	} else if (growth.wasmMemoryBytes > maxWasmGrowthBytes) {
		auditFailures.push(`WebAssembly heap grew ${growth.wasmMemoryBytes} bytes`);
	}
  if (growth.jsHeapUsedBytes > maxJsGrowthBytes) {
    auditFailures.push(`Chromium JS heap grew ${growth.jsHeapUsedBytes} bytes`);
  }
  if (growth.nativeObjectCount > maxObjectGrowth) {
    auditFailures.push(`Godot object count grew ${growth.nativeObjectCount}`);
  }
  if (growth.nativeNodeCount > maxNodeGrowth) {
    auditFailures.push(`Godot node count grew ${growth.nativeNodeCount}`);
  }
  if (growth.nativeOrphanNodeCount > maxOrphanGrowth) {
    auditFailures.push(`Godot orphan-node count grew ${growth.nativeOrphanNodeCount}`);
  }
  if (growth.chromiumDocuments !== 0) {
    auditFailures.push(`Chromium document count grew ${growth.chromiumDocuments}`);
  }
  if (growth.chromiumEventListeners > 4) {
    auditFailures.push(`Chromium event-listener count grew ${growth.chromiumEventListeners}`);
  }
  for (const interaction of interactions) {
    if (interaction.responseMsec > maxInputResponseMsec) {
      auditFailures.push(`camera input took ${interaction.responseMsec}ms to reach the diagnostic`);
    }
  }
  for (const sample of samples) {
    if (sample.diagnosticBytes > maxDiagnosticBytes) {
      auditFailures.push(`${sample.label} diagnostic reached ${sample.diagnosticBytes} bytes`);
    }
    if (sample.checkpoint?.write_failure_count !== 0) {
      auditFailures.push(`${sample.label} reported a checkpoint write failure`);
    }
  }
  for (const frameSample of frameSamples) {
    if (frameSample.frames < 2 || frameSample.worstFrameMsec > maxInputResponseMsec) {
      auditFailures.push(`${frameSample.label} stopped producing responsive animation frames`);
    }
  }
  auditFailures.push(...browserErrors);

  const longTasks = await page.evaluate(() => window.__peckingSoakLongTasks ?? []);
  const report = {
    passed: auditFailures.length === 0,
    url,
    renderer: "headless Chromium / ANGLE SwiftShader; stability and growth are gated, absolute GPU throughput is informational",
    configuration: {
      cycles,
      frameSampleMsec,
      maxNativeGrowthBytes,
		maxWasmGrowthBytes,
      maxJsGrowthBytes,
      maxObjectGrowth,
      maxNodeGrowth,
      maxOrphanGrowth,
      maxInputResponseMsec,
      maxDiagnosticBytes,
    },
    growth,
    interactions,
    backups,
    frameSamples,
    samples,
    longTasks: {
      count: longTasks.length,
      totalMsec: longTasks.reduce((sum, task) => sum + task.durationMsec, 0),
      worstMsec: Math.max(0, ...longTasks.map((task) => task.durationMsec)),
    },
    browserErrors,
    auditFailures,
  };
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(report, null, 2));
  assert.deepEqual(auditFailures, []);
} finally {
  await browser.close();
}
