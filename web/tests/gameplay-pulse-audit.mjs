import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const url = process.argv[2] ?? "http://localhost:3001/?build=gameplay-pulse-audit";
const outputDirectory = path.resolve(process.argv[3] ?? "../output/web-game/gameplay-pulse-audit");
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

async function waitForState(predicate, label, timeoutMsec = 60_000) {
	const deadline = Date.now() + timeoutMsec;
	let latest = {};
	while (Date.now() < deadline) {
		latest = await state();
		if (predicate(latest)) return latest;
		await page.waitForTimeout(100);
	}
	throw new Error(`${label} timed out; latest=${JSON.stringify(latest.gameplay_pulse ?? {})}`);
}

async function clickAuthored(x, y) {
	const canvas = page.locator("canvas");
	const box = await canvas.boundingBox();
	assert.ok(box, "the Godot canvas must have visible bounds");
	await page.mouse.click(box.x + box.width * (x / 1280), box.y + box.height * (y / 720));
}

const evidence = { url, title: {}, active: {}, errors };
try {
	await page.goto(url, { waitUntil: "domcontentloaded" });
	const title = await waitForState(
		(snapshot) => snapshot.loaded === true && snapshot.campaign_stage === "title",
		"title boot",
	);
	assert.equal(title.campaign_intake_phase, "quick_start");
	assert.equal(title.selected_new_challenge_contract?.id, "standard_filing");
	evidence.title = {
		stage: title.campaign_stage,
		intakePhase: title.campaign_intake_phase,
		defaultContract: title.selected_new_challenge_contract?.id,
	};
	await page.screenshot({ path: path.join(outputDirectory, "quick-start.png"), fullPage: true });
	await page.keyboard.press("KeyN");
	await waitForState((snapshot) => snapshot.campaign_stage === "active", "new file activation");
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
			"optional coach skip action",
		);
		const skipRect = active.first_clutch.skip_button_rect;
		await clickAuthored(skipRect.x + skipRect.width / 2, skipRect.y + skipRect.height / 2);
		active = await waitForState(
			(snapshot) => snapshot.first_clutch?.visible !== true && snapshot.shift_phase === 1,
			"optional coach dismissal",
		);
	}
	await page.waitForTimeout(1_000);
	for (let index = 0; index < 4; index += 1) {
		active = await state();
		if (active.character_dialogue?.visible !== true) break;
		await page.keyboard.press("Enter");
		await page.waitForTimeout(350);
	}

	active = await waitForState(
		(snapshot) => snapshot.shift_phase === 1
			&& snapshot.gameplay_pulse?.shift_journey?.steps?.length === 4
			&& snapshot.gameplay_pulse?.guided_loop?.item_count === 24,
		"gameplay clarity pulse",
	);
	const pulse = active.gameplay_pulse;
	const required = [
		"focus_mode", "action_preview", "core_loop", "shift_journey", "guided_loop", "physical_loop", "immediate_outcome", "shift_win",
		"review_highlights", "comeback_guidance", "combo_readiness", "hen_intention",
		"relationship_episode", "tangible_reward_choice", "rival_pulse", "golden_moment",
		"quick_docket", "hen_mastery", "fail_forward", "voluntary_streak",
		"adaptive_assistance", "celebration_hierarchy", "comprehension_tuning",
	];
	for (const key of required) assert.ok(Object.hasOwn(pulse, key), `missing pulse item: ${key}`);
	const rewardItems = [
		"signature_ability", "combo_recipe", "optional_shift_contract", "clutch_carton",
		"hen_promise", "rival_counterplay", "route_chain_plan", "near_miss_rescue",
		"furnishing_loadout", "future_reward_ghost", "three_beat_finale",
		"strategy_identity", "relationship_teamwork", "surprise_opportunity",
		"office_celebration",
	];
	for (const key of rewardItems) assert.ok(Object.hasOwn(pulse.reward_loop, key), `missing reward-loop item: ${key}`);
	assert.equal(Object.keys(pulse.reward_loop).length, 16, "reward loop should contain fifteen projections plus its authority flag");
	assert.equal(pulse.reward_loop.authoritative, true);
	assert.equal(pulse.reward_loop.optional_shift_contract.failure_penalty, 0);
	assert.deepEqual(pulse.reward_loop.clutch_carton.thresholds, [2, 4, 8]);
	assert.equal(pulse.reward_loop.three_beat_finale.beats.length, 3);
	assert.equal(pulse.authoritative, false);
	assert.equal(pulse.active_playbook.authoritative, true);
	assert.equal(pulse.active_playbook.shift_plan.length, 3);
	assert.equal(pulse.active_playbook.shift_journey.length, 4);
	assert.ok(pulse.active_playbook.options.length >= 5 && pulse.active_playbook.options.length <= 6, "the compact playbook should expose three guided plans plus only contextual play actions");
	assert.ok(pulse.active_playbook.options.every((option) => option.gain && option.cost && option.risk), "every playbook action should disclose gain, cost, and risk");
	assert.deepEqual(pulse.active_playbook.options.filter((option) => option.kind === "preset").map((option) => option.id), ["fast", "safe", "flock"]);
	assert.equal(pulse.active_playbook.recommended_preset_id, "fast", "the opening harvest directive should recommend the Fast plan");
	assert.equal(pulse.core_loop.compact, "FILE → HEN → EGG → CREDIT");
	assert.deepEqual(pulse.core_loop.steps.map((step) => step.id), ["file", "hen", "egg", "credit"]);
	assert.equal(pulse.shift_journey.compact, "PLAN → WORK → RESPOND → REWARD");
	assert.deepEqual(pulse.shift_journey.steps.map((step) => step.id), ["plan", "work", "respond", "reward"]);
	assert.equal(pulse.guided_loop.item_count, 24);
	assert.equal(pulse.physical_loop.item_count, 24);
	assert.equal(pulse.physical_loop.resolved_count, 24);
	assert.equal(pulse.physical_loop.all_resolved, true);
	const physicalLoopKeys = [
		"quick_start", "direct_world_routing", "contextual_actions", "attention_focus",
		"world_consequence_preview", "priority_peck_skill", "agency_cadence",
		"tangible_reward_ceremony", "strategy_transformation", "character_reactions",
		"relationship_moves", "incident_staging", "breakroom_recovery", "surprise_files",
		"expressive_hens", "transformative_upgrades", "five_shift_journey", "shift_highlight",
		"failure_adjustment", "collection_cabinet", "campaign_builds", "challenge_files",
		"personal_records", "next_shift_preview",
	];
	assert.deepEqual(Object.keys(pulse.physical_loop.items).toSorted(), physicalLoopKeys.toSorted());
	assert.deepEqual(pulse.guided_loop.core_vocabulary.verbs, ["INSPECT", "ROUTE", "HELP", "PECK", "INVEST"]);
	assert.equal(pulse.guided_loop.strategy_presets.recommended, "fast");
	assert.equal(pulse.guided_loop.strategy_presets.one_click_atomic, true);
	assert.equal(pulse.guided_loop.one_action_one_target.world_outline, true);
	assert.deepEqual(pulse.guided_loop.short_session_contract, {
		minimum_minutes: 8,
		maximum_minutes: 12,
		complete_arc: ["PLAN", "ACTION", "CONSEQUENCE", "REWARD"],
		next_moment_supported: true,
	});
	assert.equal(pulse.rival_pulse.hud_visible, false, "rival beat should stay quiet before the first egg");
	assert.equal(pulse.adaptive_assistance.changes_difficulty, false);
	assert.equal(pulse.comprehension_tuning.privacy, "LOCAL SESSION ONLY / NEVER TRANSMITTED");
	evidence.active = {
		stage: active.campaign_stage,
		itemCount: required.length,
		coreLoop: pulse.core_loop,
		actionPreview: pulse.action_preview,
		rivalPulse: pulse.rival_pulse,
		henMastery: pulse.hen_mastery,
		rewardLoop: pulse.reward_loop,
		shiftJourney: pulse.shift_journey,
		guidedLoop: pulse.guided_loop,
		physicalLoop: pulse.physical_loop,
		activePlaybook: pulse.active_playbook,
		privacy: pulse.comprehension_tuning.privacy,
	};
	await page.screenshot({ path: path.join(outputDirectory, "clarity-pulse.png"), fullPage: true });
	await clickAuthored(825, 65);
	await page.waitForTimeout(500);
	await page.screenshot({ path: path.join(outputDirectory, "active-playbook-menu.png"), fullPage: true });
} finally {
	await browser.close();
}

fs.writeFileSync(path.join(outputDirectory, "audit.json"), JSON.stringify(evidence, null, 2));
assert.deepEqual(errors, [], "clarity pulse audit must produce no browser errors");
console.log("GAMEPLAY_PULSE_AUDIT_PASSED quick-start=recommended items=20 reward-loop=15 guided-loop=24 physical-loop=24 presets=3 journey=4-stage playbook=authoritative rival=quiet-before-first-egg privacy=local");
