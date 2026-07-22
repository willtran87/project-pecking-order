import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3000/?build=difficulty-intake-audit";
const outputDirectory = path.resolve(process.argv[3] ?? "../output/web-game/difficulty-intake-audit");
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

async function clickAuthored(x, y) {
	const canvas = page.locator("canvas");
	const box = await canvas.boundingBox();
	assert.ok(box, "the Godot canvas must have visible bounds");
	await page.mouse.click(box.x + box.width * (x / 1280), box.y + box.height * (y / 720));
}

const evidence = { url, selections: [], activeContract: {}, errors };
try {
	await page.goto(url, { waitUntil: "domcontentloaded" });
	const standard = await waitForState(
		(snapshot) => snapshot.loaded === true
			&& snapshot.campaign_stage === "title"
			&& snapshot.campaign_intake_phase === "new_file"
			&& snapshot.selected_new_challenge_contract?.id === "standard_filing",
		"standard new-file intake",
		60_000,
	);
	assert.equal(standard.selected_new_challenge_contract.difficulty, "standard");
	evidence.selections.push({ id: "standard_filing", difficulty: "standard" });
	await page.screenshot({ path: path.join(outputDirectory, "difficulty-standard.png"), fullPage: true });

	await clickAuthored(800, 388);
	await page.keyboard.press("ArrowDown");
	await page.keyboard.press("Enter");
	const learning = await waitForState(
		(snapshot) => snapshot.selected_new_challenge_contract?.id === "supported_flock",
		"Learning difficulty selection",
	);
	assert.equal(learning.selected_new_challenge_contract.difficulty, "learning");
	evidence.selections.push({ id: "supported_flock", difficulty: "learning" });
	await page.screenshot({ path: path.join(outputDirectory, "difficulty-learning.png"), fullPage: true });

	await clickAuthored(800, 388);
	await page.keyboard.press("ArrowUp");
	await page.keyboard.press("Enter");
	const expert = await waitForState(
		(snapshot) => snapshot.selected_new_challenge_contract?.id === "executive_audit",
		"Expert difficulty selection",
	);
	assert.equal(expert.selected_new_challenge_contract.difficulty, "expert");
	evidence.selections.push({ id: "executive_audit", difficulty: "expert" });
	await page.keyboard.press("KeyT");
	await page.waitForTimeout(500);
	await page.screenshot({
		path: path.join(outputDirectory, "difficulty-expert-exact-terms.png"),
		fullPage: true,
	});
	await page.keyboard.press("KeyT");
	await page.waitForTimeout(300);

	await clickAuthored(640, 594);
	const active = await waitForState(
		(snapshot) => snapshot.campaign_stage === "active"
			&& snapshot.challenge_contract?.id === "executive_audit",
		"permanent Expert career activation",
		30_000,
	);
	assert.equal(active.challenge_contract.difficulty, "expert");
	assert.deepEqual(active.challenge_contract.criteria, {
		minimum_score: 65,
		minimum_welfare: 48,
		minimum_compliance: 65,
		minimum_farmer_favor: 53,
		maximum_crack_rate_basis_points: 2300,
	});
	evidence.activeContract = {
		id: active.challenge_contract.id,
		difficulty: active.challenge_contract.difficulty,
		criteria: active.challenge_contract.criteria,
	};
	await page.screenshot({ path: path.join(outputDirectory, "difficulty-expert-active.png"), fullPage: true });
} finally {
	await browser.close();
}

fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(evidence, null, 2));
assert.deepEqual(errors, [], "difficulty intake audit must produce no browser errors");
