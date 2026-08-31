import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";

const [outputPath, ...auditPaths] = process.argv.slice(2);
assert.ok(outputPath, "usage: node senior-policy-matrix-report.mjs <output.json> <audit.json> <audit.json> <audit.json>");
assert.equal(auditPaths.length, 3, "the Senior policy matrix requires exactly three production audits");

function scoreComponents(review) {
  const shifts = Math.max(1, Number(review.shift_count ?? 0));
  const quotaMet = Number(review.quota_met_shifts ?? 0);
  const crackRate = Number(review.crack_rate_basis_points ?? 10_000);
  const overdue = Number(review.overdue ?? 0);
  const welfare = Number(review.welfare ?? 0);
  const compliance = Number(review.compliance ?? 0);
  const favor = Number(review.farmer_favor ?? 0);
  const arrears = Number(review.closing_wage_arrears_cents ?? 0);
  return {
    quotaReliability: Math.round(30 * quotaMet / shifts),
    shellIntegrity: crackRate <= 1_500 ? 20 : crackRate <= 2_500 ? 10 : 0,
    queueControl: overdue <= 3 ? 10 : overdue <= 6 ? 5 : 0,
    flockWelfare: welfare >= 60 ? 15 : welfare >= 45 ? 8 : 0,
    coopObedience: compliance >= 70 ? 10 : compliance >= 55 ? 5 : 0,
    farmerFavor: favor >= 60 ? 10 : favor >= 50 ? 5 : 0,
    solvency: arrears === 0 ? 5 : 0,
  };
}

const rows = auditPaths.map((auditPath) => {
  const audit = JSON.parse(fs.readFileSync(auditPath, "utf8"));
  const review = audit.seniorQuarterReview?.review ?? {};
  const policyId = audit.seniorHandoff?.selectedPolicyId ?? audit.configuration?.seniorPolicyId ?? "";
  assert.ok(policyId, `${auditPath} must identify its filed Senior policy`);
  assert.equal(audit.seniorShiftsCompleted?.length, 3, `${policyId} must complete all three Senior shifts`);
  assert.equal(review.shift_count, 3, `${policyId} must close a three-shift quarter`);
  assert.deepEqual(audit.browserErrors ?? [], [], `${policyId} must remain free of browser errors`);
  return {
    policyId,
    sourceAudit: path.resolve(auditPath),
    sourcePassed: audit.passed === true,
    probation: audit.probationOutcome,
    quarter: {
      shiftCount: Number(review.shift_count ?? 0),
      score: Number(review.score ?? 0),
      marksAwarded: Number(review.marks_awarded ?? 0),
      eggs: Number(review.eggs ?? 0),
      quota: Number(review.quota ?? 0),
      quotaMetShifts: Number(review.quota_met_shifts ?? 0),
      cracked: Number(review.cracked ?? 0),
      crackRateBasisPoints: Number(review.crack_rate_basis_points ?? 0),
      overdue: Number(review.overdue ?? 0),
      welfare: Number(review.welfare ?? 0),
      compliance: Number(review.compliance ?? 0),
      farmerFavor: Number(review.farmer_favor ?? 0),
      closingFundCents: Number(review.closing_fund_cents ?? 0),
      closingWageArrearsCents: Number(review.closing_wage_arrears_cents ?? 0),
      components: scoreComponents(review),
    },
    immediateEffects: review.policy_receipt?.effects ?? {},
    seniorShifts: audit.seniorShiftsCompleted,
    auditFailures: audit.auditFailures ?? [],
  };
});

assert.deepEqual(
  [...new Set(rows.map((row) => row.policyId))].sort(),
  ["flock_dividend", "harvest_forecast", "merit_grants"],
  "the matrix must cover each quarterly policy exactly once",
);
assert.ok(rows.every((row) => row.probation?.passed === true), "every policy route must share a passing probation handoff");

const scores = rows.map((row) => row.quarter.score);
const report = {
  generatedAt: new Date().toISOString(),
  scenario: "Supported Flock / Stewardship / Standard Board Book / representative shuffled dockets / identical authored choice strategy",
  policies: rows.sort((left, right) => left.policyId.localeCompare(right.policyId)),
  comparison: {
    minimumScore: Math.min(...scores),
    maximumScore: Math.max(...scores),
    scoreSpread: Math.max(...scores) - Math.min(...scores),
    distinctScores: new Set(scores).size,
    everyQuarterCompleted: rows.every((row) => row.quarter.shiftCount === 3),
  },
};

fs.mkdirSync(path.dirname(path.resolve(outputPath)), { recursive: true });
fs.writeFileSync(outputPath, `${JSON.stringify(report, null, 2)}\n`);
console.log(JSON.stringify(report, null, 2));
