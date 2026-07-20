import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3000/?build=color-vision-audit";
const outputDirectory = path.resolve(
	process.argv[3] ?? "../output/web-game/color-vision-audit",
);
fs.mkdirSync(outputDirectory, { recursive: true });

const browser = await chromium.launch({
	headless: true,
	args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
const page = await context.newPage();
const errors = [];
page.on("console", (message) => {
	if (message.type() === "error") errors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => errors.push(`page: ${String(error)}`));

const state = () => page.evaluate(() => {
	if (typeof window.render_game_to_text !== "function") return {};
	return JSON.parse(window.render_game_to_text());
});

async function waitForState(predicate, label, timeoutMsec = 45_000) {
	const deadline = Date.now() + timeoutMsec;
	let latest = {};
	while (Date.now() < deadline) {
		latest = await state();
		if (predicate(latest)) return latest;
		await page.waitForTimeout(250);
	}
	throw new Error(`${label} timed out; latest=${JSON.stringify(latest)}`);
}

async function startActiveCareer() {
	await waitForState(
		(snapshot) => snapshot.loaded === true || snapshot.campaign_stage === "title",
		"Godot title boot",
	);
	const canvas = page.locator("canvas");
	let box = await canvas.boundingBox();
	assert.ok(box, "the Godot canvas must have visible bounds");
	await page.mouse.click(box.x + box.width * 0.5, box.y + box.height * (594 / 720));
	await waitForState(
		(snapshot) => snapshot.campaign_stage === "active",
		"new campaign activation",
		30_000,
	);
	box = await canvas.boundingBox();
	assert.ok(box, "focused play must retain a visible canvas");
	await page.keyboard.press("Enter");
	await page.waitForTimeout(500);
	await page.keyboard.press("Digit1");
	await page.keyboard.press("Enter");
	await waitForState(
		(snapshot) => snapshot.shift_phase === 1 && snapshot.pending_decision_kind === "",
		"morning briefing authorization",
		20_000,
	);
	const opening = await state();
	if (opening.first_clutch?.visible === true) {
		// React enters focused play just after the campaign diagnostic changes. The
		// stage grows at that boundary, so use fresh CSS bounds for the authored UI.
		box = await canvas.boundingBox();
		assert.ok(box, "focused First Clutch must retain visible canvas bounds");
		await page.mouse.click(
			box.x + box.width * (557 / 1280),
			box.y + box.height * (168 / 720),
		);
		await waitForState(
			(snapshot) => snapshot.first_clutch?.visible === false,
			"optional coach retirement",
			15_000,
		);
	}
	await canvas.click({ position: { x: 8, y: 8 } });
	return { canvas, box };
}

const evidence = { url, setting: {}, persistence: {}, errors };
try {
	await page.goto(url, { waitUntil: "domcontentloaded" });
	console.log("color-vision audit: wrapper loaded");
	await startActiveCareer();
	console.log("color-vision audit: active floor ready");
	await page.keyboard.press("F10");
	const opened = await waitForState(
		(snapshot) => snapshot.settings?.visible === true,
		"Settings open",
	);
	assert.equal(opened.settings.color_vision_mode, "standard");
	console.log("color-vision audit: Settings opened with standard palette");

	// Close receives initial focus. Eight audio controls precede Motion, Scale,
	// Detail, Timing, and then the Color Vision selector.
	for (let index = 0; index < 13; index += 1) await page.keyboard.press("Tab");
	await page.screenshot({
		path: path.join(outputDirectory, "color-vision-selector-standard.png"),
		fullPage: true,
	});
	await page.keyboard.press("Enter");
	await page.keyboard.press("ArrowDown");
	await page.keyboard.press("Enter");
	const safe = await waitForState(
		(snapshot) => snapshot.settings?.color_vision_mode === "color_blind_safe"
			&& snapshot.settings?.browser_mirror_status === "saved",
		"color-blind-safe preference application",
	);
	assert.match(safe.settings.accessible_text, /color vision color blind safe/i);
	evidence.setting = {
		before: opened.settings.color_vision_mode,
		after: safe.settings.color_vision_mode,
		accessibleText: safe.settings.accessible_text,
	};
	console.log("color-vision audit: safe palette saved to browser mirror");
	await page.screenshot({
		path: path.join(outputDirectory, "color-vision-selector-safe.png"),
		fullPage: true,
	});

	await page.keyboard.press("F10");
	await waitForState(
		(snapshot) => snapshot.settings?.visible === false,
		"return to safe-palette floor",
	);
	await page.waitForTimeout(750);
	await page.screenshot({
		path: path.join(outputDirectory, "safe-palette-active-floor.png"),
		fullPage: true,
	});

	await page.reload({ waitUntil: "domcontentloaded" });
	console.log("color-vision audit: immediate reload requested");
	const restored = await waitForState(
		(snapshot) => snapshot.loaded === true
			&& snapshot.settings?.color_vision_mode === "color_blind_safe"
			&& snapshot.settings?.browser_mirror_status === "loaded",
		"preference restoration after reload",
		60_000,
	);
	evidence.persistence = {
		reloaded: true,
		mode: restored.settings.color_vision_mode,
		browserMirrorStatus: restored.settings.browser_mirror_status,
		campaignStage: restored.campaign_stage,
	};
	console.log("color-vision audit: safe palette restored from browser mirror");
	await page.screenshot({
		path: path.join(outputDirectory, "safe-palette-restored-title.png"),
		fullPage: true,
	});
} finally {
	await browser.close();
}

fs.writeFileSync(
	path.join(outputDirectory, "audit.json"),
	JSON.stringify(evidence, null, 2),
);
assert.deepEqual(errors, [], "color-vision audit must produce no browser errors");
