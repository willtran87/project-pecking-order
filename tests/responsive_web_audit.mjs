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
const viewports = [
  { name: "high-2560x1600", width: 2560, height: 1600 },
  { name: "desktop-1440x900", width: 1440, height: 900 },
  { name: "mobile-390x844", width: 390, height: 844 },
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

const results = [];
for (const viewport of viewports) {
  await page.setViewportSize({ width: viewport.width, height: viewport.height });
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

fs.writeFileSync(
  path.join(outputDir, "audit.json"),
  JSON.stringify({ url, errors, results }, null, 2),
);

await browser.close();

if (errors.length > 0) {
  throw new Error(`Browser errors: ${errors.join(" | ")}`);
}
