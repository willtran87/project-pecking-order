import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3000/?build=touch-first-audit";
const outputDir = path.resolve(process.argv[3] ?? "../output/web-game/touch-first-audit");
fs.mkdirSync(outputDir, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const context = await browser.newContext({
  viewport: { width: 844, height: 390 },
  deviceScaleFactor: 2,
  hasTouch: true,
  isMobile: true,
});
const page = await context.newPage();
const cdp = await context.newCDPSession(page);
const errors = [];
const failures = [];

page.on("console", (message) => {
  if (message.type() === "error") errors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => errors.push(`page: ${String(error)}`));

const readState = () => page.evaluate(() => {
  if (typeof window.render_game_to_text !== "function") return {};
  return JSON.parse(window.render_game_to_text());
});

async function waitForState(predicate, label, timeoutMs = 25_000) {
  const deadline = Date.now() + timeoutMs;
  let state = {};
  while (Date.now() < deadline) {
    state = await readState();
    if (predicate(state)) return state;
    await page.waitForTimeout(250);
  }
  throw new Error(`${label} timed out; last stage ${state.campaign_stage ?? "unknown"}`);
}

async function canvasPoint(xRatio, yRatio) {
  const box = await page.locator("canvas").boundingBox();
  if (!box) throw new Error("Game canvas has no visible bounds.");
  return { x: box.x + box.width * xRatio, y: box.y + box.height * yRatio, box };
}

async function tapDockControl(label) {
	const point = await page.evaluate((targetLabel) => {
		const button = [...document.querySelectorAll(`.mobile-touch-controls button[aria-label="${targetLabel}"]`)]
			.find((candidate) => {
				const candidateRect = candidate.getBoundingClientRect();
				return candidateRect.width > 0 && candidateRect.height > 0;
			});
		if (!(button instanceof HTMLButtonElement)) return { x: 0, y: 0, hit: "" };
		button.scrollIntoView({ block: "nearest", inline: "nearest" });
		const rect = button.getBoundingClientRect();
		const x = rect.left + rect.width * 0.5;
		const y = rect.top + rect.height * 0.5;
		return {
			x,
			y,
			hit: document.elementFromPoint(x, y)?.getAttribute("aria-label") ?? "",
		};
	}, label);
	if (point.hit !== label) throw new Error(`${label} is not the topmost touch target at ${point.x},${point.y}; hit ${point.hit || "none"}`);
	await page.touchscreen.tap(point.x, point.y);
}

async function dragTouch(from, to, steps = 5) {
  await cdp.send("Input.dispatchTouchEvent", {
    type: "touchStart",
    touchPoints: [{ id: 0, x: from.x, y: from.y, radiusX: 2, radiusY: 2 }],
  });
  for (let step = 1; step <= steps; step += 1) {
    const ratio = step / steps;
    await cdp.send("Input.dispatchTouchEvent", {
      type: "touchMove",
      touchPoints: [{
        id: 0,
        x: from.x + (to.x - from.x) * ratio,
        y: from.y + (to.y - from.y) * ratio,
        radiusX: 2,
        radiusY: 2,
      }],
    });
    await page.waitForTimeout(35);
  }
  await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
}

async function layoutSnapshot(name) {
  const snapshot = await page.evaluate((snapshotName) => {
    const canvas = document.querySelector("canvas");
    const dock = document.querySelector(".mobile-touch-controls");
    const handbook = document.querySelector(".handbook");
    const buttons = [...document.querySelectorAll(".mobile-touch-controls button")];
    const rect = canvas?.getBoundingClientRect();
    return {
      name: snapshotName,
      viewport: { width: window.innerWidth, height: window.innerHeight },
      horizontalOverflow: document.documentElement.scrollWidth > document.documentElement.clientWidth,
      playMode: document.querySelector("main")?.getAttribute("data-play-mode") ?? "",
      canvas: rect ? { width: rect.width, height: rect.height, x: rect.x, y: rect.y } : null,
      dockDisplay: dock ? getComputedStyle(dock).display : "missing",
      handbookDisplay: handbook ? getComputedStyle(handbook).display : "missing",
      touchTargets: buttons.map((button) => {
        const buttonRect = button.getBoundingClientRect();
        return { label: button.textContent?.trim() ?? "", width: buttonRect.width, height: buttonRect.height };
      }),
    };
  }, name);
  await page.screenshot({ path: path.join(outputDir, `${name}.png`), fullPage: true });
  return snapshot;
}

const evidence = { url, layouts: [], gestures: {}, panels: {} };
try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitForState((state) => state.loaded === true || state.campaign_stage === "title", "Godot title boot", 45_000);
  const start = await canvasPoint(0.5, 594 / 720);
  await page.touchscreen.tap(start.x, start.y);
  await waitForState((state) => state.campaign_stage === "active", "touch New Campaign", 25_000);
  await page.waitForFunction(() => document.querySelector("main")?.getAttribute("data-play-mode") === "focused");

  evidence.layouts.push(await layoutSnapshot("landscape-office"));
  const beforePan = await readState();
  const panStart = await canvasPoint(0.72, 0.72);
  await dragTouch(panStart, { x: panStart.x - Math.min(120, panStart.box.width * 0.22), y: panStart.y - 18 });
  const afterPan = await waitForState(
    (state) => state.camera?.view_target !== beforePan.camera?.view_target,
    "one-finger camera pan",
  );
  evidence.gestures.pan = {
    before: beforePan.camera?.view_target,
    after: afterPan.camera?.view_target,
  };

	const beforeZoom = await readState();
	await tapDockControl("Zoom office in");
	const afterZoom = await waitForState(
		(state) => Number(state.camera?.desired_size) < Number(beforeZoom.camera?.desired_size) - 0.05,
		"touch zoom control",
	);
	evidence.gestures.zoomControl = {
		before: beforeZoom.camera?.desired_size,
		after: afterZoom.camera?.desired_size,
	};

  await tapDockControl("Open or close Flockwatch");
  const flockwatch = await waitForState((state) => state.flockwatch?.visible === true, "touch Flockwatch open");
  evidence.panels.flockwatch = { visible: true, cameraInput: flockwatch.camera?.input_enabled };
  await page.screenshot({ path: path.join(outputDir, "landscape-flockwatch.png"), fullPage: true });
  await tapDockControl("Open or close Flockwatch");
  await waitForState((state) => state.flockwatch?.visible === false, "touch Flockwatch close");

  await tapDockControl("Open Coop Settings and Controls");
  const settings = await waitForState((state) => state.settings?.visible === true, "touch Settings open");
  evidence.panels.settings = { visible: true, cameraInput: settings.camera?.input_enabled };
  await page.screenshot({ path: path.join(outputDir, "landscape-settings.png"), fullPage: true });
  await tapDockControl("Return to office overview");
  await waitForState((state) => state.settings?.visible === false, "touch Settings close");

  await page.setViewportSize({ width: 390, height: 844 });
  await page.evaluate(() => window.dispatchEvent(new Event("orientationchange")));
  await page.waitForTimeout(750);
  evidence.layouts.push(await layoutSnapshot("portrait-office"));

  for (const layout of evidence.layouts) {
    if (layout.horizontalOverflow) failures.push(`${layout.name}: horizontal overflow`);
    if (layout.playMode !== "focused") failures.push(`${layout.name}: focused play is not active`);
    if (layout.dockDisplay === "none" || layout.dockDisplay === "missing") failures.push(`${layout.name}: touch dock is hidden`);
    if (layout.handbookDisplay !== "none") failures.push(`${layout.name}: handbook remains visible during focused play`);
    for (const target of layout.touchTargets) {
      if (target.height < 40 || target.width < 44) failures.push(`${layout.name}: ${target.label} target is ${target.width}x${target.height}`);
    }
  }
  const landscape = evidence.layouts.find((layout) => layout.name === "landscape-office");
  if (!landscape?.canvas || landscape.canvas.height < 285) failures.push("landscape canvas is still vertically constrained");
  if (evidence.panels.flockwatch.cameraInput !== false) failures.push("camera input remained active behind Flockwatch");
  if (evidence.panels.settings.cameraInput !== false) failures.push("camera input remained active behind Settings");
} catch (error) {
  failures.push(error instanceof Error ? error.message : String(error));
} finally {
  failures.push(...errors);
  fs.writeFileSync(path.join(outputDir, "audit.json"), JSON.stringify({ evidence, errors, failures }, null, 2));
  await browser.close();
}

if (failures.length > 0) throw new Error(`Touch-first audit failed:\n${failures.join("\n")}`);
