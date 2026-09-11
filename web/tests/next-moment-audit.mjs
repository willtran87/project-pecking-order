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
	await page.mouse.click(box.x + box.width * (x / 1280), box.y + box.height * (y / 720));
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

	// Use the shipped keyboard-only first-run route so wrapper scaling cannot
	// distort the audit. Enter retires the briefing; 1 + Enter files the opening
	// directive and releases the live management clock.
	await page.keyboard.press("KeyN");
	await waitForState((snapshot) => snapshot.campaign_stage === "active", "new career activation");
	await page.keyboard.press("Enter");
	await page.waitForTimeout(500);
	await page.keyboard.press("Digit1");
	await page.keyboard.press("Enter");
	let active = await waitForState(
		(snapshot) => snapshot.pending_decision_kind === "" && snapshot.shift_phase === 1,
		"live first shift",
	);
	if (active.first_clutch?.visible === true) {
		active = await waitForState(
			(snapshot) => snapshot.first_clutch?.visible === true
				&& snapshot.first_clutch?.can_skip === true
				&& snapshot.first_clutch?.skip_button_rect?.width > 0,
			"optional coach Skip action",
		);
		const skipRect = active.first_clutch.skip_button_rect;
		await clickAuthored(skipRect.x + skipRect.width / 2, skipRect.y + skipRect.height / 2);
		active = await waitForState(
			(snapshot) => snapshot.first_clutch?.visible !== true && snapshot.shift_phase === 1,
			"optional coach dismissal",
		);
	}
	// The opening policy can immediately queue one character aside after the
	// coach retires. File it away before auditing the live clock control.
	await page.waitForTimeout(1_500);
	active = await state();
	if (active.character_dialogue?.visible === true) {
		active = await dismissCharacterDialogue("opening character aside dismissal");
	}
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
	await page.screenshot({ path: path.join(outputDirectory, "live-shift.png"), fullPage: true });

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

	// Exercise the worker-specific smart handoff before the authored 11:00
	// incident can legitimately become the next management stop. This uses the
	// same deterministic first-arrival subject as the dedicated timing audit.
	await page.keyboard.press("Escape");
	await page.keyboard.press("Tab");
	await waitForState(
		(snapshot) => snapshot.focused_worker_id >= 0,
		"live hen focus",
	);
	for (let cycle = 0; cycle < 12; cycle += 1) {
		const focused = await state();
		if (focused.focused_worker_id === 0) break;
		await page.evaluate(() => window.__pecking_order_mobile_action?.("cycle_hen"));
		await waitForState(
			(snapshot) => snapshot.focused_worker_id !== focused.focused_worker_id,
			"next hen focus",
			5_000,
		);
	}
	assert.equal((await state()).focused_worker_id, 0);
	await page.keyboard.press("Digit1");
	await waitForState(
		(snapshot) => snapshot.production?.focused_claim?.id > 0
			&& snapshot.production?.focused_peck_assist?.window_state === "not_ready",
		"focused hen real file",
		90_000,
	);
	await page.keyboard.press("Digit4");
	const automaticStop = await waitForState(
		(snapshot) => snapshot.next_moment?.active === false
			&& snapshot.next_moment?.target === "priority_peck"
			&& snapshot.clock_speed_index === 0
			&& snapshot.priority_peck_focus?.worker_id >= 0
			&& snapshot.camera?.focused_worker_id === snapshot.priority_peck_focus?.worker_id,
		"automatic Priority Peck camera handoff",
		30_000,
	);
	assert.equal(automaticStop.next_moment?.target, "priority_peck");
	assert.equal(automaticStop.camera?.focused_worker_id, automaticStop.priority_peck_focus?.worker_id);
	evidence.automaticStop = {
		clockSpeedIndex: automaticStop.clock_speed_index,
		nextMoment: automaticStop.next_moment,
		focusedWorkerId: automaticStop.camera.focused_worker_id,
		priorityPeckWorkerId: automaticStop.priority_peck_focus.worker_id,
	};
	await page.screenshot({ path: path.join(outputDirectory, "next-moment-arrived.png"), fullPage: true });
} finally {
	await browser.close();
}

fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(evidence, null, 2));
assert.deepEqual(errors, [], "Next Moment audit must produce no browser errors");
