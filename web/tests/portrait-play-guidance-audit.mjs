import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3001/";
const output = path.resolve(process.argv[3] ?? "../output/web-game/portrait-guidance");
fs.mkdirSync(output, { recursive: true });

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({
  viewport: { width: 390, height: 844 },
  isMobile: true,
  hasTouch: true,
  deviceScaleFactor: 1,
});
try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  const guidance = page.locator(".portrait-guidance");
  await guidance.waitFor({ state: "visible" });
  assert.match(await guidance.innerText(), /Turn your phone sideways/);
  assert.equal(await guidance.locator("button").count(), 2);
  assert.ok(await guidance.locator("button").evaluateAll(buttons => buttons.every(button => button.getBoundingClientRect().height >= 44)));
  assert.match(await guidance.innerText(), /Full screen & rotate/);
  await page.screenshot({ path: path.join(output, "01-portrait.png") });

  await page.setViewportSize({ width: 844, height: 390 });
  assert.equal(await guidance.isVisible(), false, "landscape play must reveal the canvas automatically");
  await page.setViewportSize({ width: 390, height: 844 });
  assert.equal(await guidance.isVisible(), true, "returning to portrait should restore guidance");
  await guidance.getByRole("button", { name: "Continue at small size" }).click();
  assert.equal(await guidance.count(), 0, "the player can deliberately continue in portrait");
  console.log("PORTRAIT_PLAY_GUIDANCE_AUDIT_PASSED landscape=auto-reveal portrait=dismissible target=44px");
} finally {
  await browser.close();
}
