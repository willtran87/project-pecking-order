import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3000/?build=next-moment-audit";
const outputDirectory = path.resolve(process.argv[3] ?? "../output/web-game/next-moment-audit");
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
		await page.waitForTimeout(100);
	}
	throw new Error(`${label} timed out; latest=${JSON.stringify({
		stage: latest.campaign_stage,
		phase: latest.shift_phase,
		pending: latest.pending_decision_kind,
		dialogueVisible: latest.character_dialogue?.visible,
		pauseOwner: latest.pause_context?.owner_id,
		clockSpeedIndex: latest.clock_speed_index,
		nextMoment: latest.next_moment,
		camera: latest.camera,
		priorityPeck: latest.priority_peck_focus,
	})}`);
}

async function clickAuthored(x, y) {
	const canvas = page.locator("canvas");
	const box = await canvas.boundingBox();
	assert.ok(box, "the Godot canvas must have visible bounds");
	const scale = Math.min(box.width / 1280, box.height / 720);
	await page.mouse.click(box.x + (box.width - 1280 * scale) / 2 + x * scale, box.y + (box.height - 720 * scale) / 2 + y * scale);
}

async function dismissCharacterDialogue(label, timeoutMsec = 30_000) {
	const deadline = Date.now() + timeoutMsec;
	while (Date.now() < deadline) {
		const snapshot = await state();
		if (
			snapshot.character_dialogue?.visible !== true
			&& snapshot.pause_context?.owner_id !== "flock_message"
		) return snapshot;
		await page.keyboard.press("Enter");
		await page.waitForTimeout(350);
	}
	return waitForState(
		(snapshot) => snapshot.character_dialogue?.visible !== true
			&& snapshot.pause_context?.owner_id !== "flock_message",
		label,
		1,
	);
}

const evidence = { url, active: {}, seeking: {}, restored: {}, firstAutomaticStop: {}, automaticStop: {}, errors };
try {
	await page.goto(url, { waitUntil: "domcontentloaded" });
	await waitForState(
		(snapshot) => snapshot.loaded === true && snapshot.campaign_stage === "title",
		"title boot",
		60_000,
	);

	// Use the shipped route-first opening. Waiting for an unassigned hen to
	// acquire a file used to run into the incident before testing Next Moment.
	await page.keyboard.press("KeyN");
	await waitForState((snapshot) => snapshot.campaign_stage === "active", "new career activation");
	for (let index = 0; index < 4; index++) await page.keyboard.press("Tab");
	await page.keyboard.press("Enter");
	await page.waitForTimeout(500);
	await page.keyboard.press("Digit3");
	await page.keyboard.press("Enter");
	let active = await waitForState(
		(snapshot) => snapshot.first_clutch?.stage === "specialty_route",
		"first route lesson",
	);
	if (active.character_dialogue?.visible === true) {
		active = await dismissCharacterDialogue("opening character aside dismissal");
	}
	const route = active.first_clutch.primary_button;
	assert.equal(route.label, "ROUTE & START");
	await clickAuthored(route.rect.x + route.rect.width / 2, route.rect.y + route.rect.height / 2);
	active = await waitForState(s => s.first_clutch?.stage === "delivery" && s.minute_of_day >= 482, "routed autonomous work");
	assert.equal(active.next_moment?.button_text, "NEXT  [4]");
	assert.equal(active.next_moment?.binding, "4 / D-pad Up");
	assert.ok(active.next_moment?.target_label?.length > 0);
	assert.equal(active.next_moment?.camera_focus_on_stop, true);
	assert.equal(active.clutch_reward_ladder?.next_threshold, 2);
	assert.equal(active.clutch_reward_ladder?.next_label, "STEADY");
	assert.equal(active.clutch_reward_ladder?.current_bonus_cents, 0);
	evidence.active = {
		stage: active.campaign_stage,
		shiftPhase: active.shift_phase,
		clockSpeedIndex: active.clock_speed_index,
		nextMoment: active.next_moment,
		clutchRewardLadder: active.clutch_reward_ladder,
	};

	const priorSpeed = active.clock_speed_index > 0 ? active.clock_speed_index : 1;
	await page.keyboard.press("Digit4");
	const seeking = await waitForState(
		(snapshot) => snapshot.next_moment?.active === true && snapshot.clock_speed_index === 3,
		"Next Moment seek activation",
		5_000,
	);
	assert.match(seeking.next_moment.button_text, /^STOP/);
	evidence.seeking = {
		clockSpeedIndex: seeking.clock_speed_index,
		nextMoment: seeking.next_moment,
	};

	await page.keyboard.press("Digit4");
	const restored = await waitForState(
		(snapshot) => snapshot.next_moment?.active === false && snapshot.clock_speed_index === priorSpeed,
		"manual pace restoration",
		5_000,
	);
	assert.match(restored.next_moment.button_text, /^NEXT/);
	evidence.restored = {
		clockSpeedIndex: restored.clock_speed_index,
		nextMoment: restored.next_moment,
	};

	// The route lesson already focuses a hen with an authoritative active file.
	await page.keyboard.press("Digit4");
	const automaticStop = await waitForState(
		(snapshot) => snapshot.next_moment?.active === false
			&& snapshot.next_moment?.target === "priority_peck"
			&& snapshot.clock_speed_index === 0
			&& snapshot.priority_peck_focus?.worker_id >= 0
			&& snapshot.camera?.focused_worker_id === snapshot.priority_peck_focus?.worker_id,
		"automatic Priority Peck camera handoff",
		90_000,
	);
	assert.equal(automaticStop.next_moment?.target, "priority_peck");
	assert.equal(automaticStop.pause_context?.owner_id, "next_moment");
	assert.match(automaticStop.next_moment?.stop_reason ?? "", /PECK/);
	assert.equal(automaticStop.camera?.focused_worker_id, automaticStop.priority_peck_focus?.worker_id);
	evidence.automaticStop = {
		clockSpeedIndex: automaticStop.clock_speed_index,
		nextMoment: automaticStop.next_moment,
		focusedWorkerId: automaticStop.camera.focused_worker_id,
		priorityPeckWorkerId: automaticStop.priority_peck_focus.worker_id,
	};
	await page.screenshot({ path: path.join(outputDirectory, "next-moment-arrived.png"), fullPage: true });
	await page.waitForTimeout(1200);
	assert.equal((await state()).next_moment.stop_reason, automaticStop.next_moment.stop_reason, "stop reason persists after transient feedback");
	await page.keyboard.press("Digit1");
	await waitForState(s => s.clock_speed_index === 1 && s.next_moment.stop_reason === "", "explicit resume clears automatic stop");
} finally {
	await browser.close();
}

fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(evidence, null, 2));
assert.deepEqual(errors, [], "Next Moment audit must produce no browser errors");
