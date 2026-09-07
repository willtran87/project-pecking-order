import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3001/?build=readable-opening";
const output = path.resolve(process.argv[3] ?? "../output/web-game/readable-opening");
fs.mkdirSync(output, { recursive: true });
const browser = await chromium.launch({ headless: true, args: ["--use-gl=angle", "--use-angle=swiftshader"] });
const page = await browser.newPage({ viewport: { width: Number(process.env.PECK_AUDIT_WIDTH ?? 2560), height: Number(process.env.PECK_AUDIT_HEIGHT ?? 1600) } });
const errors = [];
const evidence = { errors, stages: [] };
page.on("pageerror", error => errors.push(String(error)));
page.on("console", message => { if (message.type() === "error") errors.push(message.text()); });
const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? "{}"));
async function waitFor(predicate, label, timeout = 60000) {
  const deadline = Date.now() + timeout;
  let latest;
  while (Date.now() < deadline) {
    latest = await state();
    if (predicate(latest)) return latest;
    await page.waitForTimeout(150);
  }
  throw new Error(`${label}: ${JSON.stringify(latest?.first_clutch)}`);
}
async function clickPrimary(expected) {
  const snapshot = await waitFor(s => s.first_clutch?.primary_button?.visible && s.first_clutch.primary_button.label === expected, expected);
  const rect = snapshot.first_clutch.primary_button.rect;
  const box = await page.locator("canvas").boundingBox();
  assert.ok(rect.width >= 60 && rect.height >= 30);
  assert.ok(rect.x >= 0 && rect.y >= 0 && rect.x + rect.width <= 1280 && rect.y + rect.height <= 720, "primary action must fit on the canvas");
  await page.mouse.click(box.x + (rect.x + rect.width / 2) * box.width / 1280, box.y + (rect.y + rect.height / 2) * box.height / 720);
  evidence.stages.push({ action: expected, rect });
  await page.waitForTimeout(300);
}
try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitFor(s => s.loaded && s.campaign_stage === "title", "boot");
  await page.keyboard.press("KeyN");
  await waitFor(s => s.campaign_stage === "active", "new career");
  for (let index = 0; index < 4; index++) await page.keyboard.press("Tab");
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
  await page.keyboard.press("Digit3");
  await page.keyboard.press("Enter");
  await waitFor(s => s.first_clutch?.stage === "specialty_route", "specialty lesson");
  for (let index = 0; index < 4; index++) {
    const current = await state();
    if (!current.character_dialogue?.visible || current.character_dialogue?.suspended) break;
    await page.keyboard.press("Enter");
    await page.waitForTimeout(350);
  }
  await page.screenshot({ path: path.join(output, "01-route.png"), fullPage: true });
  await clickPrimary("ROUTE TO APPEALS");
  await waitFor(s => s.first_clutch?.stage === "check_in", "route filed");
  await clickPrimary("FILE CHECK-IN");
  await waitFor(s => s.first_clutch?.stage === "priority_peck", "check-in filed");
  await page.screenshot({ path: path.join(output, "02-start.png"), fullPage: true });
  await clickPrimary("START WORK");
  await waitFor(s => s.first_clutch?.primary_button?.label === "PECK NOW", "gold window", 90000);
  await page.screenshot({ path: path.join(output, "03-peck.png"), fullPage: true });
  await clickPrimary("PECK NOW");
  await waitFor(s => s.first_clutch?.stage === "delivery", "peck accepted");
  await page.screenshot({ path: path.join(output, "04-delivery.png"), fullPage: true });
  evidence.final = await waitFor(s => s.first_clutch?.stage === "reinvestment", "physical delivery and reward", 90000);
  await page.screenshot({ path: path.join(output, "05-reward.png"), fullPage: true });
  assert.deepEqual(errors, []);
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
console.log("READABLE_OPENING_AUDIT_PASSED mouse=route+checkin+start+peck reward=physical-delivery");
