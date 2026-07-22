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

const url = process.argv[2] ?? "http://localhost:3000/?build=active-progression-audit";
const outputDirectory = path.resolve(
  process.argv[3] ?? "../output/web-game/active-progression-audit",
);
const shifts = Math.max(2, Number(process.env.ACTIVE_PROGRESSION_SHIFTS ?? 2));
const fullProbation = shifts >= 5;
const challengeContractId = process.env.ACTIVE_PROGRESSION_CONTRACT ?? "standard_filing";
const strategyId = process.env.ACTIVE_PROGRESSION_STRATEGY ?? "first_available";
const yearTwoStrategyId = process.env.ACTIVE_PROGRESSION_YEAR_TWO_STRATEGY ?? strategyId;
const supportedStrategyIds = new Set(["first_available", "stewardship", "executive_harvest"]);
assert.ok(supportedStrategyIds.has(strategyId), `unsupported progression strategy ${strategyId}`);
assert.ok(supportedStrategyIds.has(yearTwoStrategyId), `unsupported Year 2 strategy ${yearTwoStrategyId}`);
const auditRenderer = process.env.ACTIVE_PROGRESSION_RENDERER ?? "swiftshader";
assert.ok(["swiftshader", "hardware"].includes(auditRenderer), `unsupported audit renderer ${auditRenderer}`);
const enterSeniorRoost = process.env.ACTIVE_PROGRESSION_ENTER_SENIOR === "1";
const seniorShifts = Math.max(0, Math.min(24, Number(process.env.ACTIVE_PROGRESSION_SENIOR_SHIFTS ?? 0)));
const continueYearTwo = process.env.ACTIVE_PROGRESSION_CONTINUE_YEAR_TWO === "1";
const yearOneMandateId = process.env.ACTIVE_PROGRESSION_YEAR_ONE_MANDATE ?? "standard_board_book";
const supportedYearOneMandateIds = new Set([
  "standard_board_book",
  "shell_stewardship",
  "flock_continuity",
]);
assert.ok(supportedYearOneMandateIds.has(yearOneMandateId), `unsupported Year 1 mandate ${yearOneMandateId}`);
const yearTwoMandateMode = process.env.ACTIVE_PROGRESSION_YEAR_TWO_MANDATE ?? "fallback";
const yearTwoMandateId = process.env.ACTIVE_PROGRESSION_YEAR_TWO_MANDATE_ID ?? "";
const supportedAdvancedMandateIds = new Set(["mutual_assurance", "executive_harvest"]);
assert.ok(yearTwoMandateId === "" || supportedAdvancedMandateIds.has(yearTwoMandateId), `unsupported Year 2 advanced mandate ${yearTwoMandateId}`);
const expectedAdvancedOutcome = process.env.ACTIVE_PROGRESSION_EXPECT_ADVANCED_OUTCOME ?? "any";
assert.ok(["fallback", "advanced"].includes(yearTwoMandateMode), "Year 2 mandate mode must be fallback or advanced");
assert.ok(["any", "success", "failure"].includes(expectedAdvancedOutcome), "advanced outcome must be any, success, or failure");
assert.ok(!continueYearTwo || seniorShifts >= 12, "Year 2 continuation requires at least one complete twelve-shift Senior year");
assert.ok(seniorShifts <= 12 || continueYearTwo, "Senior shifts beyond Year 1 require explicit Year 2 continuation");
const seniorPolicyId = process.env.ACTIVE_PROGRESSION_SENIOR_POLICY ?? "merit_grants";
const seniorPolicyDigits = {
  merit_grants: 1,
  flock_dividend: 2,
  harvest_forecast: 3,
};
assert.ok(
  Object.hasOwn(seniorPolicyDigits, seniorPolicyId),
  `unsupported Senior policy ${seniorPolicyId}`,
);
const seniorPolicySequence = (process.env.ACTIVE_PROGRESSION_SENIOR_POLICIES ?? seniorPolicyId)
  .split(",")
  .map((value) => value.trim())
  .filter(Boolean);
assert.ok(seniorPolicySequence.length > 0, "at least one Senior policy is required");
for (const policyId of seniorPolicySequence) {
  assert.ok(Object.hasOwn(seniorPolicyDigits, policyId), `unsupported Senior policy ${policyId}`);
}
while (seniorPolicySequence.length < Math.ceil(seniorShifts / 3)) {
  seniorPolicySequence.push(seniorPolicySequence.at(-1));
}
// SwiftShader is intentionally the slowest supported audit renderer. Keep its
// wall-clock ceiling bounded but separate from the interaction/frame-response
// budgets that represent playability on a hardware-accelerated browser.
const maxWallMsec = Number(process.env.ACTIVE_PROGRESSION_MAX_MSEC ?? 360_000);
const maxNativeGrowthBytes = Number(process.env.ACTIVE_PROGRESSION_NATIVE_GROWTH_BYTES ?? 32 * 1024 * 1024);
// A complete Senior year includes the probation reveal, Senior handoff, and
// four-quarter residency. Its end-to-end ceiling composes those established
// route ceilings instead of applying the one-quarter ceiling to their sum. The
// Senior handoff and Senior-year increments remain independently checked below,
// so one transition cannot hide unbounded growth in the aggregate allowance.
const fullSeniorYear = seniorShifts >= 12;
const maxWasmGrowthBytes = Number(process.env.ACTIVE_PROGRESSION_WASM_GROWTH_BYTES ?? (
  fullSeniorYear ? 160 : seniorShifts > 0 ? 96 : 64
) * 1024 * 1024);
const maxJsGrowthBytes = Number(process.env.ACTIVE_PROGRESSION_JS_GROWTH_BYTES ?? 16 * 1024 * 1024);
// Full probation crosses authored capacity, facility, commendation, and report
// reveal stages that a two-shift smoke never reaches. Keep separate bounded
// ceilings, then measure the Senior handoff increment against final probation.
const additionalSeniorQuarters = Math.max(0, Math.ceil(seniorShifts / 3) - 4);
const maxObjectGrowth = Number(process.env.ACTIVE_PROGRESSION_OBJECT_GROWTH ?? (
  // A route beyond twelve Senior shifts crosses a second annual gate and more
  // three-shift quarters. Compose each bounded quarter allowance instead of
  // applying the original four-quarter ceiling to an arbitrary longer route.
  fullProbation ? (fullSeniorYear ? 6_656 + additionalSeniorQuarters * 1_024 : seniorShifts > 0 ? 4_096 : 2_304) : 768
));
const maxNodeGrowth = Number(process.env.ACTIVE_PROGRESSION_NODE_GROWTH ?? (
  fullProbation ? (fullSeniorYear ? 1_344 + additionalSeniorQuarters * 192 : seniorShifts > 0 ? 768 : 512) : 128
));
const maxOrphanGrowth = Number(process.env.ACTIVE_PROGRESSION_ORPHAN_GROWTH ?? 4);
const maxInputResponseMsec = Number(process.env.ACTIVE_PROGRESSION_INPUT_RESPONSE_MSEC ?? 2_500);
const maxSeniorObjectGrowth = Number(process.env.ACTIVE_PROGRESSION_SENIOR_OBJECT_GROWTH ?? 256);
const maxSeniorNodeGrowth = Number(process.env.ACTIVE_PROGRESSION_SENIOR_NODE_GROWTH ?? 64);
const maxProbationObjectGrowth = Number(process.env.ACTIVE_PROGRESSION_PROBATION_OBJECT_GROWTH ?? (seniorShifts > 0 ? 4_096 : 2_304));
const maxProbationNodeGrowth = Number(process.env.ACTIVE_PROGRESSION_PROBATION_NODE_GROWTH ?? (seniorShifts > 0 ? 768 : 512));
const maxProbationWasmGrowthBytes = Number(process.env.ACTIVE_PROGRESSION_PROBATION_WASM_GROWTH_BYTES ?? (seniorShifts > 0 ? 96 : 64) * 1024 * 1024);
const maxSeniorQuarterObjectGrowth = Number(process.env.ACTIVE_PROGRESSION_SENIOR_QUARTER_OBJECT_GROWTH ?? (
  seniorShifts >= 12 ? 5_120 + additionalSeniorQuarters * 1_024 : 1_024
));
const maxSeniorQuarterNodeGrowth = Number(process.env.ACTIVE_PROGRESSION_SENIOR_QUARTER_NODE_GROWTH ?? (
  seniorShifts >= 12 ? 960 + additionalSeniorQuarters * 192 : 192
));
const maxSeniorQuarterWasmGrowthBytes = Number(process.env.ACTIVE_PROGRESSION_SENIOR_QUARTER_WASM_GROWTH_BYTES ?? (seniorShifts >= 12 ? 128 : 32) * 1024 * 1024);
const maxBrowserEventListenerGrowth = Number(process.env.ACTIVE_PROGRESSION_EVENT_LISTENER_GROWTH ?? (seniorShifts > 0 ? 8 : 4));

fs.mkdirSync(outputDirectory, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: auditRenderer === "hardware"
    ? ["--use-gl=angle", "--use-angle=d3d11", "--js-flags=--expose-gc"]
    : ["--use-gl=angle", "--use-angle=swiftshader", "--js-flags=--expose-gc"],
});
const context = await browser.newContext({
  viewport: { width: 1440, height: 900 },
});
const page = await context.newPage();
const browserErrors = [];
page.on("console", (message) => {
  if (message.type() === "error") browserErrors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => browserErrors.push(`page: ${String(error)}`));

await page.addInitScript(() => {
  window.__peckingProgressionLongTasks = [];
  if (typeof PerformanceObserver !== "undefined") {
    try {
      const observer = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          window.__peckingProgressionLongTasks.push({
            startMsec: entry.startTime,
            durationMsec: entry.duration,
          });
        }
      });
      observer.observe({ entryTypes: ["longtask"] });
    } catch {
      // Frame and input probes remain authoritative when Long Task timing is absent.
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
  await page.waitForTimeout(120);
}

async function health(label) {
  await collectGarbage();
  const snapshot = await state();
  const metrics = await chromiumMetrics();
  const performance = snapshot.performance ?? {};
  const webAssembly = await page.evaluate(() => (
    window.__pecking_order_runtime_metrics?.() ?? { wasmMemoryBytes: 0 }
  ));
  return {
    label,
    campaignDay: snapshot.campaign_day,
    campaignStage: snapshot.campaign_stage,
    campaignScore: snapshot.campaign_score,
    tickRevision: performance.authoritative_tick_revision,
    checkpoint: snapshot.checkpoint,
    economy: {
      feedFundCents: snapshot.economy?.feed_fund_cents,
      dailyHenPayrollCents: snapshot.economy?.daily_hen_payroll_cents,
    },
    native: {
      fps: performance.fps,
      processUsec: performance.process_usec,
      physicsProcessUsec: performance.physics_process_usec,
      staticMemoryBytes: performance.static_memory_bytes,
      objectCount: performance.object_count,
      nodeCount: performance.node_count,
      orphanNodeCount: performance.orphan_node_count,
      drawCalls: performance.draw_calls,
    },
    chromium: {
      jsHeapUsedBytes: metrics.JSHeapUsedSize ?? 0,
      nodes: metrics.Nodes ?? 0,
      documents: metrics.Documents ?? 0,
      eventListeners: metrics.JSEventListeners ?? 0,
    },
    webAssembly,
  };
}

async function sampleFrames(label, durationMsec = 1_500) {
  return page.evaluate(({ sampleLabel, duration }) => new Promise((resolve) => {
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
  }), { sampleLabel: label, duration: durationMsec });
}

async function clickAuthored(x, y) {
  const bounds = await page.locator("#canvas").boundingBox();
  assert.ok(bounds, "the live Godot canvas must remain mounted");
  await page.mouse.click(
    bounds.x + bounds.width * x / 1280,
    bounds.y + bounds.height * y / 720,
  );
}

async function requestCheckpoint(reason) {
  const accepted = await page.evaluate((checkpointReason) => {
    if (typeof window.__pecking_order_request_checkpoint !== "function") return false;
    window.__pecking_order_request_checkpoint(checkpointReason);
    return true;
  }, reason);
  assert.equal(accepted, true, "the allow-listed lifecycle checkpoint bridge must remain installed");
  await waitForState(`snapshot => snapshot.checkpoint?.last_saved_reason === '${reason}'`, 15_000);
  const snapshot = await state();
  assert.equal(snapshot.checkpoint?.status, "saved");
  assert.equal(snapshot.checkpoint?.write_failure_count, 0);
}

async function resolveVisibleDecision() {
  const before = await state();
  const activeStrategyId = Number(before.senior_roost?.year ?? 1) >= 2
    ? yearTwoStrategyId
    : strategyId;
  const kind = before.pending_decision_kind;
  assert.notEqual(kind, "", "a visible decision must publish its semantic kind");
  const decision = before.pending_decision ?? {};
  const options = Array.isArray(decision.options) ? decision.options : [];
  let selected = options.find((option) => option.index === 1);
  if (activeStrategyId === "stewardship") {
    let desiredId = "";
    if (kind === "directive") {
      desiredId = [
        "sustainable_flock",
        "sustainable_flock",
        "shell_assurance",
        "sustainable_flock",
        "sustainable_flock",
      ][Math.max(0, Math.min(4, Number(before.campaign_day ?? 1) - 1))];
    } else if (kind === "credit_allocation" || kind === "major_event") {
      desiredId = decision.id === "golden_egg_dossier"
        ? "name_the_layer"
        : decision.id === "flock_restructuring"
          ? "fund_redeployment"
          : "reward_top_layer";
    }
    selected = options.find((option) => option.id === desiredId && option.available !== false)
      ?? (kind === "incident"
        ? ["care", "quality", "danger"]
          .map((tone) => options.find((option) => option.tone === tone && option.available !== false))
          .find(Boolean)
        : undefined)
      ?? options.find((option) => option.available !== false);
  } else if (activeStrategyId === "executive_harvest") {
    let desiredId = "";
    if (kind === "directive") {
      desiredId = "sustainable_flock";
    } else if (kind === "incident") {
      desiredId = {
        wellness_request: "grant_breaks",
        farmer_story: "polish_story",
        flock_petition: "deny_and_monitor",
        ledger_molt: "patch",
        feed_shortfall: "buy_grain",
      }[decision.id] ?? "";
    } else if (kind === "credit_allocation") {
      desiredId = "claim_management_innovation";
    } else if (kind === "major_event") {
      desiredId = decision.id === "golden_egg_dossier"
        ? "patent_rooster_method"
        : decision.id === "flock_restructuring"
          ? "nominate_variance"
          : "";
    }
    selected = options.find((option) => option.id === desiredId && option.available !== false)
      ?? options.find((option) => option.available !== false);
  }
  assert.ok(selected, `${kind} must expose a selectable semantic option`);
  assert.ok(selected.index >= 1 && selected.index <= 3, `${kind} option index must remain keyboard-addressable`);
  await page.keyboard.press(`Digit${selected.index}`);
  await page.keyboard.press("Enter");
  await waitForState(`snapshot => snapshot.pending_decision_kind !== '${kind}' || snapshot.shift_phase !== ${before.shift_phase}`, 15_000);
  return {
    kind,
    decisionId: decision.id ?? "",
    optionId: selected.id ?? "",
    optionTone: selected.tone ?? "",
  };
}

async function probeCamera() {
  await page.keyboard.press("Escape");
  await waitForState("snapshot => snapshot.camera?.input_enabled === true", maxInputResponseMsec);
  await page.waitForTimeout(300);
  const before = await state();
  const started = Date.now();
  await page.keyboard.down("ArrowRight");
  await page.waitForTimeout(180);
  await page.keyboard.up("ArrowRight");
  await waitForState("snapshot => snapshot.camera?.mode === 'free_overview'", maxInputResponseMsec);
  const after = await state();
  return {
    responseMsec: Date.now() - started,
    beforeTarget: before.camera?.view_target,
    afterTarget: after.camera?.view_target,
  };
}

const startedAt = Date.now();
const shiftsCompleted = [];
const seniorShiftsCompleted = [];
const decisions = [];
const frameSamples = [];
const stageTransitions = [];
let lastTransition = "";

function recordTransition(snapshot) {
  const transition = [
    snapshot.campaign_day,
    snapshot.campaign_stage,
    snapshot.shift_phase,
    snapshot.pending_decision_kind,
    snapshot.clock_speed_index,
  ].join(":");
  if (transition !== lastTransition) {
    stageTransitions.push({
      elapsedMsec: Date.now() - startedAt,
      campaignDay: snapshot.campaign_day,
      campaignStage: snapshot.campaign_stage,
      shiftPhase: snapshot.shift_phase,
      pendingDecisionKind: snapshot.pending_decision_kind,
      clockSpeedIndex: snapshot.clock_speed_index,
      eggsToday: snapshot.eggs_today,
      quotaTarget: snapshot.quota_target,
      tickRevision: snapshot.performance?.authoritative_tick_revision,
    });
    lastTransition = transition;
  }
}

try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitForState("snapshot => snapshot.loaded === true", 90_000);
  await waitForState(
    "snapshot => snapshot.boot?.optional_visuals?.ready === true || snapshot.boot?.optional_visuals?.deferred !== true",
    60_000,
  );
  if (challengeContractId === "supported_flock") {
    await clickAuthored(800, 388);
    await page.keyboard.press("ArrowDown");
    await page.keyboard.press("Enter");
    await waitForState("snapshot => snapshot.selected_new_challenge_contract?.id === 'supported_flock'");
  } else {
    assert.equal(challengeContractId, "standard_filing", "the progression gate supports the shipped Standard or Learning contracts");
  }
  await page.keyboard.press("KeyN");
  await waitForState("snapshot => snapshot.campaign_stage === 'active'");
  const activated = await state();
  assert.equal(activated.challenge_contract?.id, challengeContractId, "the requested permanent challenge contract must activate");

  // Follow the shipped first briefing, then use the visible optional Skip affordance
  // so the endurance gate measures management progression rather than tutorial skill.
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
  if (strategyId === "stewardship") {
    await waitForState("snapshot => snapshot.pending_decision_kind === 'directive'");
    decisions.push({ campaignDay: 1, campaignStage: "active", ...(await resolveVisibleDecision()) });
  } else {
    await page.keyboard.press("Digit1");
    await page.keyboard.press("Enter");
  }
  await waitForState("snapshot => snapshot.pending_decision_kind === '' && snapshot.shift_phase === 1");
  let opening = await state();
  if (opening.first_clutch?.visible === true) {
    await waitForState(
      "snapshot => snapshot.first_clutch?.visible === true && snapshot.first_clutch?.can_skip === true && snapshot.first_clutch?.skip_button_rect?.width > 0 && snapshot.first_clutch?.skip_button_rect?.height > 0",
      15_000,
    );
    opening = await state();
    const skipRect = opening.first_clutch?.skip_button_rect ?? {};
    assert.equal(opening.first_clutch?.can_skip, true, "the optional coach must disclose its Skip action");
    assert.ok(skipRect.width > 0 && skipRect.height > 0, "the visible Skip action must publish its authored canvas rectangle");
    await clickAuthored(skipRect.x + skipRect.width / 2, skipRect.y + skipRect.height / 2);
    await waitForState("snapshot => snapshot.first_clutch?.dismissed === true && snapshot.first_clutch?.visible === false");
    await waitForState("snapshot => snapshot.checkpoint?.last_saved_reason === 'first_clutch_skipped'", 15_000);
  }
  await page.keyboard.press("Escape");
  await page.keyboard.press("Digit3");
  await waitForState("snapshot => snapshot.clock_speed_index === 3");

  const baseline = await health("day-1-running-baseline");
  const cameraProbe = await probeCamera();
  await page.keyboard.press("Digit3");
  frameSamples.push(await sampleFrames("day-1-active-production"));

  while (true) {
    assert.ok(Date.now() - startedAt < maxWallMsec, `active progression exceeded ${maxWallMsec}ms`);
    const snapshot = await state();
    recordTransition(snapshot);

    if (
      snapshot.campaign_day >= shifts + 1
      && (
        (fullProbation && snapshot.campaign_stage === "final")
        || (!fullProbation && snapshot.campaign_stage === "active" && snapshot.shift_phase === 1)
      )
    ) {
      break;
    }

    if (snapshot.pending_decision_kind) {
      const decisionReceipt = await resolveVisibleDecision();
      decisions.push({
        campaignDay: snapshot.campaign_day,
        campaignStage: snapshot.campaign_stage,
        ...decisionReceipt,
      });
      const afterDecision = await state();
      if (afterDecision.campaign_stage === "active" && afterDecision.shift_phase === 1) {
        await page.keyboard.press("Digit3");
      }
      continue;
    }

    if (snapshot.campaign_stage === "farmer") {
      const evidence = snapshot.farmer_relations_gallery?.source_digest ?? {};
      const completedDay = Number(evidence.day ?? snapshot.campaign_day - 1);
      assert.ok(evidence.eggs > 0, `day ${completedDay} must close with seated-worker production`);
      assert.ok(evidence.quota > 0, `day ${completedDay} must retain a positive clutch target`);
      shiftsCompleted.push({
        completedDay,
        nextCampaignDay: snapshot.campaign_day,
        eggs: evidence.eggs,
        sound: evidence.sound,
        cracked: evidence.cracked,
        golden: evidence.golden,
        metQuota: evidence.met_quota,
        quota: evidence.quota,
        score: snapshot.campaign_score,
        tickRevision: snapshot.performance?.authoritative_tick_revision,
        fundCents: snapshot.economy?.feed_fund_cents,
      });
      // Let the authored review scale/fade settle before visual evidence. On
      // SwiftShader one rendered frame can exceed the 300 ms tween duration.
      await page.waitForTimeout(1_200);
      await page.screenshot({
        path: path.join(outputDirectory, `day-${completedDay}-farmer-review.png`),
        fullPage: true,
      });
      await clickAuthored(835, 390);
      await waitForState("snapshot => snapshot.campaign_stage !== 'farmer'", 15_000);
      continue;
    }

    if (snapshot.campaign_stage === "probation") {
      // Digit 1 is inert when no milestone is due and selects the first disclosed
      // permanent edge when the day-two report requires one. Continue is the
      // shipped keyboard shortcut for both report forms.
      await page.keyboard.press("Digit1");
      await page.keyboard.press("KeyC");
      await page.waitForTimeout(350);
      continue;
    }

    if (snapshot.campaign_stage === "contract_board") {
      await page.keyboard.press("KeyD");
      await waitForState("snapshot => snapshot.contract_planning?.decline_pending === false && snapshot.contract_planning?.continue_enabled === true", 15_000);
      await page.keyboard.press("KeyC");
      await page.waitForTimeout(350);
      continue;
    }

    if (snapshot.campaign_stage === "active" && snapshot.shift_phase === 1) {
      if (snapshot.clock_speed_index !== 3) await page.keyboard.press("Digit3");
      if (!frameSamples.some((sample) => sample.label === `day-${snapshot.campaign_day}-active-production`)) {
        frameSamples.push(await sampleFrames(`day-${snapshot.campaign_day}-active-production`));
      }
    }
    await page.waitForTimeout(250);
  }

  assert.equal(shiftsCompleted.length, shifts, "the gate must observe every requested farmer review");
  for (let index = 1; index < shiftsCompleted.length; index += 1) {
    assert.ok(
      shiftsCompleted[index].tickRevision > shiftsCompleted[index - 1].tickRevision,
      "authoritative simulation revisions must advance across shifts",
    );
  }
  assert.ok(decisions.some((decision) => decision.kind === "incident"), "timed management incidents must be exercised");
  assert.ok(decisions.some((decision) => ["credit_allocation", "major_event"].includes(decision.kind)), "closing credit must be exercised");

  const terminal = await state();
  if (fullProbation) {
    assert.equal(terminal.campaign_stage, "final", "a complete probation gate must settle on the authored final review");
    assert.equal(terminal.probation_safeguards?.completed_shifts, 5, "the final review must contain all five filed shifts");
    assert.equal(terminal.probation_safeguards?.is_final, true, "the safeguard receipt must be final rather than a forecast");
  } else {
    assert.equal(terminal.campaign_stage, "active", "a partial progression gate must settle on the next active shift");
  }
  const probationFinalHealth = fullProbation ? await health("five-shift-probation-final") : null;

  let seniorHandoff = null;
  let seniorHandoffHealth = null;
  let seniorQuarterBaseline = null;
  let seniorQuarterReview = null;
  const seniorQuarterReviews = [];
  let seniorAnnualReview = null;
  let seniorYearTwoGate = null;
  if (enterSeniorRoost) {
    assert.equal(fullProbation, true, "Senior Roost entry requires a complete five-shift probation file");
    assert.equal(terminal.probation_safeguards?.all_pass, true, "the audited strategy must fairly earn Senior Roost entry");
    await page.screenshot({
      path: path.join(outputDirectory, "passing-probation-outcome.png"),
      fullPage: true,
    });
    await page.keyboard.press("KeyC");
    await waitForState("snapshot => snapshot.campaign_stage === 'senior_quarter' && snapshot.senior_roost?.requires_annual_mandate === true", 30_000);
    const annualMandate = await state();
    await page.screenshot({
      path: path.join(outputDirectory, "senior-annual-mandate.png"),
      fullPage: true,
    });
		const yearOneOffers = annualMandate.senior_roost?.annual_mandate_offers ?? [];
		const yearOneOfferIndex = yearOneOffers.findIndex((offer) => offer.id === yearOneMandateId);
		assert.ok(yearOneOfferIndex >= 0, `Year 1 must offer requested Board Book ${yearOneMandateId}`);
		assert.equal(yearOneOffers[yearOneOfferIndex]?.available, true, "requested Year 1 Book must be available");
		await page.keyboard.press(`Digit${yearOneOfferIndex + 1}`);
    await waitForState("snapshot => snapshot.senior_roost?.requires_annual_mandate === false && snapshot.senior_roost?.requires_policy === true", 20_000);
    const quarterPolicy = await state();
    await page.screenshot({
      path: path.join(outputDirectory, "senior-quarter-policy.png"),
      fullPage: true,
    });
    await page.keyboard.press(`Digit${seniorPolicyDigits[seniorPolicySequence[0]]}`);
    await waitForState("snapshot => snapshot.senior_roost?.status === 'active' && snapshot.senior_roost?.active_policy_id !== ''", 20_000);
    const ready = await state();
    await page.screenshot({
      path: path.join(outputDirectory, "senior-first-quarter-ready.png"),
      fullPage: true,
    });
    seniorHandoff = {
      entryStage: annualMandate.campaign_stage,
      annualMandateOffers: annualMandate.senior_roost?.annual_mandate_offers?.length ?? 0,
      selectedMandateId: quarterPolicy.senior_roost?.active_annual_mandate?.id ?? "",
      selectedPolicyId: ready.senior_roost?.active_policy_id ?? "",
      year: ready.senior_roost?.year,
      quarter: ready.senior_roost?.quarter,
      status: ready.senior_roost?.status,
      policyOffers: quarterPolicy.senior_roost?.quarterly_policy_offers ?? [],
    };
    assert.equal(seniorHandoff.annualMandateOffers, 3, "Senior Roost must disclose all three annual mandate books");
		assert.equal(seniorHandoff.selectedMandateId, yearOneMandateId, "the requested Year 1 Board Book must file authoritatively");
    assert.equal(seniorHandoff.selectedPolicyId, seniorPolicySequence[0], "the requested first-quarter policy must file authoritatively");
    assert.equal(seniorHandoff.policyOffers.length, 3, "Senior planning must expose all three quarterly policies");
    for (const offer of seniorHandoff.policyOffers) {
      assert.notEqual(offer.strategy?.score_edge ?? "", "", `${offer.id} must disclose its score edge`);
      assert.notEqual(offer.strategy?.score_watch ?? "", "", `${offer.id} must disclose its score watch`);
      assert.notEqual(offer.strategy?.board_fit ?? "", "", `${offer.id} must disclose its active-board fit`);
    }

    seniorHandoffHealth = await health("senior-first-quarter-ready");
    if (seniorShifts > 0) {
      seniorQuarterBaseline = seniorHandoffHealth;
      while (true) {
        assert.ok(Date.now() - startedAt < maxWallMsec, `Senior quarter exceeded ${maxWallMsec}ms`);
        const snapshot = await state();
        recordTransition(snapshot);
        const senior = snapshot.senior_roost ?? {};
        const filedShifts = Number(senior.total_senior_shifts ?? 0);
        const completedQuarters = Number(senior.completed_quarters ?? 0);
        if (
          completedQuarters > seniorQuarterReviews.length
          && ["senior_quarter", "senior_annual"].includes(snapshot.campaign_stage)
        ) {
          const review = senior.last_quarter_review ?? {};
          assert.equal(Number(review.shift_count ?? 0), 3, `Senior quarter ${completedQuarters} must file three shifts`);
          const filedScore = Number(review.score ?? -1);
          const filedMarks = Number(review.marks_awarded ?? -1);
          const expectedMarks = filedScore >= 80 ? 3 : filedScore >= 60 ? 2 : filedScore >= 40 ? 1 : 0;
          assert.equal(filedMarks, expectedMarks, `Senior quarter ${completedQuarters} must apply the canonical mark tiers`);
          await page.waitForTimeout(1_200);
          const quarterHealth = await health(`senior-quarter-${completedQuarters}-review`);
          seniorQuarterReviews.push({
            completedQuarter: completedQuarters,
            year: Number(review.year ?? senior.year ?? 0),
            quarter: Number(review.quarter_in_year ?? senior.quarter ?? 0),
            review,
            health: quarterHealth,
          });
          await page.screenshot({
            path: path.join(outputDirectory, `senior-quarter-${completedQuarters}-review.png`),
            fullPage: true,
          });
        }
        const targetQuarters = Math.floor(seniorShifts / 3);
        const closesOnAnnualReview = seniorShifts % 12 === 0;
        const targetReached = filedShifts >= seniorShifts && (
          closesOnAnnualReview
            ? Number(senior.completed_years ?? 0) >= seniorShifts / 12
              && senior.status === "annual_review"
              && snapshot.campaign_stage === "senior_annual"
            : seniorShifts % 3 === 0
              ? completedQuarters >= targetQuarters
                && senior.status === "quarter_choice"
                && snapshot.campaign_stage === "senior_quarter"
              : snapshot.campaign_stage === "senior_quarter"
        );
        if (targetReached) {
          seniorQuarterReview = snapshot;
          if (senior.status === "annual_review") {
            seniorAnnualReview = senior.last_annual_review ?? null;
            await page.waitForTimeout(1_200);
            await page.screenshot({
              path: path.join(outputDirectory, "senior-annual-review.png"),
              fullPage: true,
            });
          }
          break;
        }

		if (
			continueYearTwo
			&& seniorShifts > 12
			&& snapshot.campaign_stage === "senior_annual"
			&& senior.status === "annual_review"
			&& Number(senior.completed_years ?? 0) === 1
		) {
			seniorAnnualReview = senior.last_annual_review ?? null;
			assert.ok(seniorAnnualReview, "Year 2 continuation requires the authoritative Year 1 annual receipt");
			assert.equal(seniorAnnualReview.mandate_settlement?.mandate_id, yearOneMandateId, "Year 2 continuation must preserve the requested Year 1 Book receipt");
			assert.ok(
				Number(seniorAnnualReview.mandate_settlement?.mandate_seals_after ?? 0) >= 1,
				"the audited Year 1 route must fulfill its Board Book before continuing into advanced recovery play",
			);
			await page.waitForTimeout(1_200);
			await page.screenshot({
				path: path.join(outputDirectory, "senior-annual-review.png"),
				fullPage: true,
			});
			await page.keyboard.press("KeyC");
			await waitForState("snapshot => snapshot.campaign_stage === 'senior_quarter' && snapshot.senior_roost?.year === 2 && snapshot.senior_roost?.requires_annual_mandate === true", 30_000);
			await page.waitForTimeout(1_200);
			const yearTwo = await state();
			const offers = yearTwo.senior_roost?.annual_mandate_offers ?? [];
			const advancedOfferIndex = offers.findIndex((offer) => (
				Number(offer.tier ?? 0) === 1
				&& (yearTwoMandateId === "" || offer.id === yearTwoMandateId)
			));
			assert.equal(offers.length, 3, "Year 2 planning must retain exactly three frozen Board Books");
			assert.ok(advancedOfferIndex >= 0, yearTwoMandateId
				? `mastery-aware Year 2 planning must expose requested ${yearTwoMandateId}`
				: "the first earned Board Seal must expose a tier-one advanced Book");
			const advancedOffer = offers[advancedOfferIndex];
			seniorYearTwoGate = {
				year: yearTwo.senior_roost?.year,
				completedYears: yearTwo.senior_roost?.completed_years,
				mandateSeals: yearTwo.senior_roost?.mandate_seals,
				eligibleTier: yearTwo.senior_roost?.eligible_mandate_tier,
				availableMarks: yearTwo.senior_roost?.available_roost_marks,
				offers,
				selectedMode: yearTwoMandateMode,
			};
			await page.screenshot({
				path: path.join(outputDirectory, "senior-year-2-advanced-mandate.png"),
				fullPage: true,
			});

			if (yearTwoMandateMode === "advanced") {
				assert.equal(advancedOffer.available, true, "the naturally earned Year 1 marks must make the tier-one Book affordable");
				const availableBefore = Number(yearTwo.senior_roost?.available_roost_marks ?? 0);
				const stake = Number(advancedOffer.stake_marks ?? 0);
				assert.equal(stake, 2, "the first advanced Board Book must disclose its canonical two-mark stake");
				await page.keyboard.press(`Digit${advancedOfferIndex + 1}`);
				await waitForState(`snapshot => snapshot.senior_roost?.pending_mandate_confirmation?.id === '${advancedOffer.id}'`, 20_000);
				const pending = await state();
				assert.equal(pending.senior_roost?.requires_annual_mandate, true, "inspecting an advanced Book must preserve the annual gate");
				assert.equal(pending.senior_roost?.active_annual_mandate?.id ?? "", "", "inspection must not mutate the authoritative mandate");
				assert.equal(Number(pending.senior_roost?.available_roost_marks ?? -1), availableBefore, "inspection must not reserve marks early");
				await page.waitForTimeout(600);
				await page.screenshot({
					path: path.join(outputDirectory, "senior-year-2-advanced-stake-confirmation.png"),
					fullPage: true,
				});
				await page.keyboard.press("KeyC");
				await waitForState(`snapshot => snapshot.senior_roost?.active_annual_mandate?.id === '${advancedOffer.id}' && snapshot.senior_roost?.requires_policy === true`, 20_000);
				const filed = await state();
				assert.equal(Number(filed.senior_roost?.mandate_stake_reserved ?? -1), stake, "confirmation must reserve the exact advanced stake once");
				assert.equal(Number(filed.senior_roost?.available_roost_marks ?? -1), availableBefore - stake, "only confirmation may remove the stake from available marks");
				seniorYearTwoGate.pendingConfirmation = pending.senior_roost?.pending_mandate_confirmation;
				seniorYearTwoGate.filedMandate = filed.senior_roost?.active_annual_mandate;
			} else {
				await page.keyboard.press("Digit1");
				await waitForState("snapshot => snapshot.senior_roost?.requires_annual_mandate === false && snapshot.senior_roost?.requires_policy === true", 20_000);
			}
			await page.waitForTimeout(600);
			await page.screenshot({
				path: path.join(outputDirectory, "senior-year-2-mandate-filed.png"),
				fullPage: true,
			});
			continue;
		}

        if (
          snapshot.campaign_stage === "senior_quarter"
          && senior.status === "quarter_choice"
          && senior.requires_policy === true
          && completedQuarters < Math.ceil(seniorShifts / 3)
        ) {
          const nextPolicyId = seniorPolicySequence[completedQuarters];
          assert.ok(nextPolicyId, `Senior quarter ${completedQuarters + 1} requires an audited policy`);
          await page.screenshot({
            path: path.join(outputDirectory, `senior-quarter-${completedQuarters + 1}-policy.png`),
            fullPage: true,
          });
          await page.keyboard.press(`Digit${seniorPolicyDigits[nextPolicyId]}`);
          await waitForState("snapshot => snapshot.senior_roost?.status === 'active' && snapshot.senior_roost?.active_policy_id !== ''", 20_000);
          continue;
        }

        if (snapshot.pending_decision_kind) {
          const decisionReceipt = await resolveVisibleDecision();
          decisions.push({
            campaignDay: snapshot.campaign_day,
            campaignStage: snapshot.campaign_stage,
            seniorYear: senior.year,
            seniorQuarter: senior.quarter,
            ...decisionReceipt,
          });
          const afterDecision = await state();
          if (afterDecision.campaign_stage === "active" && afterDecision.shift_phase === 1) {
            await page.keyboard.press("Digit3");
          }
          continue;
        }

        if (snapshot.campaign_stage === "farmer") {
          const evidence = snapshot.farmer_relations_gallery?.source_digest ?? {};
          const seniorShiftNumber = filedShifts;
          assert.ok(seniorShiftNumber >= 1, "a Senior farmer review must follow an authoritative filed shift");
          assert.ok(evidence.eggs > 0, `Senior shift ${seniorShiftNumber} must close with seated-worker production`);
          seniorShiftsCompleted.push({
            seniorShiftNumber,
            day: evidence.day,
            eggs: evidence.eggs,
            sound: evidence.sound,
            cracked: evidence.cracked,
            golden: evidence.golden,
            metQuota: evidence.met_quota,
            quota: evidence.quota,
            tickRevision: snapshot.performance?.authoritative_tick_revision,
            fundCents: snapshot.economy?.feed_fund_cents,
          });
          await page.waitForTimeout(1_200);
          await page.screenshot({
            path: path.join(outputDirectory, `senior-shift-${seniorShiftNumber}-farmer-review.png`),
            fullPage: true,
          });
          await clickAuthored(835, 390);
          await waitForState("snapshot => snapshot.campaign_stage !== 'farmer'", 20_000);
          continue;
        }

        if (snapshot.campaign_stage === "contract_board") {
          if (snapshot.contract_planning?.continue_enabled !== true) {
            assert.equal(snapshot.contract_planning?.decline_visible, true, "Senior planning must preserve the explicit Standard Book fallback");
            await page.keyboard.press("KeyD");
            await waitForState("snapshot => snapshot.contract_planning?.decline_pending === false && snapshot.contract_planning?.continue_enabled === true", 20_000);
          }
          await page.keyboard.press("KeyC");
          await page.waitForTimeout(350);
          continue;
        }

        if (snapshot.campaign_stage === "senior_quarter" && senior.status === "active") {
          await page.keyboard.press("KeyC");
          await page.waitForTimeout(350);
          continue;
        }

        if (snapshot.campaign_stage === "active" && snapshot.shift_phase === 1) {
          if (snapshot.clock_speed_index !== 3) await page.keyboard.press("Digit3");
        }
        await page.waitForTimeout(250);
      }

      assert.equal(seniorShiftsCompleted.length, seniorShifts, "the gate must observe each requested Senior farmer review");
      if (seniorShifts % 3 === 0) {
        assert.equal(seniorQuarterReviews.length, seniorShifts / 3, "every requested Senior quarter must close authoritatively");
        for (const [index, quarter] of seniorQuarterReviews.entries()) {
          assert.equal(quarter.review?.policy_id, seniorPolicySequence[index], `Senior quarter ${index + 1} must preserve its requested policy receipt`);
        }
        await page.waitForTimeout(1_200);
        await page.screenshot({
          path: path.join(outputDirectory, seniorShifts === 12 ? "senior-year-review.png" : "senior-quarter-review.png"),
          fullPage: true,
        });
      }
      if (seniorShifts === 12) {
        assert.equal(seniorQuarterReview?.senior_roost?.completed_years, 1, "twelve Senior shifts must close Year 1");
        assert.equal(seniorQuarterReview?.senior_roost?.status, "annual_review", "Year 1 must settle on the authored annual review");
        assert.ok(seniorAnnualReview, "Year 1 must expose an annual review receipt");
        assert.equal(seniorAnnualReview.mandate_settlement?.year, 1, "the annual mandate must settle with Year 1");
				assert.equal(seniorAnnualReview.mandate_settlement?.mandate_id, yearOneMandateId, "the annual receipt must retain the requested Year 1 Book");
      }
      if (seniorShifts === 24 && yearTwoMandateMode === "advanced") {
        assert.ok(seniorAnnualReview, "twenty-four Senior shifts must expose the Year 2 annual receipt");
        const settlement = seniorAnnualReview.mandate_settlement ?? {};
        assert.equal(settlement.year, 2, "the advanced Board Book must settle with Year 2");
				assert.equal(settlement.mandate_id, yearTwoMandateId || seniorYearTwoGate?.filedMandate?.id, "the advanced settlement must retain the explicitly filed Book");
        assert.equal(settlement.stake_marks, 2, "the authentic advanced settlement must retain its two-mark stake");
        if (expectedAdvancedOutcome === "success") {
          assert.equal(settlement.success, true, "the authored executive strategy must return its advanced stake");
          assert.equal(settlement.stake_returned, 2, "successful advanced settlement must return both marks");
          assert.equal(settlement.stake_forfeited, 0, "successful advanced settlement must forfeit no marks");
        } else if (expectedAdvancedOutcome === "failure") {
          assert.equal(settlement.success, false, "the control strategy must fail the advanced Book authentically");
          assert.equal(settlement.stake_returned, 0, "failed advanced settlement must return no marks");
          assert.equal(settlement.stake_forfeited, 2, "failed advanced settlement must permanently spend both marks");
        }
      }
    }
  }

	if (continueYearTwo && seniorShifts === 12) {
		assert.ok(seniorAnnualReview, "Year 2 continuation requires the authoritative Year 1 annual receipt");
		assert.ok(
			Number(seniorAnnualReview.mandate_settlement?.mandate_seals_after ?? 0) >= 1,
			"the audited Year 1 route must fulfill its Board Book before testing advanced eligibility",
		);
		await page.keyboard.press("KeyC");
		await waitForState("snapshot => snapshot.campaign_stage === 'senior_quarter' && snapshot.senior_roost?.year === 2 && snapshot.senior_roost?.requires_annual_mandate === true", 30_000);
		await page.waitForTimeout(1_200);
		const yearTwo = await state();
		const offers = yearTwo.senior_roost?.annual_mandate_offers ?? [];
		const advancedOffers = offers.filter((offer) => Number(offer.tier ?? 0) === 1);
		assert.equal(offers.length, 3, "Year 2 planning must retain exactly three frozen Board Books");
		assert.ok(advancedOffers.length >= 1, "the first earned Board Seal must expose a tier-one advanced Book");
		if (yearTwoMandateId !== "") {
			assert.ok(advancedOffers.some((offer) => offer.id === yearTwoMandateId), `Year 2 planning must expose requested ${yearTwoMandateId}`);
		}
		seniorYearTwoGate = {
			year: yearTwo.senior_roost?.year,
			completedYears: yearTwo.senior_roost?.completed_years,
			mandateSeals: yearTwo.senior_roost?.mandate_seals,
			eligibleTier: yearTwo.senior_roost?.eligible_mandate_tier,
			availableMarks: yearTwo.senior_roost?.available_roost_marks,
			offers,
		};
		await page.screenshot({
			path: path.join(outputDirectory, "senior-year-2-advanced-mandate.png"),
			fullPage: true,
		});
	}

  await requestCheckpoint("active_progression_final");
  const final = await health(
		seniorShifts > 12
			? `senior-year-two-${seniorShifts - 12}-shifts-reviewed`
			: continueYearTwo
			? "senior-year-two-advanced-mandate"
			: seniorShifts === 12
      ? "senior-first-year-reviewed"
      : seniorShifts === 3
        ? "senior-first-quarter-reviewed"
      : enterSeniorRoost
        ? "senior-first-quarter-ready"
      : fullProbation
        ? "five-shift-probation-final"
        : `day-${shifts + 1}-running-final`,
  );
  await page.screenshot({
    path: path.join(
      outputDirectory,
			seniorShifts > 12
				? "final-senior-year-2-recovery-progress.png"
				: continueYearTwo
				? "final-senior-year-2-advanced-mandate.png"
				: seniorShifts === 12
        ? "final-senior-year-review.png"
        : seniorShifts === 3
          ? "final-senior-quarter-review.png"
        : enterSeniorRoost
          ? "final-senior-handoff.png"
        : fullProbation
          ? "final-probation-outcome.png"
          : "final-next-shift-running.png",
    ),
    fullPage: true,
  });

  const growth = {
    nativeStaticMemoryBytes: final.native.staticMemoryBytes - baseline.native.staticMemoryBytes,
    wasmMemoryBytes: final.webAssembly.wasmMemoryBytes - baseline.webAssembly.wasmMemoryBytes,
    jsHeapUsedBytes: final.chromium.jsHeapUsedBytes - baseline.chromium.jsHeapUsedBytes,
    nativeObjectCount: final.native.objectCount - baseline.native.objectCount,
    nativeNodeCount: final.native.nodeCount - baseline.native.nodeCount,
    nativeOrphanNodeCount: final.native.orphanNodeCount - baseline.native.orphanNodeCount,
    chromiumNodes: final.chromium.nodes - baseline.chromium.nodes,
    chromiumDocuments: final.chromium.documents - baseline.chromium.documents,
    chromiumEventListeners: final.chromium.eventListeners - baseline.chromium.eventListeners,
  };
  const seniorTransitionGrowth = probationFinalHealth && seniorHandoffHealth ? {
    nativeObjectCount: seniorHandoffHealth.native.objectCount - probationFinalHealth.native.objectCount,
    nativeNodeCount: seniorHandoffHealth.native.nodeCount - probationFinalHealth.native.nodeCount,
    nativeOrphanNodeCount: seniorHandoffHealth.native.orphanNodeCount - probationFinalHealth.native.orphanNodeCount,
    wasmMemoryBytes: seniorHandoffHealth.webAssembly.wasmMemoryBytes - probationFinalHealth.webAssembly.wasmMemoryBytes,
    jsHeapUsedBytes: seniorHandoffHealth.chromium.jsHeapUsedBytes - probationFinalHealth.chromium.jsHeapUsedBytes,
  } : null;
  const probationGrowth = probationFinalHealth ? {
    nativeObjectCount: probationFinalHealth.native.objectCount - baseline.native.objectCount,
    nativeNodeCount: probationFinalHealth.native.nodeCount - baseline.native.nodeCount,
    nativeOrphanNodeCount: probationFinalHealth.native.orphanNodeCount - baseline.native.orphanNodeCount,
    wasmMemoryBytes: probationFinalHealth.webAssembly.wasmMemoryBytes - baseline.webAssembly.wasmMemoryBytes,
    jsHeapUsedBytes: probationFinalHealth.chromium.jsHeapUsedBytes - baseline.chromium.jsHeapUsedBytes,
  } : null;
  const seniorQuarterGrowth = seniorQuarterBaseline ? {
    nativeObjectCount: final.native.objectCount - seniorQuarterBaseline.native.objectCount,
    nativeNodeCount: final.native.nodeCount - seniorQuarterBaseline.native.nodeCount,
    nativeOrphanNodeCount: final.native.orphanNodeCount - seniorQuarterBaseline.native.orphanNodeCount,
    wasmMemoryBytes: final.webAssembly.wasmMemoryBytes - seniorQuarterBaseline.webAssembly.wasmMemoryBytes,
    jsHeapUsedBytes: final.chromium.jsHeapUsedBytes - seniorQuarterBaseline.chromium.jsHeapUsedBytes,
  } : null;
  const auditFailures = [];
  if (growth.nativeStaticMemoryBytes > maxNativeGrowthBytes) auditFailures.push(`native memory grew ${growth.nativeStaticMemoryBytes} bytes`);
  if (baseline.webAssembly.wasmMemoryBytes <= 0) auditFailures.push("the wrapper did not expose the WebAssembly heap");
  if (growth.wasmMemoryBytes > maxWasmGrowthBytes) auditFailures.push(`WebAssembly heap grew ${growth.wasmMemoryBytes} bytes`);
  if (growth.jsHeapUsedBytes > maxJsGrowthBytes) auditFailures.push(`JS heap grew ${growth.jsHeapUsedBytes} bytes`);
  if (growth.nativeObjectCount > maxObjectGrowth) auditFailures.push(`Godot object count grew ${growth.nativeObjectCount}`);
  if (growth.nativeNodeCount > maxNodeGrowth) auditFailures.push(`Godot node count grew ${growth.nativeNodeCount}`);
  if (growth.nativeOrphanNodeCount > maxOrphanGrowth) auditFailures.push(`Godot orphan-node count grew ${growth.nativeOrphanNodeCount}`);
  if (probationGrowth?.nativeObjectCount > maxProbationObjectGrowth) auditFailures.push(`probation added ${probationGrowth.nativeObjectCount} Godot objects`);
  if (probationGrowth?.nativeNodeCount > maxProbationNodeGrowth) auditFailures.push(`probation added ${probationGrowth.nativeNodeCount} Godot nodes`);
  if (probationGrowth?.nativeOrphanNodeCount > 0) auditFailures.push(`probation added ${probationGrowth.nativeOrphanNodeCount} orphan nodes`);
  if (probationGrowth?.wasmMemoryBytes > maxProbationWasmGrowthBytes) auditFailures.push(`probation WebAssembly heap grew ${probationGrowth.wasmMemoryBytes} bytes`);
  if (seniorTransitionGrowth?.nativeObjectCount > maxSeniorObjectGrowth) auditFailures.push(`Senior handoff added ${seniorTransitionGrowth.nativeObjectCount} Godot objects`);
  if (seniorTransitionGrowth?.nativeNodeCount > maxSeniorNodeGrowth) auditFailures.push(`Senior handoff added ${seniorTransitionGrowth.nativeNodeCount} Godot nodes`);
  if (seniorTransitionGrowth?.nativeOrphanNodeCount > 0) auditFailures.push(`Senior handoff added ${seniorTransitionGrowth.nativeOrphanNodeCount} orphan nodes`);
  if (seniorQuarterGrowth?.nativeObjectCount > maxSeniorQuarterObjectGrowth) auditFailures.push(`Senior quarter added ${seniorQuarterGrowth.nativeObjectCount} Godot objects`);
  if (seniorQuarterGrowth?.nativeNodeCount > maxSeniorQuarterNodeGrowth) auditFailures.push(`Senior quarter added ${seniorQuarterGrowth.nativeNodeCount} Godot nodes`);
  if (seniorQuarterGrowth?.nativeOrphanNodeCount > 0) auditFailures.push(`Senior quarter added ${seniorQuarterGrowth.nativeOrphanNodeCount} orphan nodes`);
  if (seniorQuarterGrowth?.wasmMemoryBytes > maxSeniorQuarterWasmGrowthBytes) auditFailures.push(`Senior quarter WebAssembly heap grew ${seniorQuarterGrowth.wasmMemoryBytes} bytes`);
  if (growth.chromiumDocuments !== 0) auditFailures.push(`Chromium document count grew ${growth.chromiumDocuments}`);
  if (growth.chromiumEventListeners > maxBrowserEventListenerGrowth) auditFailures.push(`Chromium event listeners grew ${growth.chromiumEventListeners}`);
  if (cameraProbe.responseMsec > maxInputResponseMsec) auditFailures.push(`camera input took ${cameraProbe.responseMsec}ms`);
  for (const sample of frameSamples) {
    if (sample.frames < 2 || sample.worstFrameMsec > maxInputResponseMsec) {
      auditFailures.push(`${sample.label} stopped producing responsive animation frames`);
    }
  }
  auditFailures.push(...browserErrors);

  const longTasks = await page.evaluate(() => window.__peckingProgressionLongTasks ?? []);
  const report = {
    passed: auditFailures.length === 0,
    url,
    renderer: auditRenderer === "hardware"
			? "headless Chromium / ANGLE D3D11; authentic progression and functional responsiveness are gated; cross-device throughput is not claimed"
			: "headless Chromium / ANGLE SwiftShader; progression, responsiveness, and bounded growth are gated; physical GPU throughput is not claimed",
    elapsedMsec: Date.now() - startedAt,
    configuration: {
      shifts,
      challengeContractId,
      strategyId,
      yearTwoStrategyId,
		auditRenderer,
      seniorPolicyId,
      seniorPolicySequence,
      enterSeniorRoost,
      seniorShifts,
			continueYearTwo,
			yearOneMandateId,
			yearTwoMandateMode,
			yearTwoMandateId,
			expectedAdvancedOutcome,
      maxWallMsec,
      maxNativeGrowthBytes,
      maxWasmGrowthBytes,
      maxJsGrowthBytes,
      maxObjectGrowth,
      maxNodeGrowth,
      maxOrphanGrowth,
      maxInputResponseMsec,
      maxProbationObjectGrowth,
      maxProbationNodeGrowth,
      maxProbationWasmGrowthBytes,
      maxSeniorObjectGrowth,
      maxSeniorNodeGrowth,
      maxSeniorQuarterObjectGrowth,
      maxSeniorQuarterNodeGrowth,
      maxSeniorQuarterWasmGrowthBytes,
      maxBrowserEventListenerGrowth,
    },
    shiftsCompleted,
    seniorShiftsCompleted,
    decisions,
    stageTransitions,
    probationOutcome: fullProbation ? {
      passed: terminal.probation_safeguards?.all_pass === true,
      score: terminal.campaign_score,
      passCount: terminal.probation_safeguards?.pass_count,
      criteriaCount: terminal.probation_safeguards?.criteria_count,
      criteria: terminal.probation_safeguards?.criteria ?? [],
    } : null,
    seniorHandoff,
    seniorQuarterReview: seniorQuarterReview ? {
      status: seniorQuarterReview.senior_roost?.status,
      year: seniorQuarterReview.senior_roost?.year,
      quarter: seniorQuarterReview.senior_roost?.quarter,
      completedQuarters: seniorQuarterReview.senior_roost?.completed_quarters,
      review: seniorQuarterReview.senior_roost?.last_quarter_review,
    } : null,
    seniorQuarterReviews,
    seniorAnnualReview,
		seniorYearTwoGate,
    cameraProbe,
    frameSamples,
    baseline,
    probationFinalHealth,
    final,
    growth,
    probationGrowth,
    seniorTransitionGrowth,
    seniorQuarterGrowth,
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
} catch (error) {
  const failureState = await state().catch(() => ({}));
  fs.writeFileSync(path.join(outputDirectory, "failure-report.json"), JSON.stringify({
    error: String(error),
    elapsedMsec: Date.now() - startedAt,
    challengeContractId,
    strategyId,
    yearTwoStrategyId,
		auditRenderer,
    seniorPolicyId,
    seniorPolicySequence,
    enterSeniorRoost,
    seniorShifts,
		continueYearTwo,
		yearOneMandateId,
		yearTwoMandateMode,
		yearTwoMandateId,
		expectedAdvancedOutcome,
    shiftsCompleted,
    seniorShiftsCompleted,
    decisions,
    stageTransitions,
    browserErrors,
  }, null, 2));
  fs.writeFileSync(path.join(outputDirectory, "failure-state.json"), JSON.stringify(failureState, null, 2));
  await page.screenshot({
    path: path.join(outputDirectory, "failure.png"),
    fullPage: true,
  }).catch(() => {});
  throw error;
} finally {
  await browser.close();
}
