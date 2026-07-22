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

const url = process.argv[2] ?? "http://localhost:3000/?build=responsive-audit";
const outputDir = path.resolve(process.argv[3] ?? "captures/responsive-guided");
const startGame = process.argv.includes("--start-game");
const viewports = [
  { name: "high-2560x1600", width: 2560, height: 1600 },
  { name: "desktop-1440x900", width: 1440, height: 900 },
  { name: "mobile-390x844", width: 390, height: 844 },
  { name: "mobile-landscape-844x390", width: 844, height: 390 },
];

fs.mkdirSync(outputDir, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const page = await browser.newPage({ viewport: viewports[0] });
const errors = [];

page.on("console", (message) => {
  if (message.type() === "error") errors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => errors.push(`page: ${String(error)}`));

await page.goto(url, { waitUntil: "domcontentloaded" });
await page.waitForTimeout(10_000);

if (startGame) {
  const canvas = page.locator("canvas").first();
  const bounds = await canvas.boundingBox();
  if (!bounds) throw new Error("Unable to locate the game canvas for the live opening audit.");
  await page.mouse.click(
    bounds.x + bounds.width * 0.5,
    bounds.y + bounds.height * (594 / 720),
  );
  await page.waitForTimeout(1_500);
}

const results = [];
for (const viewport of viewports) {
  await page.setViewportSize({ width: viewport.width, height: viewport.height });
	await page.evaluate(() => window.dispatchEvent(new Event("resize")));
  await page.waitForTimeout(750);
  await page.screenshot({
    path: path.join(outputDir, `${viewport.name}.png`),
    fullPage: true,
  });
  results.push(await page.evaluate((requestedViewport) => {
    const canvas = document.querySelector("canvas");
    const canvasRect = canvas?.getBoundingClientRect();
    const stateText = typeof window.render_game_to_text === "function"
      ? window.render_game_to_text()
      : null;
    return {
      name: requestedViewport.name,
      requested: {
        width: requestedViewport.width,
        height: requestedViewport.height,
      },
      viewport: { width: window.innerWidth, height: window.innerHeight },
      body: {
        scrollWidth: document.documentElement.scrollWidth,
        clientWidth: document.documentElement.clientWidth,
        horizontalOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth,
      },
      canvas: canvasRect
        ? {
            intrinsicWidth: canvas.width,
            intrinsicHeight: canvas.height,
            x: canvasRect.x,
            y: canvasRect.y,
            width: canvasRect.width,
            height: canvasRect.height,
            aspectRatio: canvasRect.width / canvasRect.height,
          }
        : null,
      diagnostic: stateText ? JSON.parse(stateText) : null,
    };
  }, viewport));
}

const auditFailures = [...errors];
for (const result of results) {
  if (result.body.horizontalOverflow) {
    auditFailures.push(`${result.name}: horizontal page overflow`);
  }
  if (!startGame) continue;
  if (result.diagnostic?.campaign_stage !== "active") {
    auditFailures.push(`${result.name}: live audit did not leave the title screen`);
  }
  if (result.diagnostic?.first_clutch?.visible !== true) {
    auditFailures.push(`${result.name}: opening First Clutch guidance is not visible`);
  }
  const presentation = result.diagnostic?.office_presentation;
  if (
    presentation?.capacity !== 4
    || presentation?.core_visible !== true
    || presentation?.west_partition_visible !== true
    || presentation?.west_perch_04_visible !== false
    || presentation?.west_perch_05_visible !== false
    || presentation?.archive_visible !== false
  ) {
    auditFailures.push(`${result.name}: opening office presentation is not the bounded capacity-four state`);
  }
}

fs.writeFileSync(
  path.join(outputDir, "audit.json"),
  JSON.stringify({
    url,
    mode: startGame ? "live" : "title",
    errors,
    auditFailures,
    results,
  }, null, 2),
);

if (auditFailures.length) {
  throw new Error(`Responsive audit failed:\n${auditFailures.join("\n")}`);
}

await browser.close();

if (errors.length > 0) {
  throw new Error(`Browser errors: ${errors.join(" | ")}`);
}
