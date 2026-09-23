import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3001/";
const output = path.resolve(process.argv[3] ?? "../output/web-game/focused-play-access");
fs.mkdirSync(output, { recursive: true });

const browser = await chromium.launch({ headless: true, args: ["--use-gl=angle", "--use-angle=swiftshader"] });
const page = await browser.newPage({ viewport: { width: 2560, height: 1600 } });
const errors = [];
page.on("pageerror", error => errors.push(String(error)));
page.on("console", message => { if (message.type() === "error") errors.push(message.text()); });

try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await page.getByRole("button", { name: "Focus the game" }).click();
  const geometry = await page.locator(".game-stage").evaluate(stage => {
    const canvas = stage.querySelector("canvas");
    const outer = stage.getBoundingClientRect();
    const inner = canvas?.getBoundingClientRect();
    return {
      stage: { x: outer.x, y: outer.y, width: outer.width, height: outer.height },
      canvas: inner && { x: inner.x, y: inner.y, width: inner.width, height: inner.height },
    };
  });
  assert.ok(geometry.stage.width >= 2400, "focused game should use the available high-resolution width");
  assert.ok(geometry.canvas && Math.abs(geometry.canvas.width - geometry.stage.width) < 1, "canvas must remain anchored to its stage");
  assert.ok(geometry.stage.x >= 0 && geometry.stage.x + geometry.stage.width <= 2560, "stage must fit the viewport");

  await page.locator("#canvas").focus();
  assert.equal(await page.evaluate(() => document.activeElement?.id), "canvas");
  await page.keyboard.press("Tab");
  assert.equal(await page.evaluate(() => document.activeElement?.id), "canvas", "plain Tab remains the in-game hen-cycle shortcut");
  await page.keyboard.press("Shift+Tab");
  assert.notEqual(await page.evaluate(() => document.activeElement?.id), "canvas", "Shift+Tab must let a keyboard player exit the game canvas");
  assert.match(await page.locator("#game-controls").innerText(), /Shift\+Tab leaves the game/);
  await page.screenshot({ path: path.join(output, "01-focused-highres.png") });
  assert.deepEqual(errors, []);
  console.log("FOCUSED_PLAY_ACCESS_AUDIT_PASSED highres=2560x1600 tab=game shift-tab=exit canvas=stage-anchored");
} finally {
  await browser.close();
}
