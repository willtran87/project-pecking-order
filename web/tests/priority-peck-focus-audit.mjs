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

const url = process.argv[2] ?? "http://localhost:3000/?build=priority-peck-focus-audit";
const outputDirectory = path.resolve(
  process.argv[3] ?? "../output/web-game/priority-peck-focus-v1",
);
const auditMode = process.argv[4] ?? "land";
assert.ok(["land", "miss"].includes(auditMode), "audit mode must be land or miss");
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

async function clickAuthored(x, y) {
  const bounds = await page.locator("#canvas").boundingBox();
  assert.ok(bounds, "the Godot canvas must remain mounted");
  await page.mouse.click(
    bounds.x + bounds.width * x / 1280,
    bounds.y + bounds.height * y / 720,
  );
}

const report = {
  passed: false,
  url,
  auditMode,
  renderer: "headless Chromium / ANGLE SwiftShader; interaction and state are gated, physical GPU throughput is not claimed",
  approach: {},
  ready: {},
  landed: {},
  browserErrors,
  auditFailures: [],
};

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
  if ((await state()).character_dialogue?.visible === true) {
    await page.keyboard.press("Enter");
  }
  await waitForState("snapshot => snapshot.character_dialogue?.visible === false", 30_000);
  await page.keyboard.press("Tab");
  await waitForState("snapshot => snapshot.focused_worker_id >= 0");
	// Desktop Tab is currently owned by dossier focus traversal. Cycle through
	// the same allow-listed Next Hen action used by the production touch control.
	for (let cycle = 0; cycle < 12; cycle += 1) {
	  const focused = await state();
	  if (focused.focused_worker_id === 0) break;
	  await page.evaluate(() => window.__pecking_order_mobile_action?.("cycle_hen"));
	  await waitForState(
	    `snapshot => snapshot.focused_worker_id !== ${focused.focused_worker_id}`,
	    5_000,
	  );
	}
	assert.equal((await state()).focused_worker_id, 0, "Next Hen should select first-arrival Mabel deterministically");
	// Let the selected hen finish her real arrival route and pull an exact file at
	// readable speed. Starting 10× during the staggered walk-in can reach the
	// scheduled 11:00 incident before any seated timing interaction exists.
	await page.keyboard.press("Digit1");
	await waitForState(
	  "snapshot => snapshot.production?.focused_claim?.id > 0 && snapshot.production?.focused_peck_assist?.window_state === 'not_ready'",
	  90_000,
	);
  await page.keyboard.press("Digit3");
  await waitForState("snapshot => snapshot.clock_speed_index === 3");
  await waitForState(
    "snapshot => snapshot.priority_peck_focus?.limiting === true && snapshot.clock_effective_multiplier === 1",
    30_000,
  );

  const approach = await state();
  report.approach = {
    requestedMultiplier: approach.priority_peck_focus?.requested_multiplier,
    effectiveMultiplier: approach.clock_effective_multiplier,
    workerId: approach.priority_peck_focus?.worker_id,
    windowState: approach.production?.focused_peck_assist?.window_state,
    progress: approach.production?.focused_progress,
  };
  assert.equal(report.approach.requestedMultiplier, 10);
  assert.equal(report.approach.effectiveMultiplier, 1);
  await page.screenshot({ path: path.join(outputDirectory, "priority-focus-approach.png"), fullPage: true });

	await waitForState(
	  "snapshot => snapshot.production?.focused_peck_assist?.window_state === 'open' && snapshot.priority_peck_focus?.limiting === true && snapshot.character_dialogue?.visible === false",
	  30_000,
	);
  const ready = await state();
  const claimId = Number(ready.production?.focused_peck_assist?.claim_id ?? -1);
  const readyIntent = ready.hen_intents?.find(
    (intent) => intent.worker_id === ready.focused_worker_id,
  );
  report.ready = {
    claimId,
    progress: ready.production?.focused_progress,
    timingLabel: ready.production?.focused_peck_assist?.timing_label,
    requestedMultiplier: ready.priority_peck_focus?.requested_multiplier,
    effectiveMultiplier: ready.clock_effective_multiplier,
    audioCue: ready.audio?.feedback?.last_cue,
    audioBus: ready.audio?.feedback?.last_bus,
    worldPulseSerial: readyIntent?.priority_peck_ready_pulse_serial,
  };
  assert.ok(claimId > 0, "the focused gold window must belong to a real claim");
  assert.equal(report.ready.requestedMultiplier, 10);
  assert.equal(report.ready.effectiveMultiplier, 1);
  assert.equal(report.ready.audioCue, "priority_peck_ready");
  assert.equal(report.ready.audioBus, "Alerts");
  assert.ok(report.ready.worldPulseSerial > 0, "the inspected hen's world pin must receive the same opportunity transition");
  await page.screenshot({ path: path.join(outputDirectory, "priority-focus-ready.png"), fullPage: true });

  if (auditMode === "miss") {
    const missStarted = Date.now();
    let missedState = await state();
    while (
      missedState.production?.focused_peck_assist?.window_state !== "missed"
      && Date.now() - missStarted < 120_000
    ) {
      if (
        missedState.character_dialogue?.visible === true
        && missedState.character_dialogue?.presentation_mode === "visual_novel"
      ) {
        await page.keyboard.press("Enter");
      }
      await page.waitForTimeout(250);
      missedState = await state();
    }
    assert.equal(
      missedState.production?.focused_peck_assist?.window_state,
      "missed",
      "the inspected real claim should cross its authoritative closing boundary",
    );
    const missedIntent = missedState.hen_intents?.find(
      (intent) => intent.worker_id === missedState.focused_worker_id,
    );
    report.missed = {
      responseMsec: Date.now() - missStarted,
      claimId: missedState.production?.focused_peck_assist?.claim_id,
      windowState: missedState.production?.focused_peck_assist?.window_state,
      streak: missedState.production?.focused_peck_assist?.streak,
      worldMissedSerial: missedIntent?.priority_peck_missed_pulse_serial,
      dossierMissedSerial: missedState.priority_peck_focus?.missed_link_serial,
      dossierMissedAnimated: missedState.priority_peck_focus?.missed_link_animated,
      requestedMultiplier: missedState.priority_peck_focus?.requested_multiplier,
      effectiveMultiplier: missedState.clock_effective_multiplier,
      precisionLimiting: missedState.priority_peck_focus?.limiting,
      resultHoldKind: missedState.priority_peck_focus?.result_hold_kind,
      resultHoldMsecRemaining: missedState.priority_peck_focus?.result_hold_msec_remaining,
      focusedWorkerId: missedState.focused_worker_id,
      cameraMode: missedState.camera?.mode,
      dialogueVisible: missedState.character_dialogue?.visible,
      dialogueSuspended: missedState.character_dialogue?.suspended,
    };
    assert.equal(report.missed.claimId, claimId, "the miss must belong to the exact visible claim");
    assert.equal(report.missed.streak, 0, "a real miss must leave the timing chain reset");
    assert.ok(report.missed.worldMissedSerial > 0, "the selected world pin must receive one missed retreat");
    assert.ok(report.missed.dossierMissedSerial > 0, "the dossier must receive the same missed retreat");
    assert.equal(report.missed.dossierMissedAnimated, true);
    assert.equal(report.missed.requestedMultiplier, 10, "10× must remain selected after a miss");
    assert.equal(report.missed.effectiveMultiplier, 1, "the missed consequence must receive a readable 1× beat");
    assert.equal(report.missed.precisionLimiting, true);
    assert.equal(report.missed.resultHoldKind, "missed");
    assert.ok(report.missed.resultHoldMsecRemaining > 0);
    assert.equal(report.missed.focusedWorkerId, ready.focused_worker_id, "the missed beat must retain the inspected hen");
    assert.equal(report.missed.cameraMode, "worker_focus", "the missed beat must retain the inspected camera");
    assert.equal(report.missed.dialogueVisible, false, "ambient floor chat must wait behind the missed beat");
    await page.screenshot({ path: path.join(outputDirectory, "priority-peck-missed.png"), fullPage: true });
    await waitForState(
      "snapshot => snapshot.priority_peck_focus?.limiting === false && snapshot.clock_effective_multiplier === 10",
      5_000,
    );
    const restoredAfterMiss = await state();
    report.missed.restoredMultiplier = restoredAfterMiss.clock_effective_multiplier;
    report.missed.restoredPrecisionLimiting = restoredAfterMiss.priority_peck_focus?.limiting;
    assert.equal(report.missed.restoredMultiplier, 10, "10× must restore automatically after the missed result beat");
    assert.equal(report.missed.restoredPrecisionLimiting, false);
  } else {
  const inputStarted = Date.now();
  await page.keyboard.press("KeyE");
  const inputDispatched = Date.now();
  await waitForState(
    `snapshot => snapshot.production?.last_peck_assist?.claim_id === ${claimId}`,
    10_000,
  );
  const inputSettled = Date.now();
  const landed = await state();
  report.landed = {
    responseMsec: inputSettled - inputStarted,
    keyDispatchMsec: inputDispatched - inputStarted,
    diagnosticSettleMsec: inputSettled - inputDispatched,
    claimId: landed.production?.last_peck_assist?.claim_id,
    rating: landed.production?.last_peck_assist?.rating,
    progressGain: landed.production?.last_peck_assist?.progress_gain,
    qualityModifier: landed.production?.last_peck_assist?.quality_modifier,
    streak: landed.production?.last_peck_assist?.streak,
    requestedMultiplier: landed.priority_peck_focus?.requested_multiplier,
    effectiveMultiplier: landed.clock_effective_multiplier,
    precisionLimiting: landed.priority_peck_focus?.limiting,
    resultHoldMsecRemaining: landed.priority_peck_focus?.result_hold_msec_remaining,
    focusedWindowState: landed.production?.focused_peck_assist?.window_state,
  };
  assert.equal(report.landed.claimId, claimId, "Priority Peck must land on the exact visible claim");
  assert.ok(["perfect", "strong", "steady", "scramble"].includes(report.landed.rating));
  assert.ok(report.landed.progressGain > 0, "the retained receipt must expose its exact progress gain");
  assert.equal(report.landed.requestedMultiplier, 10, "10× must remain selected after the action");
  assert.equal(report.landed.effectiveMultiplier, 1, "the result beat must remain at readable 1×");
  assert.equal(report.landed.precisionLimiting, true);
  assert.ok(report.landed.resultHoldMsecRemaining > 0, "the settled receipt should retain a bounded visible hold");
  assert.ok(["used", "waiting"].includes(report.landed.focusedWindowState));
  assert.ok(report.landed.responseMsec <= 2_500, "semantic input should settle within the existing response budget");
  await page.screenshot({ path: path.join(outputDirectory, "priority-peck-contact.png"), fullPage: true });
  await waitForState(
    "snapshot => snapshot.priority_peck_focus?.limiting === false && snapshot.clock_effective_multiplier === 10",
    5_000,
  );
  const restored = await state();
  report.restored = {
    requestedMultiplier: restored.priority_peck_focus?.requested_multiplier,
    effectiveMultiplier: restored.clock_effective_multiplier,
    precisionLimiting: restored.priority_peck_focus?.limiting,
  };
  assert.equal(report.restored.requestedMultiplier, 10);
  assert.equal(report.restored.effectiveMultiplier, 10);
  assert.equal(report.restored.precisionLimiting, false);
  await page.screenshot({ path: path.join(outputDirectory, "priority-peck-landed.png"), fullPage: true });
  }

  report.auditFailures.push(...browserErrors);
  report.passed = report.auditFailures.length === 0;
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(report, null, 2));
  assert.deepEqual(report.auditFailures, []);
} catch (error) {
  report.auditFailures.push(String(error));
  report.failureState = await state().catch(() => ({}));
  fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(report, null, 2));
  await page.screenshot({ path: path.join(outputDirectory, "failure.png"), fullPage: true }).catch(() => {});
  throw error;
} finally {
  await browser.close();
}
