import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3000/?build=camera-controls-audit";
const outputDirectory = path.resolve(
	process.argv[3] ?? "../output/web-game/camera-controls-audit",
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

async function holdKey(key, holdMsec = 650) {
	await page.keyboard.down(key);
	await page.waitForTimeout(holdMsec);
	await page.keyboard.up(key);
}

const evidence = { url, defaults: {}, remap: {}, camera: {} };
try {
	await page.goto(url, { waitUntil: "domcontentloaded" });
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
	assert.ok(box, "the focused-play canvas must retain visible bounds");
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
		await page.mouse.click(
			box.x + box.width * (557 / 1280),
			box.y + box.height * (168 / 720),
		);
		await waitForState(
			(snapshot) => snapshot.first_clutch?.visible === false,
			"optional First Clutch coach retirement",
			15_000,
		);
	}

	await canvas.click({ position: { x: 8, y: 8 } });
	await page.keyboard.press("F10");
	const openSettings = await waitForState(
		(snapshot) => snapshot.settings?.visible === true,
		"Settings open",
	);
	const bindings = openSettings.settings?.bindings ?? {};
	evidence.defaults = bindings;
	assert.equal(Object.keys(bindings).length, 17, "all semantic actions must be published");
	assert.equal(bindings.camera_pan_left, "A / Left");
	assert.equal(bindings.camera_pan_right, "D / Right");
	assert.equal(bindings.camera_zoom_in, "Equal / Kp Add");
	assert.equal(bindings.camera_zoom_out, "Minus / Kp Subtract");
	await page.screenshot({
		path: path.join(outputDirectory, "settings-defaults.png"),
		fullPage: true,
	});

	// Settings focuses its Close button. Twenty-six forward steps traverse the
	// eight audio controls, six comfort controls, two backup controls, the nine
	// existing floor actions, Pan Left, and finally Pan Right.
	for (let index = 0; index < 27; index += 1) await page.keyboard.press("Tab");
	await page.screenshot({
		path: path.join(outputDirectory, "settings-camera-bindings.png"),
		fullPage: true,
	});
	await page.keyboard.press("Enter");
	await page.keyboard.press("KeyJ");
	const rebound = await waitForState(
		(snapshot) => snapshot.settings?.bindings?.camera_pan_right === "J",
		"camera binding persistence acknowledgement",
	);
	evidence.remap = {
		action: "camera_pan_right",
		before: bindings.camera_pan_right,
		after: rebound.settings.bindings.camera_pan_right,
		status: rebound.settings.accessible_text,
	};
	assert.match(rebound.settings.accessible_text, /binding filed and saved/i);
	await page.mouse.move(box.x + box.width * 0.5, box.y + box.height * 0.72);
	await page.mouse.wheel(0, 4_000);
	await page.waitForTimeout(750);
	await page.screenshot({
		path: path.join(outputDirectory, "settings-camera-remapped.png"),
		fullPage: true,
	});

	await page.keyboard.press("F10");
	await waitForState(
		(snapshot) => snapshot.settings?.visible === false && snapshot.camera?.input_enabled === true,
		"return to live floor",
	);
	await page.keyboard.press("Escape");
	const overview = await waitForState(
		(snapshot) => snapshot.camera?.mode === "home",
		"authored office overview",
		10_000,
	);
	const initialTarget = overview.camera.view_target;
	await holdKey("KeyD");
	await page.waitForTimeout(750);
	const afterOldKey = await state();
	assert.equal(
		afterOldKey.camera?.view_target,
		initialTarget,
		"the replaced D binding must no longer pan the camera",
	);
	assert.equal(afterOldKey.camera?.mode, "home");
	await holdKey("KeyJ");
	const afterNewKey = await waitForState(
		(snapshot) => snapshot.camera?.mode === "free_overview",
		"rebound camera pan",
		10_000,
	);
	evidence.camera = {
		initialTarget,
		afterOldKey: afterOldKey.camera?.view_target,
		afterNewKey: afterNewKey.camera?.view_target,
		mode: afterNewKey.camera?.mode,
	};
	await page.screenshot({
		path: path.join(outputDirectory, "active-floor-after-remap.png"),
		fullPage: true,
	});
} finally {
	await browser.close();
}

evidence.errors = errors;
fs.writeFileSync(
	path.join(outputDirectory, "audit.json"),
	JSON.stringify(evidence, null, 2),
);
assert.deepEqual(errors, [], "camera-control audit must produce no browser errors");
