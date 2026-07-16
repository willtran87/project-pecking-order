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

const url = process.argv[2] ?? "http://localhost:3000/?build=checkpoint-persistence-audit";
const outputDir = path.resolve(process.argv[3] ?? "output/web-game/checkpoint-persistence-audit");
const profileDir = path.join(outputDir, `chromium-profile-${process.pid}-${Date.now()}`);
fs.mkdirSync(outputDir, { recursive: true });

const errors = [];
const launchOptions = {
	headless: true,
	viewport: { width: 1440, height: 900 },
	args: ["--use-gl=angle", "--use-angle=swiftshader"],
};

function observeErrors(page, phase) {
	page.on("console", (message) => {
		if (message.type() === "error") errors.push(`${phase} console: ${message.text()}`);
	});
	page.on("pageerror", (error) => errors.push(`${phase} page: ${String(error)}`));
}

async function gameState(page) {
	return page.evaluate(() => {
		if (typeof window.render_game_to_text !== "function") return {};
		try {
			return JSON.parse(window.render_game_to_text());
		} catch {
			return {};
		}
	});
}

async function waitForGame(page, condition, timeout = 60_000) {
	await page.waitForFunction(
		(name) => {
			if (typeof window.render_game_to_text !== "function") return false;
			try {
				const state = JSON.parse(window.render_game_to_text());
				switch (name) {
					case "loaded":
						return state.loaded === true;
					case "title":
						return state.campaign_stage === "title";
					case "active_with_saved_checkpoint":
						return state.campaign_stage === "active"
							&& state.checkpoint?.has_checkpoint === true
							&& state.checkpoint?.dirty === false;
					case "title_with_checkpoint_candidate":
						return state.campaign_stage === "title"
							&& state.checkpoint?.has_candidate === true
							&& state.checkpoint?.has_checkpoint === false;
					case "active":
						return state.campaign_stage === "active";
					default:
						return false;
				}
			} catch {
				return false;
			}
		},
		condition,
		{ timeout },
	);
}

async function focusGameAndPress(page, key) {
	const canvas = page.locator("#canvas");
	await canvas.waitFor({ state: "visible" });
	await canvas.click({ position: { x: 12, y: 12 } });
	await page.keyboard.press(key);
}

function authoritativeResumeState(state) {
	const firstClutch = state.first_clutch ?? {};
	const economy = state.economy ?? {};
	const production = state.production ?? {};
	return {
		campaign_day: state.campaign_day,
		campaign_score: state.campaign_score,
		first_clutch_stage: firstClutch.stage,
		first_clutch_target_worker_id: firstClutch.target_worker_id,
		first_clutch_visible: firstClutch.visible,
		feed_fund_cents: economy.feed_fund_cents,
		claims_waiting: production.claims_waiting,
		claims_outstanding: production.claims_outstanding,
	};
}

async function openAuditPage(context, phase) {
	const page = context.pages()[0] ?? await context.newPage();
	observeErrors(page, phase);
	await page.goto(url, { waitUntil: "domcontentloaded" });
	await waitForGame(page, "loaded");
	return page;
}

const firstContext = await chromium.launchPersistentContext(profileDir, launchOptions);
const firstPage = await openAuditPage(firstContext, "initial");
await waitForGame(firstPage, "title");
await focusGameAndPress(firstPage, "n");
await waitForGame(
	firstPage,
	"active_with_saved_checkpoint",
);
await firstPage.waitForTimeout(1_800);
const settledState = await gameState(firstPage);
const expectedResumeState = authoritativeResumeState(settledState);
const settledHeader = await firstPage.locator(".system-state").innerText();
await firstPage.screenshot({
	path: path.join(outputDir, "settled-before-browser-close.png"),
	fullPage: true,
});
await firstContext.close();

const secondContext = await chromium.launchPersistentContext(profileDir, launchOptions);
const secondPage = await openAuditPage(secondContext, "restart");
await waitForGame(
	secondPage,
	"title_with_checkpoint_candidate",
);
const restartTitleState = await gameState(secondPage);
const restartHeader = await secondPage.locator(".system-state").innerText();
await focusGameAndPress(secondPage, "c");
await waitForGame(secondPage, "active_with_saved_checkpoint");
await secondPage.waitForTimeout(1_000);
const restoredState = await gameState(secondPage);
const actualResumeState = authoritativeResumeState(restoredState);
await secondPage.screenshot({
	path: path.join(outputDir, "restored-after-browser-restart.png"),
	fullPage: true,
});
await secondContext.close();

const exactResumeMatch = JSON.stringify(actualResumeState) === JSON.stringify(expectedResumeState);
const audit = {
	url,
	profileDir,
	errors,
	settledHeader,
	restartHeader,
	checkpointBeforeClose: settledState.checkpoint ?? {},
	checkpointAfterRestartAtTitle: restartTitleState.checkpoint ?? {},
	expectedResumeState,
	actualResumeState,
	exactResumeMatch,
};
fs.writeFileSync(path.join(outputDir, "audit.json"), JSON.stringify(audit, null, 2));

if (errors.length > 0) {
	throw new Error(`Browser errors: ${errors.join(" | ")}`);
}
if (!exactResumeMatch) {
	throw new Error(`Authoritative state drifted across browser restart: ${JSON.stringify(audit)}`);
}

console.log("CHECKPOINT_WEB_PERSISTENCE_AUDIT_PASSED browser=restart indexeddb=restored state=exact");
