import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

// Authored local review fixture for layout; not evidence of a completed human shift.
const url = process.argv[2] ?? "http://localhost:3001/?preview=shift-result";
const output = path.resolve(process.argv[3] ?? "../output/web-game/personal-goal-review");
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ["--use-gl=angle", "--use-angle=swiftshader"] });
const page = await browser.newPage({ viewport: { width: Number(process.env.PECK_AUDIT_WIDTH ?? 2560), height: Number(process.env.PECK_AUDIT_HEIGHT ?? 1600) } });
const errors = [];
const evidence = { fixture: "authored shift-result preview", errors };
page.on("pageerror", error => errors.push(String(error)));
page.on("console", message => { if (message.type() === "error") errors.push(message.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? "{}"));
async function waitFor(predicate) {
  for (let attempt = 0; attempt < 400; attempt++) {
    const current = await state();
    if (predicate(current)) return current;
    await page.waitForTimeout(250);
  }
  throw new Error("Review goal control did not settle");
}
async function clickGoal(current) {
  const rect = current.personal_goal_control.rect;
  assert.ok(rect.x >= 0 && rect.y >= 0 && rect.x + rect.width <= 1280 && rect.y + rect.height <= 720, "goal button must remain inside the authored canvas");
  const box = await page.locator("canvas").boundingBox();
  await page.mouse.click(box.x + (rect.x + rect.width / 2) * box.width / 1280, box.y + (rect.y + rect.height / 2) * box.height / 720);
}
try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  evidence.offered = await waitFor(s => s.personal_goal_control?.visible);
  await page.screenshot({ path: path.join(output, "01-review-offer.png"), fullPage: true });
  await clickGoal(evidence.offered);
  evidence.accepted = await waitFor(s => s.personal_shift_goal?.status === "active");
  assert.match(evidence.accepted.personal_goal_control.label, /ACCEPTED/);
  assert.ok(evidence.accepted.personal_shift_goal.quota > 1, "the real review report must not silently offer a quota of one");
  await page.screenshot({ path: path.join(output, "02-goal-accepted.png"), fullPage: true });
  await clickGoal(evidence.accepted);
  evidence.canceled = await waitFor(s => Object.keys(s.personal_shift_goal ?? {}).length === 0 && s.personal_goal_control?.label.startsWith("TRY NEXT SHIFT"));
  assert.deepEqual(errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error);
  await page.screenshot({ path: path.join(output, "failure.png"), fullPage: true });
  throw error;
} finally {
  fs.writeFileSync(path.join(output, "audit.json"), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log("PERSONAL_GOAL_REVIEW_AUDIT_PASSED actual-clicks=accept+cancel");
