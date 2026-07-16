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

const url = process.argv[2] ?? "http://localhost:3000/?build=settings-web-audit";
const outputDir = path.resolve(process.argv[3] ?? "output/web-game/settings-web-audit");
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

const waitForSettings = async (predicate) => page.waitForFunction((serializedPredicate) => {
  if (typeof window.render_game_to_text !== "function") return false;
  const settings = JSON.parse(window.render_game_to_text()).settings;
  if (!settings) return false;
  if (serializedPredicate === "open") return settings.visible === true;
  if (serializedPredicate === "contrast-on") return settings.visible === true && settings.high_contrast === true;
  if (serializedPredicate === "contrast-off") return settings.visible === true && settings.high_contrast === false;
  return false;
}, predicate, { timeout: 25_000 });

const focusGameAndOpenSettings = async () => {
  const canvas = page.locator("canvas");
  await canvas.waitFor({ state: "visible", timeout: 25_000 });
  await page.waitForFunction(() => {
    if (typeof window.render_game_to_text !== "function") return false;
    return Boolean(JSON.parse(window.render_game_to_text()).settings);
  }, null, { timeout: 25_000 });
  // A real pointer focus is required by Godot Web before it forwards keyboard
  // events. Use a quiet top-left canvas point outside the title-card actions.
  await canvas.click({ position: { x: 8, y: 8 } });
  await page.keyboard.press("F10");
  await waitForSettings("open");
};

const toggleHighContrast = async (expectedState) => {
  const canvas = page.locator("canvas");
  const bounds = await canvas.boundingBox();
  if (!bounds) throw new Error("Godot canvas bounds were unavailable.");
  await page.mouse.move(bounds.x + bounds.width * 0.5, bounds.y + bounds.height * 0.72);
  await page.mouse.wheel(0, 1_200);
  await page.waitForTimeout(500);
  await page.screenshot({
    path: path.join(outputDir, `settings-comfort-${expectedState ? "before-on" : "before-off"}.png`),
    fullPage: true,
  });
  // The responsive Godot panel keeps this full-width check row pinned directly
  // above its safety copy when the internal scroll reaches the comfort section.
  // Use its visible switch so this browser audit exercises the real persisted
  // control rather than mutating the diagnostic or virtual filesystem directly.
  let changed = false;
  for (const yRatio of [0.11, 0.13, 0.15, 0.17]) {
    await page.mouse.click(bounds.x + bounds.width * 0.5, bounds.y + bounds.height * yRatio);
    await page.waitForTimeout(300);
    const diagnostic = await readDiagnostic();
    if (diagnostic?.settings?.high_contrast === expectedState) {
      changed = true;
      break;
    }
  }
  if (!changed) throw new Error("Visible high-contrast control did not accept pointer input.");
};

await page.goto(url, { waitUntil: "domcontentloaded" });
await focusGameAndOpenSettings();
const initial = await readDiagnostic();
if (!initial?.settings?.accessible_text?.includes("Coop Comfort and Controls")) {
  throw new Error("Open settings did not publish its accessible summary.");
}
if (initial.settings.high_contrast !== false) {
  throw new Error("Fresh browser context did not begin from the documented contrast default.");
}

await page.screenshot({ path: path.join(outputDir, "settings-desktop.png"), fullPage: true });
await toggleHighContrast(true);
await page.keyboard.press("F10");
await page.waitForTimeout(1_000);

await page.reload({ waitUntil: "domcontentloaded" });
await focusGameAndOpenSettings();
const restored = await readDiagnostic();
if (restored?.settings?.high_contrast !== true) {
  throw new Error("High-contrast preference did not survive a browser reload.");
}

await page.setViewportSize({ width: 844, height: 390 });
await page.waitForTimeout(750);
await page.screenshot({ path: path.join(outputDir, "settings-landscape-844x390.png"), fullPage: true });
const responsive = await page.evaluate(() => {
  const canvas = document.querySelector("canvas");
  const rect = canvas?.getBoundingClientRect();
  return {
    horizontalOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth,
    canvasAspectRatio: rect ? rect.width / rect.height : null,
  };
});
if (responsive.horizontalOverflow || Math.abs(responsive.canvasAspectRatio - (16 / 9)) > 0.002) {
  throw new Error("Settings landscape layout broke the responsive browser shell.");
}

await page.setViewportSize({ width: 1440, height: 900 });
await page.waitForTimeout(500);
await toggleHighContrast(false);
await page.keyboard.press("F10");

fs.writeFileSync(path.join(outputDir, "audit.json"), JSON.stringify({
  url,
  errors,
  initialSettings: initial.settings,
  restoredSettings: restored.settings,
  responsive,
}, null, 2));

await browser.close();
if (errors.length > 0) throw new Error(`Browser errors: ${errors.join(" | ")}`);
