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
  if (serializedPredicate === "scale-150") return settings.visible === true && settings.ui_scale === 1.5;
  if (serializedPredicate === "scale-100") return settings.visible === true && settings.ui_scale === 1;
  if (serializedPredicate.startsWith("category-")) {
    return settings.visible === true
      && settings.active_category === serializedPredicate.slice("category-".length);
  }
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
  // keyboard order through four category tabs and the Comfort & Display rows to
  // High Contrast, then activate it with Space. Hidden category pages do not
  // enter the focus path.
  await page.waitForTimeout(250);
  for (let index = 0; index < 19; index += 1) {
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

const selectInterfaceScale = async (selectionKey, expectedScale) => {
  // Safe Return owns initial focus. Four category tabs, then Motion, Camera
  // Motion, Camera Input, and Interface Scale place focus on the scale selector.
  // Wait for show_settings()' deferred safe-focus request before traversing.
  await page.waitForTimeout(250);
  for (let index = 0; index < 8; index += 1) {
    await page.keyboard.press("Tab");
  }
  await page.screenshot({
    path: path.join(outputDir, `settings-scale-${selectionKey === "End" ? "before-max" : "before-default"}.png`),
    fullPage: true,
  });
  // Pointer activation is also a shipped input path. Open the focused selector
  // at its authored desktop position, then traverse its three-item popup with
  // bounded arrow steps; Home/End is not consistently forwarded by Chromium to
  // Godot's popup on Windows.
  const canvas = page.locator("canvas");
  const box = await canvas.boundingBox();
  if (!box) throw new Error("Settings canvas has no interaction bounds.");
  await page.mouse.click(box.x + (box.width * 0.6), box.y + (box.height * 0.605));
  const directionKey = selectionKey === "End" ? "ArrowDown" : "ArrowUp";
  // The first popup arrow establishes the current-item cursor; the next two
  // reach the opposite endpoint of this three-item list.
  for (let index = 0; index < 3; index += 1) {
    await page.keyboard.press(directionKey);
  }
  await page.keyboard.press("Enter");
  await waitForSettings(expectedScale === 1.5 ? "scale-150" : "scale-100");
};

const screenshotCategory = async (category, suffix = "desktop") => {
  await waitForSettings(`category-${category}`);
  const diagnostic = await readDiagnostic();
  if (
    diagnostic.settings.available_categories?.join(",") !== "audio,comfort,controls,career"
    || diagnostic.settings.active_category !== category
  ) {
    throw new Error(`Settings did not publish the ${category} category contract.`);
  }
  await page.screenshot({
    path: path.join(outputDir, `settings-${category}-${suffix}.png`),
    fullPage: true,
  });
  return diagnostic.settings;
};

await page.goto(url, { waitUntil: "domcontentloaded" });
await focusGameAndOpenSettings();
const initial = await readDiagnostic();
if (!initial?.settings?.accessible_text?.includes("Coop Settings and Controls")) {
  throw new Error("Open settings did not publish its accessible summary.");
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
if (
  initial.settings.effect_level !== "full"
  || initial.settings.particle_level !== "full"
  || initial.settings.camera_motion !== "full"
  || initial.settings.camera_sensitivity !== "standard"
  || initial.settings.notice_duration !== "standard"
  || initial.settings.animation_speed !== "standard"
  || initial.settings.animation_speed_multiplier !== 1
  || initial.settings.tooltip_delay !== "standard"
  || initial.settings.tooltip_delay_seconds !== 0.5
  || initial.settings.guidance_mode !== "full"
  || initial.settings.first_clutch_replay_available !== false
  || initial.settings.first_clutch_reference?.mode !== "review"
  || initial.settings.first_clutch_reference?.playbook_visible !== false
  || initial.settings.first_clutch_reference?.step_count !== 5
  || initial.settings.first_clutch_reference?.mutates_campaign !== false
  || initial.settings.haptics_enabled !== true
) {
  throw new Error("Fresh browser settings did not publish the feedback preference defaults.");
}
if (
  initial.settings.active_category !== "comfort"
  || initial.settings.available_categories?.join(",") !== "audio,comfort,controls,career"
  || initial.settings.settings_category !== "comfort"
  || !initial.settings.accessible_text.toLowerCase().includes("comfort & display category, 2 of 4")
  || initial.settings.accessible_text.toLowerCase().includes("master 100 percent")
  ||
  !initial.settings.accessible_text.toLowerCase().includes("effect density full")
  || !initial.settings.accessible_text.toLowerCase().includes("particle density full")
  || !initial.settings.accessible_text.toLowerCase().includes("camera motion full")
  || !initial.settings.accessible_text.toLowerCase().includes("camera input sensitivity standard")
  || !initial.settings.accessible_text.toLowerCase().includes("animation speed standard")
  || !initial.settings.accessible_text.toLowerCase().includes("tooltip delay standard")
  || !initial.settings.accessible_text.toLowerCase().includes("guidance full")
  || !initial.settings.accessible_text.toLowerCase().includes("standard duration")
  || !initial.settings.accessible_text.toLowerCase().includes("haptics enabled")
) {
  throw new Error("Open settings did not publish the focused Comfort and Display category.");
}

const desktopCategories = {};
desktopCategories.comfort = await screenshotCategory("comfort");
// Safe Return owns initial focus. Tab reaches Audio Mix; activation and arrow
// navigation then exercise the authored public category path.
await page.keyboard.press("Tab");
await page.keyboard.press("Space");
desktopCategories.audio = await screenshotCategory("audio");
if (
  !desktopCategories.audio.accessible_text.toLowerCase().includes("office hum + flock room tone 65 percent")
  || desktopCategories.audio.accessible_text.toLowerCase().includes("camera motion full")
) {
  throw new Error("Audio Mix narration was not scoped to the active category.");
}
await page.keyboard.press("ArrowRight");
desktopCategories.comfort = await screenshotCategory("comfort");
await page.keyboard.press("ArrowRight");
desktopCategories.controls = await screenshotCategory("controls");
if (!desktopCategories.controls.accessible_text.toLowerCase().includes("select a floor or camera control")) {
  throw new Error("Controls category did not publish its rebinding guidance.");
}
await page.keyboard.press("ArrowRight");
desktopCategories.career = await screenshotCategory("career");
if (!desktopCategories.career.accessible_text.toLowerCase().includes("explicit replacement confirmation")) {
  throw new Error("Career Backup category did not publish its replacement safeguard.");
}
await page.keyboard.press("ArrowLeft");
await page.keyboard.press("ArrowLeft");
await waitForSettings("category-comfort");
await page.keyboard.press("F10");
await page.waitForTimeout(300);
await page.keyboard.press("F10");
await waitForSettings("open");
await selectInterfaceScale("End", 1.5);
const maxScaleDesktop = await screenshotCategory("comfort", "150-desktop");
await page.keyboard.press("F10");
await page.waitForTimeout(300);
await page.keyboard.press("F10");
await waitForSettings("open");
await toggleHighContrast(true);
await page.keyboard.press("F10");
await page.waitForTimeout(1_000);

await page.reload({ waitUntil: "domcontentloaded" });
await focusGameAndOpenSettings();
const restored = await readDiagnostic();
if (restored?.settings?.high_contrast !== true) {
  throw new Error("High-contrast preference did not survive a browser reload.");
}
if (restored?.settings?.active_category !== "comfort" || restored?.settings?.settings_category !== "comfort") {
  throw new Error("The last selected settings category did not survive a browser reload.");
}
if (restored?.settings?.ui_scale !== 1.5) {
  throw new Error("The maximum interface scale did not survive a browser reload.");
}
if (restored?.settings?.pause_when_unfocused !== true || restored?.settings?.audio?.ambient?.volume !== 0.65) {
  throw new Error("Focus safety or independent ambience did not survive browser preference restoration.");
}
if (
  restored?.settings?.effect_level !== "full"
  || restored?.settings?.particle_level !== "full"
  || restored?.settings?.camera_motion !== "full"
  || restored?.settings?.camera_sensitivity !== "standard"
  || restored?.settings?.notice_duration !== "standard"
  || restored?.settings?.animation_speed !== "standard"
  || restored?.settings?.animation_speed_multiplier !== 1
  || restored?.settings?.tooltip_delay !== "standard"
  || restored?.settings?.tooltip_delay_seconds !== 0.5
  || restored?.settings?.guidance_mode !== "full"
  || restored?.settings?.first_clutch_reference?.mode !== "review"
  || restored?.settings?.first_clutch_reference?.step_count !== 5
  || restored?.settings?.first_clutch_reference?.mutates_campaign !== false
  || restored?.settings?.haptics_enabled !== true
) {
  throw new Error("Feedback preferences did not survive browser preference restoration.");
}

await page.setViewportSize({ width: 844, height: 390 });
await page.waitForTimeout(750);
const compactCategories = {};
compactCategories.comfort = await screenshotCategory("comfort", "150-844x390");
await page.keyboard.press("Tab");
await page.keyboard.press("Space");
compactCategories.audio = await screenshotCategory("audio", "150-844x390");
await page.keyboard.press("ArrowRight");
compactCategories.comfort = await screenshotCategory("comfort", "150-844x390");
await page.keyboard.press("ArrowRight");
compactCategories.controls = await screenshotCategory("controls", "150-844x390");
await page.keyboard.press("ArrowRight");
compactCategories.career = await screenshotCategory("career", "150-844x390");
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
// Return to Comfort and reset the temporary contrast choice so this audit is
// repeatable even when its browser profile is reused.
await page.keyboard.press("F10");
await page.waitForTimeout(300);
await page.keyboard.press("F10");
await waitForSettings("open");
await page.keyboard.press("Tab");
await page.keyboard.press("ArrowRight");
await waitForSettings("category-comfort");
await page.keyboard.press("F10");
await page.waitForTimeout(300);
await page.keyboard.press("F10");
await waitForSettings("open");
await toggleHighContrast(false);
await page.keyboard.press("F10");

fs.writeFileSync(path.join(outputDir, "audit.json"), JSON.stringify({
  url,
  errors,
  initialSettings: initial.settings,
  restoredSettings: restored.settings,
  maxScaleDesktop,
  desktopCategories,
  compactCategories,
  responsive,
}, null, 2));

await browser.close();
if (errors.length > 0) throw new Error(`Browser errors: ${errors.join(" | ")}`);
