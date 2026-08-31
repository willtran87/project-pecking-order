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

const url = process.argv[2] ?? "http://localhost:3000/?build=economic-briefing-web-audit";
const outputDir = path.resolve(
  process.argv[3] ?? "output/web-game/economic-briefing-web-audit",
);
fs.mkdirSync(outputDir, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
const errors = [];
page.on("console", (message) => {
  if (message.type() === "error") errors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => errors.push(`page: ${String(error)}`));

const readDiagnostic = async () => page.evaluate(() => {
  if (typeof window.render_game_to_text !== "function") return null;
  return JSON.parse(window.render_game_to_text());
});

const canvas = page.locator("canvas");
const clickCanvas = async (logicalX, logicalY) => {
  const box = await canvas.boundingBox();
  if (!box) throw new Error("Godot canvas has no interaction bounds.");
  await page.mouse.click(
    box.x + (box.width * (logicalX / 1280)),
    box.y + (box.height * (logicalY / 720)),
  );
};

await page.goto(url, { waitUntil: "domcontentloaded" });
await canvas.waitFor({ state: "visible", timeout: 25_000 });
await page.waitForFunction(() => (
  typeof window.render_game_to_text === "function"
  && Boolean(JSON.parse(window.render_game_to_text()).settings)
), null, { timeout: 25_000 });

// Begin the authored file through the visible intake action.
await canvas.focus();
await clickCanvas(640, 605);
await page.waitForFunction(() => (
  JSON.parse(window.render_game_to_text()).campaign_stage === "active"
), null, { timeout: 15_000 });

// Open Flockwatch, reveal its optional filing pages, and select Capital.
await canvas.focus();
await page.keyboard.press("KeyV");
await page.waitForFunction(() => (
  JSON.parse(window.render_game_to_text()).flockwatch?.visible === true
), null, { timeout: 10_000 });
await clickCanvas(1180, 193);
await page.waitForTimeout(200);
await clickCanvas(1160, 226);
await page.waitForFunction(() => (
  JSON.parse(window.render_game_to_text()).flockwatch?.available_pages?.includes("capital")
), null, { timeout: 10_000 });
await clickCanvas(1180, 193);
await page.waitForTimeout(200);
await clickCanvas(1160, 254);
await page.waitForFunction(() => (
  JSON.parse(window.render_game_to_text()).flockwatch?.current_page === "capital"
), null, { timeout: 10_000 });

// Set maximum interface scale through the same public Settings selector used by
// players. The first ArrowDown establishes PopupMenu's current-item cursor.
await canvas.focus();
await page.keyboard.press("F10");
await page.waitForFunction(() => (
  JSON.parse(window.render_game_to_text()).settings?.visible === true
), null, { timeout: 10_000 });
await page.waitForTimeout(250);
await clickCanvas(800, 436);
for (let index = 0; index < 3; index += 1) {
  await page.keyboard.press("ArrowDown");
}
await page.keyboard.press("Enter");
await page.waitForFunction(() => (
  JSON.parse(window.render_game_to_text()).settings?.ui_scale === 1.5
), null, { timeout: 10_000 });
await page.keyboard.press("F10");
await page.waitForFunction(() => {
  const diagnostic = JSON.parse(window.render_game_to_text());
  return diagnostic.settings?.visible === false
    && diagnostic.flockwatch?.visible === true
    && diagnostic.flockwatch?.current_page === "capital";
}, null, { timeout: 10_000 });
await page.waitForTimeout(500);

const diagnostic = await readDiagnostic();
const briefingText = diagnostic?.flockwatch?.accessible_text ?? "";
for (const fragment of [
  "Economic briefing",
  "Secured operating margin",
  "Primary bottleneck",
  "Action:",
]) {
  if (!briefingText.includes(fragment)) {
    throw new Error(`Capital narration is missing ${JSON.stringify(fragment)}.`);
  }
}
if (diagnostic?.settings?.ui_scale !== 1.5) {
  throw new Error("Capital renderer did not retain maximum interface scale.");
}

const responsive = await page.evaluate(() => {
  const gameCanvas = document.querySelector("canvas");
  const rect = gameCanvas?.getBoundingClientRect();
  return {
    horizontalOverflow: document.documentElement.scrollWidth
      > document.documentElement.clientWidth,
    canvasAspectRatio: rect ? rect.width / rect.height : null,
  };
});
if (
  responsive.horizontalOverflow
  || Math.abs(responsive.canvasAspectRatio - (16 / 9)) > 0.002
) {
  throw new Error("Max-scale Capital briefing broke the responsive Web shell.");
}

await page.screenshot({
  path: path.join(outputDir, "economic-briefing-150-desktop.png"),
  fullPage: true,
});
fs.writeFileSync(path.join(outputDir, "audit.json"), JSON.stringify({
  url,
  errors,
  stage: diagnostic.campaign_stage,
  settingsScale: diagnostic.settings.ui_scale,
  flockwatch: {
    visible: diagnostic.flockwatch.visible,
    page: diagnostic.flockwatch.current_page,
    availablePages: diagnostic.flockwatch.available_pages,
    accessibleText: briefingText,
  },
  responsive,
}, null, 2));

await browser.close();
if (errors.length > 0) {
  throw new Error(`Browser errors: ${errors.join(" | ")}`);
}
