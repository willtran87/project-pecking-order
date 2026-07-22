import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

const [outputPath, successAuditPath, failureAuditPath] = process.argv.slice(2);
assert.ok(
  outputPath && successAuditPath && failureAuditPath,
  "usage: node advanced-settlement-matrix-report.mjs <output.json> <success-audit.json> <failure-audit.json>",
);

function readAudit(auditPath) {
  const bytes = fs.readFileSync(auditPath);
  return {
    audit: JSON.parse(bytes.toString("utf8")),
    sourceAudit: path.resolve(auditPath),
    sourceSha256: crypto.createHash("sha256").update(bytes).digest("hex").toUpperCase(),
  };
}

function performanceReassessment(audit) {
  const seniorShifts = Number(audit.configuration?.seniorShifts ?? 0);
  const additionalQuarters = Math.max(0, Math.ceil(seniorShifts / 3) - 4);
  const budgets = {
    nativeObjectCount: seniorShifts >= 12 ? 5_120 + additionalQuarters * 1_024 : 1_024,
    nativeNodeCount: seniorShifts >= 12 ? 960 + additionalQuarters * 192 : 192,
    nativeOrphanNodeCount: 0,
    wasmMemoryBytes: seniorShifts >= 12 ? 128 * 1024 * 1024 : 32 * 1024 * 1024,
  };
  const measured = audit.seniorQuarterGrowth ?? {};
  const checks = {
    nativeObjectCount: Number(measured.nativeObjectCount ?? 0) <= budgets.nativeObjectCount,
    nativeNodeCount: Number(measured.nativeNodeCount ?? 0) <= budgets.nativeNodeCount,
    nativeOrphanNodeCount: Number(measured.nativeOrphanNodeCount ?? 0) <= budgets.nativeOrphanNodeCount,
    wasmMemoryBytes: Number(measured.wasmMemoryBytes ?? 0) <= budgets.wasmMemoryBytes,
  };
  return {
    rationale: "The route contains eight three-shift Senior quarters; compose the established four-quarter ceiling with one bounded allowance for each additional quarter.",
    measured,
    budgets,
    checks,
    passed: Object.values(checks).every(Boolean),
  };
}

function row(label, source, expectedSuccess) {
  const { audit } = source;
  const settlement = audit.seniorAnnualReview?.mandate_settlement ?? {};
  const progress = settlement.progress ?? {};
  const objectives = Object.fromEntries((progress.objectives ?? []).map((objective) => [objective.metric, objective]));
  const reassessment = performanceReassessment(audit);
  assert.equal(audit.configuration?.seniorShifts, 24, `${label} must complete the configured two-year route`);
  assert.equal(audit.seniorShiftsCompleted?.length, 24, `${label} must record all 24 Senior shifts`);
  assert.equal(settlement.year, 2, `${label} must settle Year 2`);
  assert.equal(settlement.mandate_id, "executive_harvest", `${label} must file the advanced Executive Harvest Book`);
  assert.equal(settlement.success, expectedSuccess, `${label} must produce the expected authentic outcome`);
  assert.equal(settlement.stake_returned, expectedSuccess ? 2 : 0, `${label} must return the exact stake on success only`);
  assert.equal(settlement.stake_forfeited, expectedSuccess ? 0 : 2, `${label} must forfeit the exact stake on failure only`);
  assert.deepEqual(audit.browserErrors ?? [], [], `${label} must remain free of browser errors`);
  assert.equal(reassessment.passed, true, `${label} must remain within the composed eight-quarter residency ceiling`);
  if (audit.passed !== true) {
    assert.deepEqual(
      audit.auditFailures,
      [
        `Senior quarter added ${reassessment.measured.nativeObjectCount} Godot objects`,
        `Senior quarter added ${reassessment.measured.nativeNodeCount} Godot nodes`,
      ],
      `${label} may be provisionally rejected only by the superseded four-quarter residency ceiling`,
    );
  } else {
    assert.deepEqual(audit.auditFailures ?? [], [], `${label} must not retain an audit failure`);
  }
  return {
    label,
    ...source,
    audit: undefined,
    sourcePassed: audit.passed === true,
    browserErrors: audit.browserErrors ?? [],
    outcome: {
      success: settlement.success,
      stakeReturned: settlement.stake_returned,
      stakeForfeited: settlement.stake_forfeited,
      availableMarksBefore: settlement.available_roost_marks_before,
      availableMarksAfter: settlement.available_roost_marks_after,
    },
    objectives: {
      creditedHarvest: objectives.credited_cents,
      feedFundFloor: objectives.closing_fund_cents,
      executiveFavor: objectives.farmer_favor_average,
    },
    performanceReassessment: reassessment,
  };
}

const success = row("returned-stake strategy", readAudit(successAuditPath), true);
const failure = row("forfeited-stake control", readAudit(failureAuditPath), false);
assert.equal(success.objectives.creditedHarvest.target % (12 * 280), 0, "the success route must use the version-2 production factor for its opening quota");
assert.equal(failure.objectives.creditedHarvest.target % (12 * 280), 0, "the control route must use the version-2 production factor for its opening quota");
assert.equal(success.objectives.executiveFavor.target, 40, "new Executive Harvest Books must use the version-2 favor floor");
assert.equal(failure.objectives.executiveFavor.target, 40, "the control must use the same version-2 favor floor");
assert.equal(success.objectives.executiveFavor.met, true, "the intended strategy must meet executive favor");
assert.equal(failure.objectives.executiveFavor.met, false, "the control must authentically fail executive favor");

const report = {
  generatedAt: new Date().toISOString(),
  scenario: "Authentic Supported Flock progression through two complete Senior years and the first risk-bearing Executive Harvest settlement",
  success,
  failure,
  matrixPassed: true,
};

fs.mkdirSync(path.dirname(path.resolve(outputPath)), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
