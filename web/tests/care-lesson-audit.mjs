import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3001/?build=care-lesson";
const output = path.resolve(process.argv[3] ?? "../output/web-game/care-lesson");
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ["--use-gl=angle", "--use-angle=swiftshader"] });
const page = await browser.newPage({ viewport: { width: Number(process.env.PECK_AUDIT_WIDTH ?? 2560), height: Number(process.env.PECK_AUDIT_HEIGHT ?? 1600) } });
const evidence = { errors: [] };
page.on("pageerror", e => evidence.errors.push(String(e)));
page.on("console", e => { if (e.type() === "error") evidence.errors.push(e.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? "{}"));
async function waitFor(predicate, label) {
  const deadline = Date.now() + 90000;
  while (Date.now() < deadline) {
    const current = await state();
    if (predicate(current)) return current;
    await page.waitForTimeout(200);
  }
  throw new Error(label);
}
async function click(rect) {
  assert.ok(rect.width > 0 && rect.height >= 26 && rect.x >= 0 && rect.y >= 0 && rect.x + rect.width <= 1281 && rect.y + rect.height <= 721, "action must fit the game canvas");
  const box = await page.locator("canvas").boundingBox();
  await page.mouse.click(box.x + (rect.x + rect.width / 2) * box.width / 1280, box.y + (rect.y + rect.height / 2) * box.height / 720);
}
async function openLesson() {
  await page.keyboard.press("KeyQ");
  await waitFor(s => s.manager_power?.popup_visible, "PLAN must open");
  await page.keyboard.press("ArrowUp");
  await page.waitForTimeout(400);
  await page.screenshot({ path: path.join(output, "00-plan-menu.png"), fullPage: true });
  await page.keyboard.press("Enter");
  return waitFor(s => s.care_lesson?.visible, "optional care must open");
}
try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitFor(s => s.loaded && s.campaign_stage === "title", "title");
  await page.keyboard.press("KeyN");
  await waitFor(s => s.campaign_stage === "active", "new career");
  for (let i = 0; i < 4; i++) await page.keyboard.press("Tab");
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
  await page.keyboard.press("Digit1");
  await page.keyboard.press("Enter");
  const coach = await waitFor(s => s.first_clutch?.can_skip && s.first_clutch?.skip_button_rect?.width > 0, "coach skip");
  await click(coach.first_clutch.skip_button_rect);
  await waitFor(s => !s.first_clutch?.visible && s.shift_phase === 1, "live shift");
  for (let i = 0; i < 4; i++) {
    const current = await state();
    if (!current.character_dialogue?.visible || current.character_dialogue?.suspended) break;
    await page.keyboard.press("Enter");
    await page.waitForTimeout(350);
  }
  evidence.offered = (await openLesson()).care_lesson;
  await page.screenshot({ path: path.join(output, "01-choice.png"), fullPage: true });
  await click(evidence.offered.controls.later.rect);
  await waitFor(s => !s.care_lesson?.visible, "Later must leave");
  evidence.reopened = (await openLesson()).care_lesson;
  assert.equal(evidence.reopened.controls.choice.disabled, false);
  await click(evidence.reopened.controls.choice.rect);
  evidence.completed = (await waitFor(s => s.care_lesson?.complete, "real check-in must complete the lesson")).care_lesson;
  assert.match(evidence.completed.summary, /FILED/);
  await page.screenshot({ path: path.join(output, "02-result.png"), fullPage: true });
  await click(evidence.completed.controls.later.rect);
  await waitFor(s => !s.care_lesson?.visible, "Back to work must leave");
  assert.deepEqual(evidence.errors, []);
  evidence.passed = true;
} catch (error) {
  evidence.failure = String(error);
  evidence.final = await state();
  await page.screenshot({ path: path.join(output, "failure.png"), fullPage: true });
  throw error;
} finally {
  fs.writeFileSync(path.join(output, "audit.json"), JSON.stringify(evidence, null, 2));
  await browser.close();
}
console.log("CARE_LESSON_AUDIT_PASSED real-controls=later+reopen+check-in+return");
