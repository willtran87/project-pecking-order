import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://127.0.0.1:3027/?build=shift-clock-play";
const output = path.resolve(process.argv[3] ?? "../output/web-game/shift-clock-play");
fs.mkdirSync(output, { recursive: true });

const browser = await chromium.launch({
	headless: true,
	args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const page = await browser.newPage({ viewport: { width: Number(process.env.PECK_AUDIT_WIDTH ?? 1440), height: Number(process.env.PECK_AUDIT_HEIGHT ?? 900) } });
const errors = [];
const evidence = { errors, moments: {} };
page.on("pageerror", error => errors.push(String(error)));
page.on("console", message => {
	if (message.type() === "error") errors.push(message.text());
});

const state = () => page.evaluate(() => JSON.parse(window.render_game_to_text?.() ?? "{}"));
async function waitFor(predicate, label, timeout = 60000) {
	const deadline = Date.now() + timeout;
	let latest;
	while (Date.now() < deadline) {
		latest = await state();
		if (predicate(latest)) return latest;
		await page.waitForTimeout(125);
	}
	throw new Error(`${label}: ${JSON.stringify({
		stage: latest?.first_clutch?.stage,
		clock: latest?.time_label,
		eggs: latest?.eggs_today,
		objective: latest?.shift_objective?.accessible_text,
		speed: latest?.clock_speed_index,
		pause: latest?.pause_context?.owner_id,
		decision: latest?.pending_decision_kind,
		nextMoment: latest?.next_moment,
	})}`);
}
async function clickPrimary(label) {
	const snapshot = await waitFor(s => s.first_clutch?.primary_button?.visible
		&& s.first_clutch.primary_button.label === label, label);
	const rect = snapshot.first_clutch.primary_button.rect;
	const canvas = await page.locator("canvas").boundingBox();
	assert.ok(canvas && rect.width > 0 && rect.height > 0);
	const scale = Math.min(canvas.width / 1280, canvas.height / 720);
	await page.mouse.click(
		canvas.x + (canvas.width - 1280 * scale) / 2 + (rect.x + rect.width / 2) * scale,
		canvas.y + (canvas.height - 720 * scale) / 2 + (rect.y + rect.height / 2) * scale,
	);
}
function clockEvidence(snapshot) {
	return {
		day: snapshot.shift_status?.day_text,
		time: snapshot.shift_status?.time_text,
		authoritativeTime: snapshot.time_label,
		minute: snapshot.minute_of_day,
		selectedSpeed: snapshot.clock_speed_index,
		effectiveSpeed: snapshot.clock_effective_multiplier,
		pauseOwner: snapshot.pause_context?.owner_id,
		workProgress: snapshot.production?.focused_progress,
		firstClutchStage: snapshot.first_clutch?.stage,
	};
}

async function checkHud(snapshot) {
	const canvas = await page.locator("canvas").boundingBox();
	const layout = snapshot.shift_status?.layout;
	assert.ok(canvas && layout, "live HUD exposes actual layout bounds");
	const ratio = Math.min(canvas.width / 1280, canvas.height / 720);
	for (const name of ["SpeedButton_0", "CompactSpeedMenu", "NextMomentButton", "OpenSettingsButton", "ActivePlaybookButton"]) {
		const control = layout.controls[name];
		if (!control?.visible) continue;
		assert.ok(control.rect.x >= 0 && control.rect.x + control.rect.width <= 1281, `${name} fits the stage`);
		if (layout.compact) assert.ok(control.rect.height * ratio >= 43.5, `${name} has a 44 CSS-pixel target`);
	}
	return { viewport: page.viewportSize(), canvas, layout };
}

try {
	await page.goto(url, { waitUntil: "domcontentloaded" });
	await waitFor(s => s.loaded && s.campaign_stage === "title", "title boot");
	await page.keyboard.press("KeyN");
	await waitFor(s => s.campaign_stage === "active", "new career");
	for (let index = 0; index < 4; index++) await page.keyboard.press("Tab");
	await page.keyboard.press("Enter");
	await page.waitForTimeout(500);
	await page.keyboard.press("Digit3");
	await page.keyboard.press("Enter");
	await waitFor(s => s.first_clutch?.stage === "specialty_route", "route lesson");
	for (let index = 0; index < 4; index++) {
		const current = await state();
		if (!current.character_dialogue?.visible || current.character_dialogue?.suspended) break;
		await page.keyboard.press("Enter");
		await page.waitForTimeout(350);
	}
	await clickPrimary("ROUTE & START");
	const running = await waitFor(s => s.first_clutch?.stage === "delivery"
		&& s.clock_speed_index === 1 && s.minute_of_day >= 482, "first work beat");
	assert.equal(running.routing_lifecycle?.header_copy, "WORKS ON HER OWN");
	assert.equal(running.routing_lifecycle?.route_hint_copy, "NO EXTRA CLICKS  ·  NEXT: EGG");
	evidence.moments.running = clockEvidence(running);
	await page.screenshot({ path: path.join(output, "01-running.png"), fullPage: true });

	await page.keyboard.press("Space");
	const paused = await waitFor(s => s.clock_speed_index === 0
		&& s.pause_context?.owner_id === "player", "player pause");
	assert.equal(paused.shift_status?.time_text, paused.time_label, "pausing must show the authoritative clock time");
	assert.equal(paused.first_clutch?.primary_button?.label, "RESUME SHIFT", "a paused in-progress file must offer resume rather than start again");
	evidence.moments.paused = clockEvidence(paused);
	evidence.openingHud = await checkHud(paused);
	await page.waitForTimeout(1200);
	const held = await state();
	assert.equal(held.minute_of_day, paused.minute_of_day, "pause must hold game time");
	assert.equal(held.production?.focused_progress, paused.production?.focused_progress, "pause must hold hen work");
	assert.equal(held.shift_status?.time_text, paused.shift_status?.time_text, "pause must retain the visible clock");
	assert.match(held.shift_status?.clock_accessible_text ?? "", /Pause owner: Player/);
	evidence.moments.held = clockEvidence(held);
	await page.screenshot({ path: path.join(output, "02-paused.png"), fullPage: true });

	await page.keyboard.press("Space");
	await waitFor(s => s.clock_speed_index === 1, "resume 1x");
	await page.keyboard.press("Digit2");
	const fast = await waitFor(s => s.clock_speed_index === 2
		&& (s.clock_effective_multiplier === 3
			|| (s.clock_effective_multiplier === 1 && s.priority_peck_focus?.limiting)), "3x requested pace or explained precision hold");
	evidence.moments.fast = clockEvidence(fast);
	await page.keyboard.press("Digit4");
	const seeking = await waitFor(s => (
		s.next_moment?.active === true && s.clock_speed_index === 3
	) || s.first_clutch?.reinvestment?.modal_visible === true
		|| (s.clock_speed_index === 0 && /PECK/i.test(s.next_moment?.stop_reason ?? "")), "Next Moment seek or automatic stop");
	evidence.moments.seeking = {
		...clockEvidence(seeking),
		automaticStopBeforeSample: seeking.first_clutch?.reinvestment?.modal_visible === true,
	};
	await page.screenshot({ path: path.join(output, "03-seeking.png"), fullPage: true });

	let reward = await waitFor(s => (s.first_clutch?.stage === "reinvestment"
		&& s.first_clutch?.reinvestment?.modal_visible)
		|| (s.clock_speed_index === 0 && /PECK/i.test(s.next_moment?.stop_reason ?? "")), "physical egg or optional peck stop", 300000);
	if (!reward.first_clutch?.reinvestment?.modal_visible) {
		assert.equal(reward.pause_context?.owner_id, "next_moment");
		evidence.moments.optionalStop = { ...clockEvidence(reward), reason: reward.next_moment.stop_reason };
		await page.keyboard.press("Digit1");
		reward = await waitFor(s => s.first_clutch?.stage === "reinvestment"
			&& s.first_clutch?.reinvestment?.modal_visible, "autonomous delivery without optional peck", 300000);
	}
	assert.equal(reward.clock_effective_multiplier, 0, "the reward decision must hold the clock");
	assert.equal(reward.shift_status?.time_text, reward.time_label, "HUD and authority must show the same time");
	evidence.moments.reward = clockEvidence(reward);
	await page.screenshot({ path: path.join(output, "04-reward.png"), fullPage: true });
	await page.keyboard.press("Digit1");
	await page.keyboard.press("Enter");
	const filed = await waitFor(s => s.first_clutch?.reinvestment?.modal_visible !== true
		&& s.pending_decision_kind === "", "first reward filed");
	evidence.moments.filed = clockEvidence(filed);
	await page.screenshot({ path: path.join(output, "05-filed.png"), fullPage: true });
	const overview = await waitFor(s => s.camera?.mode === "home", "installation focus returns to office", 10000);
	evidence.moments.overview = { ...clockEvidence(overview), cameraMode: overview.camera.mode };
	evidence.normalHud = await checkHud(overview);
	await page.screenshot({ path: path.join(output, "05b-overview.png"), fullPage: true });
	const settled = await waitFor(s => s.eggs_today >= 1
		&& s.first_clutch?.stage === "complete"
		&& new RegExp(`${s.eggs_today} of (?:3|16) eggs laid`).test(s.shift_objective?.accessible_text ?? ""),
	"credited egg visible after reward", 15000);
	evidence.moments.settled = {
		...clockEvidence(settled),
		eggsToday: settled.eggs_today,
		quota: settled.quota_target,
		objective: settled.shift_objective?.accessible_text,
	};
	await page.screenshot({ path: path.join(output, "06-settled.png"), fullPage: true });
	await page.keyboard.press("Digit2");
	const thirdDeadline = Date.now() + 150000;
	let third = await state();
	while (Date.now() < thirdDeadline && third.eggs_today < 3) {
		if (third.pending_decision_kind) {
			await page.keyboard.press("Digit1");
			await page.keyboard.press("Enter");
			await page.waitForTimeout(450);
		} else if (third.character_dialogue?.visible && !third.character_dialogue?.suspended) {
			await page.keyboard.press("Enter");
		} else if (third.clock_speed_index === 0 && third.shift_phase === 1) {
			await page.keyboard.press("Digit2");
		} else {
			await page.waitForTimeout(200);
		}
		third = await state();
	}
	assert.ok(third.eggs_today >= 3, "the live shift should carry its opening clutch through three eggs");
	const handoff = await waitFor(s => s.eggs_today >= 3
		&& new RegExp(`QUOTA\\s*·\\s*${s.eggs_today}\\s*\\/\\s*${s.quota_target}`).test(s.shift_objective?.readout ?? "")
		&& /Shift quota:/.test(s.shift_objective?.accessible_text ?? ""),
	"opening clutch reveals the full shift quota", 10000);
	if (handoff.eggs_today === 3) {
		assert.match(handoff.shift_objective.accessible_text, /13 remaining/);
	}
	evidence.moments.thirdEgg = {
		...clockEvidence(handoff),
		eggsToday: handoff.eggs_today,
		readout: handoff.shift_objective?.readout,
		objective: handoff.shift_objective?.accessible_text,
		openingSlotsVisible: handoff.shift_objective?.opening_slots_visible,
		openingSlotsFilled: handoff.shift_objective?.opening_slots_filled,
	};
	await page.screenshot({ path: path.join(output, "07-third-egg.png"), fullPage: true });
	assert.deepEqual(errors, []);
	evidence.passed = true;
} catch (error) {
	evidence.failure = String(error);
	try {
		const finalState = await state();
		evidence.final = {
			...clockEvidence(finalState),
			eggsToday: finalState.eggs_today,
			objective: finalState.shift_objective?.accessible_text,
		};
		await page.screenshot({ path: path.join(output, "failure.png"), fullPage: true });
	} catch { /* preserve the primary failure */ }
	throw error;
} finally {
	fs.writeFileSync(path.join(output, "audit.json"), JSON.stringify(evidence, null, 2));
	await browser.close();
}
console.log("SHIFT_CLOCK_PLAY_AUDIT_PASSED pause=held paces=1x+3x+next-moment reward=filed third-egg=quota-handoff");
