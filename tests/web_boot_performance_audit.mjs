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

const url = process.argv[2] ?? "http://localhost:3000/?build=boot-performance-audit";
const outputDir = path.resolve(process.argv[3] ?? "output/web-game/boot-performance-audit");
const readyBudgetMsec = Number(process.env.BOOT_READY_BUDGET_MSEC || 0);
const warmReadyBudgetMsec = Number(process.env.BOOT_WARM_READY_BUDGET_MSEC || 0);
fs.mkdirSync(outputDir, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const errors = [];

async function measure(label, page, navigate) {
  page.on("console", (message) => {
    if (message.type() === "error") errors.push(`${label} console: ${message.text()}`);
  });
  page.on("pageerror", (error) => errors.push(`${label} page: ${String(error)}`));

  const wallStart = Date.now();
  await navigate();
  const domContentLoadedMsec = Date.now() - wallStart;
  await page.waitForFunction(() => {
    if (typeof window.render_game_to_text !== "function") return false;
    try { return JSON.parse(window.render_game_to_text()).loaded === true; } catch { return false; }
  }, null, { timeout: 90_000 });
  const diagnosticReadyMsec = Date.now() - wallStart;
  const result = await page.evaluate(({ name, domMsec, readyMsec }) => {
    const navigation = performance.getEntriesByType("navigation")[0];
    const gameResources = performance.getEntriesByType("resource")
      .filter((entry) => entry.name.includes("/game/"))
      .map((entry) => ({
        name: new URL(entry.name).pathname,
        startTimeMsec: Math.round(entry.startTime),
        responseStartMsec: Math.round(entry.responseStart),
        responseEndMsec: Math.round(entry.responseEnd),
        durationMsec: Math.round(entry.duration),
        transferBytes: entry.transferSize,
        encodedBytes: entry.encodedBodySize,
        decodedBytes: entry.decodedBodySize,
      }))
      .sort((left, right) => left.startTimeMsec - right.startTimeMsec);
    let bootTiming = window.__pecking_order_boot_timing ?? null;
    try {
      const rendered = typeof window.render_game_to_text === "function"
        ? JSON.parse(window.render_game_to_text())
        : null;
      bootTiming = rendered?.boot ?? bootTiming;
    } catch {
      // Keep the resource trace useful if a diagnostic read races a write.
    }
    return {
      label: name,
      domContentLoadedMsec: domMsec,
      diagnosticReadyMsec: readyMsec,
      navigation: navigation ? {
        responseStartMsec: Math.round(navigation.responseStart),
        responseEndMsec: Math.round(navigation.responseEnd),
        domInteractiveMsec: Math.round(navigation.domInteractive),
        domContentLoadedMsec: Math.round(navigation.domContentLoadedEventEnd),
        loadEventMsec: Math.round(navigation.loadEventEnd),
      } : null,
      gameResources,
      bootTiming,
      loadingVisible: Boolean(document.querySelector(".loading-state")),
      canvasVisible: document.querySelector("canvas")?.classList.contains("is-loaded") ?? false,
    };
  }, { name: label, domMsec: domContentLoadedMsec, readyMsec: diagnosticReadyMsec });
  const optionalAtReady = result.bootTiming?.optional_visuals;
  if (optionalAtReady?.deferred === true && optionalAtReady?.ready !== true) {
    try {
      await page.waitForFunction(() => {
        if (typeof window.render_game_to_text !== "function") return false;
        try {
          const state = JSON.parse(window.render_game_to_text());
          return state?.boot?.optional_visuals?.ready === true;
        } catch {
          return false;
        }
      }, null, { timeout: 60_000 });
      result.optionalVisualsReadyMsec = Date.now() - wallStart;
      result.finalBootTiming = await page.evaluate(() => {
        try { return JSON.parse(window.render_game_to_text()).boot ?? null; } catch { return null; }
      });
    } catch {
      result.optionalVisualsReadyMsec = null;
      result.finalBootTiming = null;
    }
  }
  return result;
}

const coldPage = await context.newPage();
const cold = await measure("cold", coldPage, () => coldPage.goto(url, { waitUntil: "domcontentloaded" }));
await coldPage.screenshot({ path: path.join(outputDir, "cold-ready.png") });

const warm = await measure("warm-reload", coldPage, () => coldPage.reload({ waitUntil: "domcontentloaded" }));
await coldPage.screenshot({ path: path.join(outputDir, "warm-ready.png") });

const report = { url, readyBudgetMsec, warmReadyBudgetMsec, errors, runs: [cold, warm] };
fs.writeFileSync(path.join(outputDir, "audit.json"), JSON.stringify(report, null, 2));
await browser.close();

const failures = [...errors];
for (const run of report.runs) {
  if (!run.canvasVisible || run.loadingVisible) failures.push(`${run.label}: canvas did not reach ready presentation`);
  const runBudgetMsec = run.label === "cold" ? readyBudgetMsec : warmReadyBudgetMsec;
  if (runBudgetMsec > 0 && run.diagnosticReadyMsec > runBudgetMsec) {
    failures.push(`${run.label}: ${run.diagnosticReadyMsec}ms exceeds ${runBudgetMsec}ms budget`);
  }
}
if (failures.length > 0) throw new Error(failures.join("\n"));

console.log(JSON.stringify(report, null, 2));
