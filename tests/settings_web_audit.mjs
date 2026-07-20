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
  // A real DOM focus plus pointer activation is required by Godot Web before it
  // forwards keyboard events. Retry the same public F10 route after a short
  // readiness window instead of assuming one key event survives shader startup.
  for (let attempt = 0; attempt < 3; attempt += 1) {
    await canvas.focus();
    await canvas.click({ position: { x: 8, y: 8 } });
    await canvas.focus();
    await page.keyboard.press("F10");
    try {
      await page.waitForFunction(() => {
        if (typeof window.render_game_to_text !== "function") return false;
        return JSON.parse(window.render_game_to_text()).settings?.visible === true;
      }, null, { timeout: 5_000 });
      return;
    } catch {
      await page.waitForTimeout(500);
    }
  }
  await waitForSettings("open");
};

const toggleHighContrast = async (expectedState) => {
  // Settings gives its safe Return button initial focus. Walk the authored
  // keyboard order through five mute/slider pairs and five selectors to the
  // High Contrast check row, then activate it with Space. This follows the
  // same reachable path a keyboard or switch-control player uses and avoids
  // viewport-dependent coordinates inside the Godot canvas.
  for (let index = 0; index < 16; index += 1) {
    await page.keyboard.press("Tab");
  }
  await page.waitForTimeout(300);
  await page.screenshot({
    path: path.join(outputDir, `settings-appearance-${expectedState ? "before-on" : "before-off"}.png`),
    fullPage: true,
  });
  await page.keyboard.press("Space");
  await waitForSettings(expectedState ? "contrast-on" : "contrast-off");
};

await page.goto(url, { waitUntil: "domcontentloaded" });
await focusGameAndOpenSettings();
const initial = await readDiagnostic();
if (!initial?.settings?.accessible_text?.includes("Coop Settings and Controls")) {
  throw new Error("Open settings did not publish its accessible summary.");
}
if (!initial.settings.accessible_text.toLowerCase().includes("office hum + flock room tone 65 percent")) {
  throw new Error("Open settings did not narrate the independent ambience channel.");
}
if (initial.settings.pause_when_unfocused !== true || initial.settings.focus_pause_active !== false) {
  throw new Error("Fresh browser settings did not publish the default-on idle focus safety.");
}
if (initial.settings.audio?.ambient?.volume !== 0.65 || initial.settings.audio?.music?.volume !== 0.65) {
  throw new Error("Fresh browser settings did not publish distinct music and ambience channels.");
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
if (restored?.settings?.pause_when_unfocused !== true || restored?.settings?.audio?.ambient?.volume !== 0.65) {
  throw new Error("Focus safety or independent ambience did not survive browser preference restoration.");
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
