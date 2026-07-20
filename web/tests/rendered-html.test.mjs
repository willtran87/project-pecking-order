import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import test from "node:test";
import { runInNewContext } from "node:vm";
import ts from "typescript";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);

  return worker.fetch(
    new Request("http://localhost/", {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async () => new Response("Not found", { status: 404 }),
      },
    },
    {
      waitUntil() {},
      passThroughOnException() {},
    },
  );
}

async function accessibleStatusBuilder() {
  const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
  const start = page.indexOf("function buildAccessibleGameStatus(");
  const end = page.indexOf("function loadGodotScript", start);
  assert.notEqual(start, -1, "accessible status builder should exist");
  assert.notEqual(end, -1, "accessible status helper boundary should exist");

  const source = `${page.slice(start, end)}\nglobalThis.__accessibleStatusBuilder = buildAccessibleGameStatus;`;
  const compiled = ts.transpileModule(source, {
    compilerOptions: {
      target: ts.ScriptTarget.ES2022,
      module: ts.ModuleKind.None,
    },
  }).outputText;
  const sandbox = {};
  runInNewContext(compiled, sandbox);
  assert.equal(typeof sandbox.__accessibleStatusBuilder, "function");
  return sandbox.__accessibleStatusBuilder;
}

async function persistenceStatusBuilders() {
	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	const start = page.indexOf("function diagnosticPlainText(");
	const end = page.indexOf("function loadGodotScript", start);
	assert.notEqual(start, -1, "checkpoint diagnostic parser should exist");
	assert.notEqual(end, -1, "persistence helper boundary should exist");

	const source = `${page.slice(start, end)}
		globalThis.__checkpointDiagnosticFromValue = checkpointDiagnosticFromValue;
		globalThis.__buildPersistencePresentation = buildPersistencePresentation;
		globalThis.__classifyBrowserStorageCapability = classifyBrowserStorageCapability;
		globalThis.__createLifecycleCheckpointRequester = createLifecycleCheckpointRequester;`;
	const compiled = ts.transpileModule(source, {
		compilerOptions: {
			target: ts.ScriptTarget.ES2022,
			module: ts.ModuleKind.None,
		},
	}).outputText;
	const sandbox = {};
	runInNewContext(compiled, sandbox);
	return {
		parseCheckpoint: sandbox.__checkpointDiagnosticFromValue,
		buildPresentation: sandbox.__buildPersistencePresentation,
		classifyStorage: sandbox.__classifyBrowserStorageCapability,
		createLifecycleRequester: sandbox.__createLifecycleCheckpointRequester,
	};
}

async function campaignHasBegunBuilder() {
	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	const start = page.indexOf("function campaignHasBegun(");
	const end = page.indexOf("function loadGodotScript", start);
	assert.notEqual(start, -1, "campaign focus detector should exist");
	assert.notEqual(end, -1, "campaign focus helper boundary should exist");

	const source = `${page.slice(start, end)}\nglobalThis.__campaignHasBegun = campaignHasBegun;`;
	const compiled = ts.transpileModule(source, {
		compilerOptions: {
			target: ts.ScriptTarget.ES2022,
			module: ts.ModuleKind.None,
		},
	}).outputText;
	const sandbox = {};
	runInNewContext(compiled, sandbox);
	assert.equal(typeof sandbox.__campaignHasBegun, "function");
	return sandbox.__campaignHasBegun;
}

function probationSafeguardNearMiss() {
	return {
		visible: true,
		is_final: false,
		completed_shifts: 4,
		required_shifts: 5,
		criteria_count: 5,
		pass_count: 4,
		at_risk_count: 1,
		all_pass: false,
		criteria: [
			{
				id: "score",
				label: "PROBATION SCORE",
				metric: "probation_score",
				comparison: "minimum",
				target: 60,
				unit: "points",
				projected_value: 64,
				pass: true,
				signed_gap: 4,
			},
			{
				id: "welfare",
				label: "FLOCK WELFARE",
				metric: "average_welfare",
				comparison: "minimum",
				target: 45,
				unit: "points",
				projected_value: 52,
				pass: true,
				signed_gap: 7,
			},
			{
				id: "compliance",
				label: "COOP COMPLIANCE",
				metric: "average_compliance",
				comparison: "minimum",
				target: 55,
				unit: "points",
				projected_value: 80,
				pass: true,
				signed_gap: 25,
			},
			{
				id: "farmer_favor",
				label: "FARMER FAVOR",
				metric: "average_farmer_favor",
				comparison: "minimum",
				target: 50,
				unit: "points",
				projected_value: 49,
				pass: false,
				at_risk: true,
				signed_gap: -1,
				distance_to_pass: 1,
				recoverable: true,
			},
			{
				id: "crack_rate",
				label: "SHELL CRACK RATE",
				metric: "crack_rate_basis_points",
				comparison: "maximum",
				target: 2_500,
				unit: "basis_points",
				projected_value: 1_921,
				pass: true,
				signed_gap: 579,
			},
		],
		largest_recoverable_blocker: {
			id: "farmer_favor",
			label: "FARMER FAVOR",
			metric: "average_farmer_favor",
			comparison: "minimum",
			target: 50,
			unit: "points",
			projected_value: 49,
			pass: false,
			signed_gap: -1,
			distance_to_pass: 1,
			recoverable: true,
		},
	};
}

function probationDoctrine(overrides = {}) {
	return {
		milestone_id: "shell_quality_lab",
		milestone_title: "Shell Quality Lab",
		label: "SHELL ASSURANCE",
		strengths: ["SHELL QUALITY", "COMPLIANCE", "REWORK"],
		watchouts: ["FLOCK WELFARE", "RECOVERY DAYS"],
		...overrides,
	};
}


function probationChallengeContract(overrides = {}) {
	return {
		id: "standard_filing",
		label: "STANDARD FILING",
		short_label: "STANDARD",
		description: "The authored five-shift filing standard.",
		criteria: {
			minimum_score: 60,
			minimum_welfare: 45,
			minimum_compliance: 55,
			minimum_farmer_favor: 50,
			maximum_crack_rate_basis_points: 2_500,
		},
		...overrides,
	};
}

test("server-renders the playable Pecking Order shell", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);

  const html = await response.text();
  assert.match(html, /<title>Pecking Order/i);
  assert.match(html, /Earn your roost\./);
  assert.match(html, /Live career file/i);
  assert.match(html, /Opening career file/i);
  assert.match(html, /Preparing the browser runtime/i);
  assert.match(html, /<progress[^>]+aria-label="Game loading progress"[^>]+max="100"/i);
  assert.match(html, /rel="preload"[^>]+href="\/game\/index\.js"[^>]+as="script"/i);
  assert.match(html, /rel="preload"[^>]+href="\/game\/index\.wasm"[^>]+as="fetch"/i);
  assert.match(html, /rel="preload"[^>]+href="\/game\/index\.pck"[^>]+as="fetch"/i);
  assert.match(html, /<canvas[^>]+id="canvas"/i);
  assert.match(html, /<canvas[^>]+aria-describedby="game-controls game-status"/i);
	assert.match(html, /<input[^>]+type="file"[^>]+accept="\.json,application\/json"[^>]+hidden/i);
  assert.match(html, /id="game-controls"[^>]+class="visually-hidden"/i);
  assert.match(html, /Game controls: click a hen or route control/i);
  assert.match(html, /1 through 3 to choose a binder, card, or speed/i);
  assert.match(html, /D to keep the standard book/i);
  assert.match(html, /C to continue after filing/i);
  assert.match(html, /N to inspect negotiated riders/i);
  assert.match(html, /R to restore standard terms/i);
	assert.match(html, /P to fund a Feed Party/i);
	assert.match(html, /O for after-hours pecking/i);
	assert.match(html, /F10 for Coop Settings and Controls/i);
	assert.match(html, /Controls can be rebound from the settings panel/i);
  assert.match(html, /aria-keyshortcuts="1 2 3 Enter N R D C E P O Space V F10 Tab Escape"/i);
  assert.match(html, /id="game-status"[^>]+role="status"[^>]+aria-live="polite"[^>]+aria-atomic="true"/i);
  assert.equal((html.match(/role="status"/g) ?? []).length, 1);
  assert.match(html, /Game loading\. Objective: wait for the career file to open\./i);
	assert.match(html, /data-save-status="checking"/i);
	assert.match(html, /Checkpoint pending/i);
	assert.match(html, /Checkpoint pending \| checking browser storage/i);
	assert.doesNotMatch(html, /autosave operational|autosave active/i);
  assert.doesNotMatch(html, /coordinate_system|godot_canvas|__pecking_order_state/i);
  assert.doesNotMatch(html, /Loading saved coop records/i);
  assert.match(html, /Reload terminal/);
	assert.match(html, /<main[^>]+data-play-mode="page"/i);
	assert.match(html, /<button[^>]+aria-controls="management-handbook"[^>]*>Handbook<\/button>/i);
	assert.match(html, /<button[^>]+aria-pressed="false"[^>]+aria-label="Focus the game"[^>]*>Focus game<\/button>/i);
  assert.match(html, /Full screen/);
	assert.match(html, /<span class="career-state" data-save-status="checking">/i);
	assert.match(html, /<details class="control-details"><summary>Controls<\/summary>/i);
	assert.match(html, /Controller: A Priority Peck/i);
	assert.match(html, /right shoulder cycle hen/i);
	assert.match(html, /Settings [+] controls/i);
	assert.match(html, /Meet Mabel at her claims desk/i);
	assert.match(html, /<details id="management-handbook"[^>]+class="handbook-details">/i);
	assert.match(html, /Management Handbook/i);
	assert.match(html, /Optional field reference/i);
	assert.doesNotMatch(html, /<details class="handbook-details"[^>]+open/i);
});

test("narrates the visible Priority Peck recommendation without requiring hen cycling", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const status = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 3,
		shift_phase: 1,
		orders: { on_track: 2, total: 3 },
		production: {
			recommended_peck_assist_worker_id: 2,
			recommended_peck_assist_worker_name: "Henrietta",
			peck_assists_remaining: 2,
		},
	}), { loaded: true, loadProgress: 100 });
	assert.match(status, /Priority Peck ready for Henrietta; press E or use Priority/i);
});

test("offers bounded portable career files to the Godot validator through a browser picker", async () => {
	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	assert.match(page, /const MAX_PORTABLE_BACKUP_BYTES = 8 \* 1024 \* 1024/);
	assert.match(page, /__pecking_order_choose_backup_file/);
	assert.match(page, /input\.value = "";\s*input\.click\(\)/);
	assert.doesNotMatch(page, /delete runtime\.__pecking_order_choose_backup_file/);
	assert.match(page, /file\.size > MAX_PORTABLE_BACKUP_BYTES/);
	assert.match(page, /await file\.text\(\)/);
	assert.match(page, /__pecking_order_offer_backup/);
	assert.match(page, /offerBackup\(jsonText, file\.name, ""\)/);
	assert.match(page, /finally \{\s*input\.value = ""/);
	assert.match(page, /requestAnimationFrame\(\(\) => gameCanvas\.current\?\.focus\(\)\)/);
	assert.match(page, /input\.value = "";\s*restoreCanvasFocus\(\);\s*return/);
	assert.match(page, /__pecking_order_runtime_metrics/);
	assert.match(page, /engine\.rtenv\?\.HEAP8\?\.buffer\.byteLength \?\? 0/);
	assert.doesNotMatch(page, /__pecking_order_runtime_metrics\s*=\s*engine/);
});

test("installs a bounded synchronous browser mirror for independently validated player preferences", async () => {
	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	assert.match(page, /PLAYER_PREFERENCES_STORAGE_KEY = "pecking-order\.player-preferences"/);
	assert.match(page, /MAX_PLAYER_PREFERENCES_BYTES = 512 \* 1024/);
	assert.match(page, /installPlayerPreferencesBridge\(\)/);
	assert.match(page, /__pecking_order_preferences_bridge/);
	assert.match(page, /Object\.freeze/);
	assert.match(page, /localStorage\.setItem\(PLAYER_PREFERENCES_STORAGE_KEY, payload\)/);
	assert.match(page, /localStorage\.getItem\(PLAYER_PREFERENCES_STORAGE_KEY\) === payload/);
	assert.match(page, /JSON\.parse\(payload\)/);
	assert.match(page, /Array\.isArray\(parsed\)/);
});

test("starts the runtime and manifest fetch in parallel with truthful staged loading copy", async () => {
	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	assert.match(page, /Promise\.all\(\[\s*loadGodotScript\(\),\s*loadGodotConfig\(\),\s*\]\)/);
	assert.match(page, /Loading office runtime and assets/);
	assert.match(page, /Assembling the opening office/);
	assert.doesNotMatch(page, /Loading saved coop records/);
});

test("keeps the Godot backing canvas sharp after resize, rotation, and fullscreen changes", async () => {
	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	assert.match(page, /const fitCanvasToStage = \(\) =>/);
	assert.match(page, /new ResizeObserver\(fitCanvasToStage\)/);
	assert.match(page, /addEventListener\("resize", fitCanvasToStage/);
	assert.match(page, /addEventListener\("orientationchange", fitCanvasToStage/);
	assert.match(page, /addEventListener\("fullscreenchange", fitCanvasToStage/);
	assert.match(page, /Math\.max\(1280/);
	assert.match(page, /Math\.min\(\s*2560/);
	assert.match(page, /renderHeight = Math\.round\(renderWidth \* 9 \/ 16\)/);
});

test("focuses the wrapper after a campaign begins while retaining a manual page-mode override", async () => {
	const campaignHasBegun = await campaignHasBegunBuilder();
	assert.equal(campaignHasBegun({}), false);
	assert.equal(campaignHasBegun({ campaign_stage: "title" }), false);
	assert.equal(campaignHasBegun({ campaign_stage: " TITLE " }), false);
	for (const campaignStage of ["active", "farmer", "credit", "final", "senior_quarter", "senior_annual"]) {
		assert.equal(campaignHasBegun({ campaign_stage: campaignStage }), true, campaignStage);
	}

	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	const css = await readFile(new URL("../app/globals.css", import.meta.url), "utf8");
	assert.match(page, /playModePreference === "auto" && campaignActive/);
	assert.match(page, /const nextCampaignActive = campaignHasBegun\(state\)/);
	assert.match(page, /setCampaignActive\(\(current\) =>/);
	assert.match(page, /setPlayModePreference\(enteringFocusedPlay \? "focused" : "page"\)/);
	assert.match(page, /details\.open = true/);
	assert.match(page, /details\.scrollIntoView\(\{ block: "start" \}\)/);
	assert.match(css, /\.is-focused-play \.intro,[\s\S]*display:\s*none/);
	assert.match(css, /\.is-focused-play \.handbook[\s\S]*display:\s*none/);
	assert.match(css, /\.is-focused-play \.game-stage\s*\{[\s\S]*100dvh - 122px/);
	assert.match(css, /\.site-shell\.is-focused-play\s*\{[\s\S]*1920px/);
	assert.match(css, /@media \(max-width:\s*720px\)[\s\S]*grid-template-columns:\s*repeat\(4, minmax\(0, 1fr\)\)/);
	assert.match(page, /className="mobile-touch-controls" aria-label="Touch game controls"/);
	assert.match(page, /__pecking_order_mobile_action/);
	assert.match(page, /aria-label="Focus next hen">Next hen</);
	assert.match(page, /onKeyDown=\{handleCanvasKeyDown\}/);
	assert.match(page, /invokeMobileAction\("cycle_hen"\)/);
	assert.match(page, /invokeMobileAction\("flockwatch"\)/);
	assert.match(page, /invokeMobileAction\("settings"\)/);
	assert.match(page, /invokeMobileAction\("zoom_in"\)/);
	assert.match(page, /invokeMobileAction\("zoom_out"\)/);
	assert.match(page, /runTouchControl\(event, \(\) => invokeMobileAction\("zoom_in"\)\)/);
	assert.match(page, /onTouchStart=\{\(event\) => runTouchControl/);
	assert.match(css, /@media \(max-width:\s*900px\)[\s\S]*\.is-focused-play \.mobile-touch-controls[\s\S]*grid-template-columns:\s*repeat\(4, minmax\(0, 1fr\)\)/);
	assert.match(css, /\.mobile-touch-controls button\s*\{[\s\S]*min-height:\s*40px/);
	assert.match(css, /@media \(max-width:\s*480px\)[\s\S]*\.is-focused-play \.terminal-action-secondary\s*\{\s*display:\s*none/);
	assert.match(css, /@media \(max-width:\s*480px\)[\s\S]*\.is-focused-play \.mobile-touch-controls\s*\{\s*grid-template-columns:\s*repeat\(4/);
});

test("reports checkpoint evidence truthfully across persistent, best-effort, pending, and failed states", async () => {
	const {
		parseCheckpoint,
		buildPresentation,
		classifyStorage,
	} = await persistenceStatusBuilders();

	assert.equal(classifyStorage(false, undefined).status, "unavailable");
	assert.equal(classifyStorage(true, true).status, "persistent");
	assert.equal(classifyStorage(true, false).status, "best_effort");

	const cleanWithoutEvidence = parseCheckpoint({
		status: "clean",
		dirty: false,
		saving: false,
		last_error: "",
		last_saved_unix_msec: 0,
		has_candidate: true,
		has_checkpoint: false,
		write_success_count: 0,
	});
	const pending = buildPresentation({ status: "persistent" }, cleanWithoutEvidence);
	assert.equal(pending.tone, "checking");
	assert.match(pending.headerText, /Checkpoint pending/);
	assert.match(pending.accessibleText, /has not reported a successful checkpoint yet/);
	assert.doesNotMatch(pending.accessibleText, /checkpoint saved/i);

	const saved = parseCheckpoint({
		status: "clean",
		dirty: false,
		saving: false,
		last_error: "",
		last_saved_unix_msec: 1_753_000_000_000,
		has_checkpoint: true,
		write_success_count: 1,
	});
	const persistent = buildPresentation({ status: "persistent" }, saved);
	assert.equal(persistent.tone, "saved");
	assert.match(persistent.headerText, /Career saved \| persistent storage/);
	assert.match(persistent.accessibleText, /Career checkpoint saved\. Browser storage is persistent\./);

	const bestEffort = buildPresentation({ status: "best_effort" }, saved);
	assert.equal(bestEffort.tone, "saved");
	assert.match(bestEffort.headerText, /Career saved \| best-effort storage/);
	assert.match(bestEffort.accessibleText, /may be cleared by the browser/);

	const runtimeNonPersistent = parseCheckpoint({
		status: "clean",
		dirty: false,
		saving: false,
		has_checkpoint: true,
		write_success_count: 1,
		last_saved_unix_msec: 1_753_000_000_000,
		userfs_persistent_hint: false,
	});
	for (const storageStatus of ["persistent", "best_effort"]) {
		const unavailableRuntime = buildPresentation({ status: storageStatus }, runtimeNonPersistent);
		assert.equal(unavailableRuntime.tone, "unavailable");
		assert.match(unavailableRuntime.headerText, /Career saving unavailable/);
		assert.match(unavailableRuntime.accessibleText, /game runtime reports that its user filesystem is not persistent/);
		assert.doesNotMatch(unavailableRuntime.accessibleText, /checkpoint saved/i);
	}

	const runtimePositiveHint = parseCheckpoint({
		status: "clean",
		has_checkpoint: true,
		write_success_count: 1,
		last_saved_unix_msec: 1_753_000_000_000,
		userfs_persistent_hint: true,
	});
	const stillChecking = buildPresentation({ status: "checking" }, runtimePositiveHint);
	assert.equal(stillChecking.tone, "checking", "a positive runtime hint must not bypass the independent browser probe");
	assert.match(stillChecking.accessibleText, /Browser storage persistence is still being checked/);
	const confirmedByBoth = buildPresentation({ status: "persistent" }, runtimePositiveHint);
	assert.equal(confirmedByBoth.tone, "saved");

	const saving = buildPresentation({ status: "persistent" }, parseCheckpoint({
		status: "saving",
		dirty: true,
		saving: true,
		has_checkpoint: true,
		write_success_count: 1,
		last_saved_unix_msec: 1_753_000_000_000,
	}));
	assert.match(saving.headerText, /Saving career checkpoint/);
	assert.doesNotMatch(saving.accessibleText, /checkpoint saved/i);

	const dirty = buildPresentation({ status: "persistent" }, parseCheckpoint({
		status: "dirty",
		dirty: true,
		has_checkpoint: true,
		write_success_count: 1,
		last_saved_unix_msec: 1_753_000_000_000,
	}));
	assert.match(dirty.headerText, /Unsaved career changes pending/);
	assert.match(dirty.accessibleText, /prior successful checkpoint is recorded/);
	assert.doesNotMatch(dirty.accessibleText, /checkpoint saved/i);

	const failed = buildPresentation({ status: "persistent" }, parseCheckpoint({
		status: "failed",
		last_error: "<script>globalThis.compromised = true</script><b>Indexed write failed.</b>",
		last_saved_unix_msec: 1_753_000_000_000,
		has_checkpoint: true,
		write_success_count: 1,
	}));
	assert.equal(failed.tone, "degraded");
	assert.match(failed.headerText, /Career save degraded/);
	assert.match(failed.accessibleText, /Indexed write failed\./);
	assert.doesNotMatch(failed.accessibleText, /<|>|script|globalThis/);

	const unavailable = buildPresentation({ status: "unavailable" }, saved);
	assert.equal(unavailable.tone, "unavailable");
	assert.match(unavailable.accessibleText, /Career saving is unavailable/);
});

test("probes browser durability and forwards every lifecycle boundary through a late-bound bridge", async () => {
	const page = await readFile(new URL("../app/page.tsx", import.meta.url), "utf8");
	assert.match(page, /window\.indexedDB/);
	assert.match(page, /factory\.open\(databaseName, 1\)/);
	assert.match(page, /storageManager\.persisted\(\)/);
	assert.match(page, /document\.addEventListener\("visibilitychange"/);
	assert.match(page, /window\.addEventListener\("blur"/);
	assert.match(page, /window\.addEventListener\("focus"/);
	assert.match(page, /window\.addEventListener\("pagehide"/);
	assert.match(page, /document\.removeEventListener\("visibilitychange"/);
	assert.match(page, /window\.removeEventListener\("blur"/);
	assert.match(page, /window\.removeEventListener\("focus"/);
	assert.match(page, /window\.removeEventListener\("pagehide"/);
	assert.match(page, /__pecking_order_set_focus_paused/);
	assert.match(page, /web_visibility_hidden/);
	assert.match(page, /web_pagehide/);
	assert.doesNotMatch(page, /dedupeWindowMsec|lastRequestMsec/);

	const { createLifecycleRequester } = await persistenceStatusBuilders();
	let bridge;
	const calls = [];
	const request = createLifecycleRequester(() => bridge);
	assert.equal(request("web_visibility_hidden"), false, "missing startup bridge should be a safe no-op");
	bridge = (reason) => calls.push(reason);
	assert.equal(request("web_visibility_hidden"), true, "bridge should be looked up again at event time");
	assert.equal(request("web_pagehide"), true, "back-to-back hidden/pagehide must both reach Office");
	assert.equal(calls.join(","), "web_visibility_hidden,web_pagehide");

	let throwNext = true;
	bridge = (reason) => {
		if (throwNext) {
			throwNext = false;
			throw new Error("transient synchronous bridge failure");
		}
		calls.push(`after_throw:${reason}`);
	};
	assert.equal(request("web_visibility_hidden"), false, "a thrown bridge call should be absorbed");
	assert.equal(request("web_pagehide"), true, "a thrown call must not suppress the next lifecycle request");

	let rejectNext = true;
	bridge = (reason) => {
		if (rejectNext) {
			rejectNext = false;
			return Promise.reject(new Error("transient asynchronous bridge failure"));
		}
		calls.push(`after_rejection:${reason}`);
		return Promise.resolve();
	};
	assert.equal(request("web_visibility_hidden"), true, "an asynchronous rejection should be absorbed");
	await Promise.resolve();
	assert.equal(request("web_pagehide"), true, "a rejected call must not suppress the next lifecycle request");
	await Promise.resolve();
	assert.match(calls.join(","), /after_throw:web_pagehide/);
	assert.match(calls.join(","), /after_rejection:web_pagehide/);
});

test("appends one sanitized persistence update to the assistive game status", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const persistenceStatus = "Career checkpoint saved. Browser storage is persistent.";
	const status = buildStatus(JSON.stringify({
		campaign_stage: "title",
	}), {
		loaded: true,
		loadError: "",
		loadProgress: 100,
		persistenceStatus,
	});
	assert.match(status, /^Campaign menu open\./);
	assert.equal((status.match(/Career checkpoint saved/g) ?? []).length, 1);
	assert.match(status, /Browser storage is persistent\.$/);

	const duplicate = buildStatus(JSON.stringify({}), {
		loaded: true,
		loadError: "",
		loadProgress: 100,
		persistenceStatus: "<b>Game ready. Objective: follow the current in-game guidance.</b>",
	});
	assert.equal(duplicate, "Game ready. Objective: follow the current in-game guidance.");
});

test("prioritizes the open settings and controls surface for assistive technology", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const status = buildStatus(JSON.stringify({
		loaded: true,
		settings: {
			visible: true,
			accessible_text: "Coop Settings and Controls. Master 80 percent. Motion reduced. High contrast on.",
		},
		probation_safeguards: probationSafeguardNearMiss(),
		campaign_stage: "active",
	}), { loaded: true, loadError: "", loadProgress: 100 });
	assert.match(status, /^Coop Settings and Controls\./);
	assert.match(status, /Master 80 percent/);
	assert.match(status, /Motion reduced/);
	assert.match(status, /Return to the Floor/);
	assert.doesNotMatch(status, /route files and keep the objectives/);
	assert.doesNotMatch(status, /Probation safeguards/);
});

test("narrates the visible management decision and every bounded choice", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const status = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 2,
		case_docket: { id: "PO-7919" },
		shift_phase: 0,
		pending_decision_kind: "directive",
		pending_decision: {
			visible: true,
			id: "morning_directive",
			title: "<strong>Choose today's management policy</strong>",
			body: "One policy governs the shift.<script>globalThis.compromised=true</script>",
			selected_option_id: "shell_assurance",
			options: [
				{ index: 1, id: "record_harvest", label: "Record Harvest", tagline: "Maximum throughput", cost_cents: 0, available: true },
				{ index: 2, id: "shell_assurance", label: "Shell Assurance", tagline: "Protect quality", cost_cents: 300, available: true },
				{ index: 3, id: "sustainable_flock", label: "Sustainable Flock", tagline: "Protect welfare", cost_cents: 9000, available: false, unavailable_reason: "Protected reserve would be breached." },
			],
		},
	}), { loaded: true, loadError: "", loadProgress: 100 });

	assert.match(status, /^Shift 2\. Case docket PO-7919\. Choose today's management policy\./i);
	assert.match(status, /Choices: 1, Record Harvest: Maximum throughput/);
	assert.match(status, /2, Shell Assurance: Protect quality, costs \$3\.00, selected/);
	assert.match(status, /3, Sustainable Flock: Protect welfare unavailable: Protected reserve would be breached/);
	assert.match(status, /press 1 through 3 to inspect a response, then Enter to authorize it/);
	assert.doesNotMatch(status, /<|>|script|globalThis|compromised/);
});

test("narrates the contextual Enter action during First Clutch dossier lessons", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const status = buildStatus(JSON.stringify({
		loaded: true,
		campaign_stage: "active",
		campaign_day: 1,
		shift_phase: 1,
		first_clutch: {
			visible: true,
			stage: "specialty_route",
			progress: 1,
			guidance: "Press Enter to route Mabel to Appeals, or choose another tray below.",
		},
	}), { loaded: true, loadError: "", loadProgress: 100 });
	assert.match(status, /First Clutch 1 of 5/);
	assert.match(status, /Press Enter to route Mabel to Appeals/);
});

test("prioritizes Flockwatch page and action feedback over the underlying shift", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const feedback = "Provisions order held: protected reserve would be breached.";
	const status = buildStatus(JSON.stringify({
		flockwatch: {
			visible: true,
			current_page: "operations",
			current_page_title: "Operations",
			available_pages: ["today", "flock", "operations", "capital"],
			accessible_text: `Flockwatch filing pages. Operations is current. Available: Today, Flock, Operations, Capital. 12 sections filed. Latest notice: ${feedback}`,
			last_feedback: feedback,
		},
		campaign_stage: "active",
		campaign_day: 4,
		shift_phase: 1,
		orders: { on_track: 2, total: 3 },
		probation_safeguards: probationSafeguardNearMiss(),
	}), { loaded: true, loadError: "", loadProgress: 100 });

	assert.match(status, /^Flockwatch open\. Current page: Operations\./);
	assert.match(status, /Available: Today, Flock, Operations, Capital\./);
	assert.match(status, /12 sections filed\./);
	assert.equal((status.match(/Provisions order held/g) ?? []).length, 1, "last feedback should not be narrated twice when the authored summary already includes it");
	assert.doesNotMatch(status, /Operations is current|route files and keep the objectives|Probation safeguards/);
});

test("normalizes Flockwatch diagnostics to bounded plain text with structured fallbacks", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const status = buildStatus(JSON.stringify({
		flockwatch: {
			visible: true,
			current_page: "governance_records",
			current_page_title: "<strong>Governance / Records</strong>",
			available_pages: ["today", "governance_records", { id: "capital", title: "<em>Capital</em>" }],
			accessible_text: "Flockwatch filing pages. <em>Governance / Records</em> is current. <script>globalThis.compromised = true</script>",
			last_feedback: "<b>Case file accepted.</b><img src=x onerror='globalThis.compromised = true'>",
		},
		campaign_stage: "final",
	}), { loaded: true, loadError: "", loadProgress: 100 });

	assert.match(status, /^Flockwatch open\. Current page: Governance \/ Records\./);
	assert.match(status, /Available pages: Today, Governance Records, and Capital\./);
	assert.match(status, /Latest notice: Case file accepted\./);
	assert.doesNotMatch(status, /<|>|script|onerror|globalThis|Final campaign review/);
});

test("announces permanent career commendations only from the Records filing", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const commendations = {
		earned_count: 3,
		total_count: 11,
		complete: false,
		next: {
			title: "<strong>Mutual Assurance</strong>",
			progress_label: "2 / 3 binders<script>globalThis.compromised = true</script>",
		},
	};
	const records = buildStatus(JSON.stringify({
		campaign_stage: "active",
		commendations,
		flockwatch: {
			visible: true,
			current_page: "governance_records",
			current_page_title: "Records",
			accessible_text: "Flockwatch filing pages. Records is current. 9 sections filed.",
		},
	}), context);
	assert.match(records, /Career commendations: 3 of 11 filed\./);
	assert.match(records, /Next stamp: Mutual Assurance, 2 \/ 3 binders\./);
	assert.match(records, /no hidden economy bonus/i);
	assert.doesNotMatch(records, /<|>|script|globalThis/);

	const today = buildStatus(JSON.stringify({
		campaign_stage: "active",
		commendations,
		flockwatch: {
			visible: true,
			current_page: "today",
			current_page_title: "Today",
			accessible_text: "Flockwatch filing pages. Today is current. 8 sections filed.",
		},
	}), context);
	assert.doesNotMatch(today, /Career commendations|Mutual Assurance|hidden economy bonus/);
});

test("narrates one concise selected probation doctrine in the live campaign and Flockwatch", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const doctrine = probationDoctrine();
	const expected = "Active probation doctrine: Shell Assurance, filed through Shell Quality Lab. Strengths: Shell Quality, Compliance, and Rework. Watch: Flock Welfare and Recovery Days.";
	const liveStatus = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 3,
		shift_phase: 1,
		orders: { on_track: 2, total: 3 },
		senior_roost: { status: "inactive" },
		probation_doctrine: doctrine,
	}), context);

	assert.match(liveStatus, new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
	assert.equal((liveStatus.match(/Active probation doctrine:/g) ?? []).length, 1);

	const flockwatchStatus = buildStatus(JSON.stringify({
		campaign_stage: "active",
		senior_roost: { status: "inactive" },
		probation_doctrine: doctrine,
		flockwatch: {
			visible: true,
			current_page: "today",
			current_page_title: "Today",
			accessible_text: "Flockwatch filing pages. Today is current. 8 sections filed.",
		},
	}), context);

	assert.match(flockwatchStatus, /^Flockwatch open\. Current page: Today\./);
	assert.match(flockwatchStatus, /8 sections filed\./);
	assert.match(flockwatchStatus, new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
	assert.equal((flockwatchStatus.match(/Active probation doctrine:/g) ?? []).length, 1);

	const authoredFlockwatchStatus = buildStatus(JSON.stringify({
		campaign_stage: "active",
		senior_roost: { status: "inactive" },
		probation_doctrine: doctrine,
		flockwatch: {
			visible: true,
			current_page: "today",
			current_page_title: "Today",
			accessible_text: `Flockwatch filing pages. Today is current. ${expected}`,
		},
	}), context);
	assert.match(authoredFlockwatchStatus, new RegExp(expected.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
	assert.equal((authoredFlockwatchStatus.match(/Active probation doctrine:/g) ?? []).length, 1, "authored Flockwatch copy should not duplicate the derived doctrine summary");
});

test("sanitizes probation doctrine copy and suppresses it before selection, on the title, and in Senior Roost", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const unsafeDoctrine = probationDoctrine({
		milestone_title: "<em>Shell Quality Lab</em><img src=x onerror='globalThis.compromised = true'>",
		label: "<b>SHELL ASSURANCE</b><script>globalThis.compromised = true</script>",
		strengths: ["<strong>SHELL QUALITY</strong>", "<script>globalThis.compromised = true</script>", "COMPLIANCE", "REWORK", "UNBOUNDED COPY"],
		watchouts: ["<b>FLOCK WELFARE</b>", "<style>body{display:none}</style>RECOVERY DAYS"],
	});
	const sanitized = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 3,
		shift_phase: 1,
		orders: { on_track: 2, total: 3 },
		senior_roost: { status: "inactive" },
		probation_doctrine: unsafeDoctrine,
	}), context);

	assert.match(sanitized, /Active probation doctrine: Shell Assurance, filed through Shell Quality Lab\./);
	assert.match(sanitized, /Strengths: Shell Quality, Compliance, and Rework\./);
	assert.match(sanitized, /Watch: Flock Welfare and Recovery Days\./);
	assert.doesNotMatch(sanitized, /<|>|script|style|onerror|globalThis|Unbounded Copy/i);

	const beforeSelection = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 2,
		shift_phase: 1,
		orders: { on_track: 1, total: 3 },
		probation_doctrine: { label: "SHELL ASSURANCE" },
	}), context);
	assert.doesNotMatch(beforeSelection, /Active probation doctrine|Shell Assurance/);

	const title = buildStatus(JSON.stringify({
		campaign_stage: "title",
		probation_doctrine: probationDoctrine(),
	}), context);
	assert.equal(title, "Campaign menu open. Objective: choose a filing standard, then meet Mabel and open the new career file.");

	const seniorFlockwatch = buildStatus(JSON.stringify({
		campaign_stage: "senior_quarter",
		senior_roost: { status: "active", year: 2, quarter: 1 },
		probation_doctrine: probationDoctrine(),
		flockwatch: {
			visible: true,
			current_page: "today",
			current_page_title: "Today",
		},
	}), context);
	assert.match(seniorFlockwatch, /^Flockwatch open\. Current page: Today\./);
	assert.doesNotMatch(seniorFlockwatch, /Active probation doctrine|Shell Assurance/);

	const seniorLive = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 9,
		shift_phase: 1,
		senior_roost: { status: "active", year: 2, quarter: 1, shift_in_quarter: 1 },
		orders: { on_track: 2, total: 3 },
		probation_doctrine: probationDoctrine(),
	}), context);
	assert.match(seniorLive, /^Senior Year 2, Quarter 1, Shift 1 running\./);
	assert.doesNotMatch(seniorLive, /Active probation doctrine|Shell Assurance/);
});

test("distinguishes the selected new-file standard from the saved resume standard on intake", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const selectedChallenge = probationChallengeContract({
		id: "executive_audit",
		label: "EXECUTIVE AUDIT",
		short_label: "AUDIT",
		route_guidance: "Harvest Partnership has a proven specialist route. Care-led files need extra score; quality-led files must deliberately recover welfare and farmer favor.",
		criteria: {
			minimum_score: 65,
			minimum_welfare: 48,
			minimum_compliance: 65,
			minimum_farmer_favor: 53,
			maximum_crack_rate_basis_points: 2_300,
		},
	});
	const savedChallenge = probationChallengeContract();
	const title = buildStatus(JSON.stringify({
		campaign_stage: "title",
		campaign_intake_phase: "new_file",
		challenge_contract: selectedChallenge,
		selected_new_challenge_contract: selectedChallenge,
		resume_available: true,
		resume_challenge_contract: savedChallenge,
		resume_senior_roost: false,
	}), context);
	assert.match(title, /^Campaign menu open\. New file selection: Executive Audit\./);
	assert.match(title, /score 65, welfare 48, compliance 65, farmer favor 53/);
	assert.match(title, /shell cracks at or below 23\.00 percent/);
	assert.match(title, /Route guidance: Harvest Partnership has a proven specialist route\./);
	assert.match(title, /Care-led files need extra score/);
	assert.match(title, /saved-file candidate remains unchanged until replacement is confirmed\./);
	assert.match(title, /return to the saved-file candidate\./);
	assert.doesNotMatch(title, /Continue resumes saved file under/);

	const resumeLanding = buildStatus(JSON.stringify({
		campaign_stage: "title",
		campaign_intake_phase: "resume",
		selected_new_challenge_contract: selectedChallenge,
		resume_available: true,
		resume_challenge_contract: savedChallenge,
		resume_senior_roost: false,
	}), context);
	assert.doesNotMatch(resumeLanding, /New file selection|Executive Audit|choose a filing standard/);
	assert.match(resumeLanding, /resumable file candidate is available under Standard Filing; Continue will verify and open it\./);
	assert.match(resumeLanding, /Objective: continue the saved-file candidate, or review a new file\./);

	const unverifiedResume = buildStatus(JSON.stringify({
		campaign_stage: "title",
		selected_new_challenge_contract: selectedChallenge,
		resume_available: true,
		resume_challenge_contract: {},
		resume_senior_roost: false,
	}), context);
	assert.match(unverifiedResume, /filing standard could not be verified\./);
	assert.doesNotMatch(unverifiedResume, /under Standard Filing/);

	const seniorResume = buildStatus(JSON.stringify({
		campaign_stage: "title",
		selected_new_challenge_contract: selectedChallenge,
		resume_available: true,
		resume_challenge_contract: savedChallenge,
		resume_senior_roost: true,
	}), context);
	assert.match(seniorResume, /saved Senior career candidate is available; Continue will verify and open it\./);
	assert.doesNotMatch(seniorResume, /under Standard Filing/);
});


test("keeps active and Flockwatch Today safeguard narration concise", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const challenge = probationChallengeContract();
	const safeguardForecast = probationSafeguardNearMiss();

	const live = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 2,
		shift_phase: 1,
		orders: { on_track: 2, total: 3 },
		senior_roost: { status: "inactive" },
		challenge_contract: challenge,
		probation_safeguards: safeguardForecast,
	}), context);
	assert.match(live, /Probation filing standard: Standard Filing\./);
	assert.match(live, /Probation safeguards: 4 of 5 currently pass\./);
	assert.match(live, /Largest recoverable blocker: Farmer Favor, 49 points against a minimum of 50 points; 1 point short\./);
	assert.equal((live.match(/Probation filing standard:/g) ?? []).length, 1);
	assert.doesNotMatch(live, /Final terms:|Probation Score passes|Flock Welfare passes|Shell Crack Rate passes/);

	const flockwatchToday = buildStatus(JSON.stringify({
		campaign_stage: "active",
		senior_roost: { status: "inactive" },
		challenge_contract: challenge,
		probation_safeguards: safeguardForecast,
		flockwatch: {
			visible: true,
			current_page: "today",
			current_page_title: "Today",
			accessible_text: "Flockwatch filing pages. Today is current. 8 sections filed.",
		},
	}), context);
	assert.match(flockwatchToday, /^Flockwatch open\. Current page: Today\./);
	assert.match(flockwatchToday, /Probation filing standard: Standard Filing\./);
	assert.match(flockwatchToday, /Probation safeguards: 4 of 5 currently pass\./);
	assert.match(flockwatchToday, /Largest recoverable blocker: Farmer Favor/);
	assert.equal((flockwatchToday.match(/Probation filing standard:/g) ?? []).length, 1);
	assert.doesNotMatch(flockwatchToday, /Final terms:|Probation Score passes|Shell Crack Rate passes/);

	const flockwatchOperations = buildStatus(JSON.stringify({
		campaign_stage: "active",
		senior_roost: { status: "inactive" },
		challenge_contract: challenge,
		probation_safeguards: safeguardForecast,
		flockwatch: {
			visible: true,
			current_page: "operations",
			current_page_title: "Operations",
			accessible_text: "Flockwatch filing pages. Operations is current. 12 sections filed.",
		},
	}), context);
	assert.match(flockwatchOperations, /^Flockwatch open\. Current page: Operations\./);
	assert.match(flockwatchOperations, /Probation filing standard: Standard Filing\./);
	assert.doesNotMatch(flockwatchOperations, /Probation safeguards|Largest recoverable blocker|Final terms:/);

	const senior = buildStatus(JSON.stringify({
		campaign_stage: "senior_quarter",
		senior_roost: { status: "active", year: 2, quarter: 1 },
		challenge_contract: challenge,
		probation_safeguards: safeguardForecast,
		flockwatch: { visible: true, current_page: "today", current_page_title: "Today" },
	}), context);
	assert.doesNotMatch(senior, /Probation filing standard|Standard Filing|Probation safeguards|Largest recoverable blocker|Final terms:/);
});


test("reserves every exact safeguard row for probation reports and the final review", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const safeguardForecast = probationSafeguardNearMiss();
	for (const campaignStage of ["probation", "final"]) {
		const status = buildStatus(JSON.stringify({
			campaign_stage: campaignStage,
			campaign_day: 5,
			senior_roost: { status: "inactive" },
			challenge_contract: probationChallengeContract(),
			probation_safeguards: safeguardForecast,
		}), context);

		assert.match(status, /Probation safeguards: 4 of 5 currently pass; 4 of 5 shifts completed\./);
		assert.match(status, /Largest recoverable blocker: Farmer Favor, 49 points against a minimum of 50 points; 1 point short\./);
		assert.match(status, /Probation Score passes at 64 points against a minimum of 60 points, 4 points above minimum/);
		assert.match(status, /Flock Welfare passes at 52 points against a minimum of 45 points, 7 points above minimum/);
		assert.match(status, /Coop Compliance passes at 80 points against a minimum of 55 points, 25 points above minimum/);
		assert.match(status, /Farmer Favor is at risk at 49 points against a minimum of 50 points, 1 point short/);
		assert.match(status, /Shell Crack Rate passes at 19\.21 percent against a maximum of 25\.00 percent, 5\.79 percentage points below maximum/);
	}

	const modalStatus = buildStatus(JSON.stringify({
		campaign_stage: "active",
		shift_phase: 1,
		probation_safeguards: safeguardForecast,
		commissioning_reveal: {
			visible: true,
			receipt: {
				facility_name: "Wellness Nest",
				purchased_level: 2,
				cost_cents: 12_000,
				spendable_after_cents: 8_500,
			},
		},
	}), context);
	assert.match(modalStatus, /^Facility commissioned: Wellness Nest/);
	assert.doesNotMatch(modalStatus, /Probation safeguards/);
});

test("keeps the full probation-to-Senior reference in a collapsed responsive handbook", async () => {
  const [response, page, css] = await Promise.all([
    render(),
    readFile(new URL("../app/page.tsx", import.meta.url), "utf8"),
    readFile(new URL("../app/globals.css", import.meta.url), "utf8"),
  ]);
  const html = await response.text();

  assert.equal((page.match(/<article>/g) ?? []).length, 3);
  assert.equal((html.match(/class="briefing-number"/g) ?? []).length, 3);
	assert.match(page, /<details id="management-handbook" ref=\{handbookDetails\} className="handbook-details">/);
	assert.match(page, /<strong>Management Handbook<\/strong>/);
	assert.match(page, /<details className="control-details">/);
	assert.match(page, /<summary>Controls<\/summary>/);
	assert.match(page, /className="control-grid" aria-label="Keyboard and pointer controls"/);
  assert.match(html, /Five-shift probation/);
	assert.match(html, /Uncapped Senior career/);
  assert.match(html, /Clear the daily orders/);
  assert.match(html, /three probation orders each shift/);
  assert.match(html, /one score across all five shifts/);
	assert.match(html, /recurring Senior quarters/);
  assert.match(html, /Route the peckwork/);
  assert.match(html, /specialty and current file/);
	assert.match(html, /career, trust, and grievance/);
	assert.match(html, /named-hen case files/);
	assert.match(html, /fund a remedy, mediate, file a coercive PIP/);
	assert.match(html, /Farmer Relations Gallery can turn one real shift into a Layer Profile, Clutch Results Board, or Farmer(?:'|&#x27;)s Method campaign/i);
	assert.match(html, /standing, cash effects, and the chosen attribution stay on the permanent wall/i);
  for (const queue of ["AUTO", "NEST", "PREDATOR", "APPEALS"]) {
    assert.match(html, new RegExp(`\\b${queue}\\b`));
  }
  assert.match(html, /Matched specialties clear files faster/);
  assert.match(html, /looming deadline/);
  assert.match(html, /imperfect route/);
	assert.match(html, /AUTO remains opt-in for each employed hen/);
	assert.match(html, /manual tray is an explicit override/);
	assert.match(html, /Rooster Operations check-in allowance/);
	assert.match(html, /Grow the bureau/);
	assert.match(html, /authorize vacant perches/);
	assert.match(html, /applicant specialties, wages, and profiles/);
	assert.match(html, /Records Annex raises live-file capacity from 18 to 24, 30, then 36/i);
	assert.match(html, /Farm Mutual folders with disclosed lane mix, timed arrivals, premium, and breach charge/i);
	assert.match(html, /Successful binders earn standing and Bronze, Silver, then Gold seals/i);
	assert.match(html, /three visible Service Coop tiers/i);
	assert.match(html, /Three-day market seasons begin on Day 6/i);
	assert.match(html, /Gold accreditation can open a physical Negotiation Room/i);
	assert.match(html, /one rush, specialist, or welfare rider/i);
	assert.match(html, /Feed, payroll, upkeep, arrears, settlements, and signed breach exposure are reserved/i);
	assert.match(html, /When browser storage is available, the terminal checkpoints roster, case, order, and capital decisions/i);
	assert.match(html, /Pass Shift 5 to unlock three-shift Senior quarters/i);
	assert.match(html, /live Career Forecasts/);
	assert.match(html, /promotion marks you can bank or invest/i);
	assert.match(html, /named hen.*cross-training/i);
	assert.match(html, /Wellness Nest tiers add recovery perches and protect Rested Flock welfare/i);
	assert.match(html, /Training Roost tiers reduce sponsorship cost and production drag/i);
	assert.match(html, /Rooster Operations Office tiers add check-ins but also supervisor payroll and surveillance pressure/i);
	assert.match(html, /IT Coop tiers improve only AUTO-routed work while raising compliance exposure/i);
	assert.match(html, /Capital Blueprint and Campus Portfolio to commission visible office expansions/i);
	assert.match(html, /Campus Portfolio extends North Meadow(?:'|&#x27;)s shared utilities into Orchard Row and Creekside Yard/i);
	assert.match(html, /Collection Rail Hub, Grain Recovery Mill, Creekside Chilling Exchange, or Contractor Roost/i);
	assert.match(html, /Contractor, power, and cold capacity are finite/i);
	assert.match(html, /completed module only delivers its economic benefit when an available named hen staffs it/i);
	assert.match(html, /Checkpoint pending \| checking browser storage/);
	assert.doesNotMatch(html, /autosave operational|autosave active/i);
	assert.match(html, /Hen \/ route file/);
	assert.match(html, /Flockwatch \+ roster/);
	assert.match(html, /Keep standard book/);
	assert.match(html, /Continue after filing/);
	assert.match(page, /render_game_to_text/);
	assert.match(page, /advanceTime/);
	assert.match(page, /buildAccessibleGameStatus/);
	assert.match(page, /campaignStage === "senior_annual"/);
	assert.match(page, /campaignStage === "senior_quarter"/);
	assert.match(page, /campaignStage === "contract_board"/);
	assert.match(page, /recordValue\(state\.contract_board\)/);
	assert.match(page, /recordValue\(state\.contract_planning\)/);
	assert.match(page, /recordValue\(state\.campus_portfolio\)/);
	assert.match(page, /recordValue\(state\.campus_portfolio_planner\)/);
	assert.match(page, /recordValue\(state\.campus_portfolio_reveal\)/);
	assert.match(page, /recordValue\(contractBoard\.standing\)/);
	assert.match(page, /recordValue\(contractBoard\.accreditation\)/);
	assert.match(page, /press 1 through 3 to select a binder and inspect its lane mix, timed arrivals, premium, and breach charge/);
	assert.match(page, /Objective: press C to open the morning briefing/);
	assert.match(page, /activeContract\.base_premium_cents/);
	assert.match(page, /activeContract\.service_coop_bonus_cents/);
	assert.match(page, /activeContract\.premium_cents/);
	assert.match(page, /activeContractObjective\(activeContract, completed, required\)/);
	assert.match(page, /Optional Career Sponsorship available/);
	assert.match(page, /firstClutch\.first_hen_prelude === true/);
	assert.match(page, /open \$\{firstHenName\}'s file before choosing the flock policy/);
	assert.match(page, /JSON\.parse\(renderedState\)/);
	assert.match(page, /setInterval\(refreshAccessibleGameStatus, 1500\)/);
	assert.doesNotMatch(page, /[·–→…]/);

  assert.match(css, /\.briefing\s*\{[\s\S]*grid-template-columns:\s*repeat\(3,\s*1fr\)/);
  assert.match(css, /@media \(max-width:\s*1000px\)[\s\S]*\.briefing\s*\{\s*grid-template-columns:\s*1fr/);
	assert.match(css, /body\s*\{[\s\S]*overflow-x:\s*clip/);
	assert.match(css, /\.game-stage\s*\{[\s\S]*100dvh - 220px/);
	assert.match(css, /\.control-menu\s*\{[\s\S]*max-width:\s*calc\(100vw - 24px\)/);
	assert.match(css, /@media \(max-height:\s*520px\) and \(orientation:\s*landscape\)[\s\S]*\.masthead, \.intro\s*\{\s*display:\s*none/);
	assert.match(css, /@media \(max-height:\s*520px\) and \(orientation:\s*landscape\)[\s\S]*\.is-focused-play \.game-stage\s*\{[\s\S]*100dvh - 80px/);
	assert.match(css, /\.game-canvas:focus-visible\s*\{[\s\S]*outline:\s*4px solid var\(--yellow\)/);
  assert.match(css, /\.game-canvas:focus-visible\s*\{[\s\S]*outline-offset:\s*-8px/);
	assert.match(css, /\.game-canvas\s*\{[\s\S]*touch-action:\s*none/);
});

test("announces the active Senior career forecast and its largest recoverable cause", async () => {
  const buildStatus = await accessibleStatusBuilder();
  const context = { loaded: true, loadError: "", loadProgress: 100 };
  const careerForecast = {
    visible: true,
    mode: "senior_roost",
    basis: "if_filed_now",
    projected_score: 67,
    score_max: 100,
    projected_marks: 2,
    next_mark_threshold: 80,
    points_to_next_mark: 13,
    largest_recoverable_component: {
      id: "queue_control",
      label: "QUEUE CONTROL",
      recoverable_points: 5,
      cause: "4 overdue files are recorded; 3 or fewer earns full credit.",
    },
  };
  const activeState = {
    campaign_stage: "active",
    campaign_day: 9,
    shift_phase: 1,
    senior_roost: { status: "active", year: 2, quarter: 3, shift_in_quarter: 2 },
    career_forecast: careerForecast,
    orders: { on_track: 2, total: 3 },
  };

  const active = buildStatus(JSON.stringify(activeState), context);
  assert.match(active, /Career forecast if filed now: 67 of 100, 2 projected Roost Marks\./);
  assert.match(active, /Next mark tier 80, 13 points away\./);
  assert.match(active, /Largest recoverable component: QUEUE CONTROL, 5 points\./);
  assert.match(active, /4 overdue files are recorded/);

  const farmerReview = buildStatus(JSON.stringify({
    ...activeState,
    campaign_stage: "farmer",
  }), context);
  assert.doesNotMatch(farmerReview, /Career forecast if filed now/i);

  const probation = buildStatus(JSON.stringify({
    ...activeState,
    senior_roost: { status: "inactive" },
  }), context);
  assert.doesNotMatch(probation, /Career forecast if filed now/i);
});

test("announces Farm Mutual standing, Service Coop economics, and the next live binder action", async () => {
  const buildStatus = await accessibleStatusBuilder();
  const context = { loaded: true, loadError: "", loadProgress: 100 };
  const standing = {
    points: 6,
    rank_label: "SILVER",
    seals: [
      { id: "bronze", earned: true },
      { id: "silver", earned: true },
      { id: "gold", earned: false },
    ],
  };
  const accreditation = {
    level: 2,
    max_level: 3,
    premium_bonus_basis_points: 10_000,
    premium_bonus_percent: 100,
  };
  const active = {
    short_name: "Homestead Clutch",
    required_completed: 3,
    timely_sound_completed: 1,
    base_premium_cents: 1_000,
    service_coop_bonus_cents: 1_000,
    premium_cents: 2_000,
    breach_cents: 750,
    completed_claim_ids: [21],
    scheduled_claims: [
      {
        claim_id: 22,
        released: true,
        rejected: false,
        deadline_minute_of_day: 615,
        deadline_time: "10:15 AM",
      },
      {
        claim_id: 23,
        released: false,
        rejected: false,
        arrival_minute_of_day: 660,
        arrival_time: "11:00 AM",
      },
    ],
  };

  const planning = buildStatus(JSON.stringify({
    campaign_stage: "contract_board",
    campaign_day: 3,
    contract_board: { target_day: 3, standing, accreditation, active },
  }), context);
  assert.match(planning, /Farm Mutual standing SILVER, 6 points, 2 of 3 seals\./);
  assert.match(planning, /Service Coop accreditation level 2 of 3, adding \+100 percent/);
  assert.match(planning, /base premium \$10\.00, Service Coop bonus \$10\.00, total \$20\.00/);
  assert.match(planning, /breach charge \$7\.50/);
  assert.match(planning, /Objective: press C to open the morning briefing\./);

  const running = buildStatus(JSON.stringify({
    campaign_stage: "active",
    campaign_day: 3,
    shift_phase: 1,
    contract_board: { standing, accreditation, active },
  }), context);
	assert.match(running, /Homestead Clutch, Baseline Filing, Standard Terms: 1 of 3 clean folders delivered on time/);
  assert.match(running, /base premium \$10\.00, Service Coop bonus \$10\.00, total \$20\.00/);
  assert.match(running, /Objective: clear the released Farm Mutual folder due at 10:15 AM, then protect the regular clutch\./);

  const awaitingArrival = buildStatus(JSON.stringify({
    campaign_stage: "active",
    campaign_day: 3,
    shift_phase: 1,
    contract_board: {
      standing,
      accreditation,
      active: {
        ...active,
        completed_claim_ids: [21, 22],
        scheduled_claims: [active.scheduled_claims[1]],
      },
    },
  }), context);
  assert.match(awaitingArrival, /Objective: route the regular clutch now and leave capacity for the next Farm Mutual batch at 11:00 AM\./);

  const thresholdMet = buildStatus(JSON.stringify({
    campaign_stage: "active",
    campaign_day: 3,
    shift_phase: 1,
    contract_board: {
      standing,
      accreditation,
      active: { ...active, timely_sound_completed: 3 },
    },
  }), context);
  assert.match(thresholdMet, /Objective: protect the regular clutch until close; the binder threshold is met and its premium will settle then\./);
});

test("announces an authoritative seasonal rider draft with exact settlement terms", async () => {
  const buildStatus = await accessibleStatusBuilder();
  const context = { loaded: true, loadError: "", loadProgress: 100 };
  const effectiveTerms = {
    short_name: "Predator Pool",
    clause_id: "expedited_hatch_rider",
    clause_label: "Expedited Hatch Rider",
    total_claims: 6,
    rush_claims: 3,
    required_completed: 5,
    authored_base_premium_cents: 1_600,
    season_premium_delta_cents: 320,
    clause_premium_delta_cents: 400,
    service_coop_bonus_cents: 2_400,
    premium_cents: 4_720,
    breach_cents: 1_280,
    spendable_after_reserve_cents: 5_720,
  };
  const status = buildStatus(JSON.stringify({
    campaign_stage: "contract_board",
    campaign_day: 9,
    contract_board: {
      target_day: 9,
      season: {
        id: "summer_predator_migration",
        label: "Summer Predator Migration",
        summary: "Predator-loss demand is peaking for three shifts.",
      },
      negotiation_room: { owned: true, level: 1 },
      offers: [{ id: "predator_watch_pool" }],
    },
    contract_planning: {
      selected_offer_id: "predator_watch_pool",
      selected_clause_id: "expedited_hatch_rider",
      effective_terms: effectiveTerms,
      can_sign: true,
    },
  }), context);

  assert.match(status, /Day 9, Summer Predator Migration/);
  assert.match(status, /Predator Pool selected under Expedited Hatch Rider/);
  assert.match(status, /6 folders, 3 rush, 5 clean and on time/);
  assert.match(status, /authored premium \$16\.00, season \+\$3\.20, rider \+\$4\.00, Service Coop bonus \$24\.00, total \$47\.20/);
  assert.match(status, /breach charge \$12\.80, reserve leaves \$57\.20/);
  assert.match(status, /Gold Negotiation Room commissioned/);
  assert.match(status, /Press N to inspect riders, R for standard terms/);
});

test("announces flock-care capital, Rested Flock risk, and effective training terms", async () => {
  const buildStatus = await accessibleStatusBuilder();
  const context = { loaded: true, loadError: "", loadProgress: 100 };
  const flockCare = {
    welfare: 70,
    rested_flock_gate: 72,
    welfare_delta_to_gate: -2,
    wellness_level: 2,
    training_roost_level: 1,
    breaks_active: 2,
    recovery_perch_count: 4,
    training_active: [{ worker_id: 3, lane_id: "appeals" }],
    training_terms: {
      base_sponsorship_cost_cents: 1_200,
      effective_sponsorship_cost_cents: 1_000,
      sponsorship_discount_cents: 200,
      effective_work_multiplier: 0.90,
      work_penalty_percent: 10,
      coaching_xp_bonus: 2,
      wage_bonus_cents: 100,
    },
    next_care_action: {
      facility_id: "wellness_nest_room",
      display_name: "Wellness Nest",
      next_level: 3,
      capital_cost_cents: 14_000,
      maintenance_delta_cents: 400,
      can_purchase: false,
      reason: "Spendable Feed Fund is $12.00 short.",
    },
  };

  const farmerReview = buildStatus(JSON.stringify({
    campaign_stage: "farmer",
    campaign_day: 8,
    flock_care: flockCare,
  }), context);
  assert.match(farmerReview, /Flock care: Wellness Nest level 2, 2 of 4 recovery perches occupied/);
  assert.match(farmerReview, /Training Roost level 1, 1 active training file, sponsorship \$10\.00, 10 percent training penalty/);
  assert.match(farmerReview, /Next care gate: Wellness Nest, level 3, \$140\.00 capital and \+\$4\.00 daily upkeep/);
  assert.match(farmerReview, /Gate: Spendable Feed Fund is \$12\.00 short/);
	assert.match(farmerReview, /open Requisitions to manage capital, provisions, and any named-hen case files/);

  const seniorPlanning = buildStatus(JSON.stringify({
    campaign_stage: "senior_quarter",
    campaign_day: 8,
    senior_roost: { status: "quarter_choice", year: 2, quarter: 1 },
    flock_care: flockCare,
    career_sponsorship: {
      visible: true,
      available_marks: 5,
      mark_cost: 3,
      fund_cost_cents: 1_000,
      training_terms: flockCare.training_terms,
      unavailable_reason: "",
    },
  }), context);
  assert.match(seniorPlanning, /Rested Flock welfare 70 of required 72, 2 short/);
  assert.match(seniorPlanning, /invest 3 marks and \$10\.00/);
  assert.match(seniorPlanning, /10 percent training penalty, coaching \+2 XP, then \+\$1\.00 daily wage/);

  const restedShift = buildStatus(JSON.stringify({
    campaign_stage: "active",
    campaign_day: 8,
    shift_phase: 1,
    flock_care: flockCare,
    contract_board: {
      active: {
        short_name: "Rested Homestead",
        clause_id: "rested_flock_warranty",
        clause_label: "Rested Flock Rider",
        required_completed: 3,
        timely_sound_completed: 1,
        premium_cents: 2_000,
        breach_cents: 900,
      },
    },
  }), context);
  assert.match(restedShift, /Rested Flock Rider/);
  assert.match(restedShift, /Rested Flock welfare 70 of required 72, 2 short/);
});

test("announces frozen Rooster Operations and IT Coop economics without a new shortcut", async () => {
  const buildStatus = await accessibleStatusBuilder();
  const context = { loaded: true, loadError: "", loadProgress: 100 };
  const operations = {
    version: 2,
    rooster_office_level: 2,
    it_coop_level: 2,
    supervision: {
      action_limit: 3,
      actions_used: 1,
      actions_remaining: 2,
      actions: [{ day: 8, worker_id: 0, action_id: "share_credit" }],
      supervisor_payroll_cents: 800,
      surveillance_grievance_millipoints: 1250,
      surveillance_stress_millipoints: 1000,
      surveillance_solidarity_millipoints: 1000,
    },
    automation: {
      enabled: true,
      work_basis_points: 10600,
      work_multiplier: 1.06,
      specialty_grace_minutes: 120,
      recognizes_secondary_specialties: true,
      compliance_exposure_millipoints: 1800,
      ledger_patch_cost_cents: 2600,
      auto_enrolled_workers: 2,
      active_auto_claims: 1,
    },
    manager_roster: [
      {
        name: "Cornelius Claimwell",
        title: "Senior Clutch Manager",
        assignment_label: "Whole Flock",
        posture_label: "Promote Visibility",
        posture_filed: true,
      },
      {
        name: "Bramwell Beakley",
        title: "Acting Lead",
        assignment_label: "At-Risk Hens",
        posture_label: "Chase Quota",
        posture_filed: false,
      },
      {
        name: "Prudence Peckworth",
        title: "Assistant Roost Supervisor",
        assignment_label: "Back Row",
        posture_label: "Audit Everything",
        posture_filed: true,
      },
    ],
    manager_candidates: [
      { name: "Cornelius Claimwell", hired: true },
      { name: "Bramwell Beakley", hired: true },
      { name: "Prudence Peckworth", hired: true },
      { name: "Clover Crowsby", hired: false },
      { name: "Pivot Strutters", hired: false },
      { name: "Byte Bantam", hired: false },
    ],
    management_density: {
      manager_count: 3,
      active_hens: 4,
      meeting_minutes: 50,
      conflicting_directives: 2,
      risk_label: "OVERMANAGED",
    },
    management_reports: {
      today: 3,
      total: 18,
      visibility_today: 1,
      produces_eggs: false,
    },
    next_operations_action: {
      facility_id: "it_coop",
      next_level: 3,
      next_level_name: "Automated Claims Sorter",
      can_purchase: false,
      reason: "Records Annex level 3 is required.",
      cost_cents: 18000,
      maintenance_delta_cents: 400,
      supervisor_payroll_delta_cents: 0,
      added_daily_operating_cents: 400,
    },
  };

  const farmerReview = buildStatus(JSON.stringify({
    campaign_stage: "farmer",
    campaign_day: 8,
    operations,
  }), context);
  assert.match(farmerReview, /Rooster Operations Office level 2: 1 of 3 check-ins used, 2 remaining/);
  assert.match(farmerReview, /supervisor payroll \$8\.00 per day/);
  assert.match(farmerReview, /Surveillance adds 1\.25 points grievance and 1 point stress per hen, plus 1 point flock solidarity per shift/);
  assert.match(farmerReview, /IT Coop level 2: AUTO pace \+6 percent, 120-minute specialty grace, secondary credentials recognized/);
  assert.match(farmerReview, /compliance exposure 1\.8 points per shift and ledger patch \$26\.00/);
  assert.match(farmerReview, /Management roster: Cornelius Claimwell, Senior Clutch Manager, assigned Whole Flock, Promote Visibility/);
  assert.match(farmerReview, /Bramwell Beakley, Acting Lead, assigned At-Risk Hens, posture not yet filed/);
  assert.match(farmerReview, /Density 3 managers for 4 hens, 50 meeting minutes, 2 conflicting directives, overmanaged/);
  assert.match(farmerReview, /3 management reports filed today; management reports produce zero eggs/);
  assert.match(farmerReview, /Successor slate: 3 non-incumbent candidates/);
  assert.match(farmerReview, /Next operations gate: Automated Claims Sorter, level 3, \$180\.00 capital and \+\$4\.00 daily operating cost/);
  assert.match(farmerReview, /Gate: Records Annex level 3 is required/);
  assert.match(farmerReview, /open Requisitions to manage capital, provisions, and any named-hen case files/);

  const running = buildStatus(JSON.stringify({
    campaign_stage: "active",
    campaign_day: 8,
    shift_phase: 1,
    operations,
  }), context);
  assert.match(running, /Rooster Operations: 1 of 3 check-ins filed, 2 remaining/);
  assert.match(running, /IT Coop supports 2 AUTO hens, 1 with active file/);
  assert.match(running, /Management layer: 3 managers for 4 hens, 50 meeting minutes, 2 conflicting directives, 3 reports, zero eggs/);
  assert.doesNotMatch(running, /supervisor payroll|surveillance adds|ledger patch/i);
});

test("announces the canonical Flock Relations review docket and carry risk", async () => {
  const buildStatus = await accessibleStatusBuilder();
  const context = { loaded: true, loadError: "", loadProgress: 100 };
  const farmerReview = buildStatus(JSON.stringify({
    campaign_stage: "farmer",
    campaign_day: 10,
    senior_roost: { status: "active", year: 1, quarter: 2, shift_in_quarter: 1 },
    flock_relations: {
      level: 2,
      capacity: 2,
      resolution_limit: 2,
      resolutions_used_today: 1,
      open_case_count: 1,
      resolved_total: 4,
      denied_total: 1,
      settlement_spend_total_cents: 4_800,
      last_resolution: {
        worker_name: "Mabel",
        action_label: "Fund Remedy",
        cost_cents: 1_600,
      },
    },
  }), context);

  assert.match(farmerReview, /Flock Relations level 2: 1 of 2 case slot open; 1 of 2 review authorizations used/);
  assert.match(farmerReview, /Unresolved cases carry obedience, unity, and named-hen grievance pressure/);
  assert.match(farmerReview, /Last filed disposition: Fund Remedy for Mabel/);
	assert.match(farmerReview, /open Requisitions to manage capital, provisions, and any named-hen case files/);
});

test("announces Flock Provisions stock, seasonal quote, coverage, and spoilage", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const farmerReview = buildStatus(JSON.stringify({
		campaign_stage: "farmer",
		campaign_day: 11,
		feed_procurement: {
			level: 2,
			stock_scoops: 14,
			capacity_scoops: 36,
			next_demand_scoops: 9,
			covered_scoops: 9,
			spot_price_cents: 270,
			season_label: "Winter Feed-Fund Squeeze",
			spoiled_scoops_total: 3,
		},
	}), context);

	assert.match(farmerReview, /Flock Provisions level 2: 14 of 36 scoops stored/);
	assert.match(farmerReview, /covering 9 of 9 next-shift demand; 0 projected spot fallback/);
	assert.match(farmerReview, /\$2\.70 per scoop in Winter Feed-Fund Squeeze/);
	assert.match(farmerReview, /3 scoops have spoiled on the permanent ledger/);

	const spotFallback = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 4,
		shift_phase: 1,
		feed_procurement: {
			level: 0,
			next_demand_scoops: 7,
			spot_price_cents: 180,
			season_label: "Spring Hatch Surge",
		},
	}), context);
	assert.match(spotFallback, /not commissioned; 7 feed scoops will be covered automatically/);
	assert.match(spotFallback, /Spring Hatch Surge spot market at \$1\.80 each/);
});

test("announces the post-credit Farmer Relations Gallery campaign gate and receipt", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const gallery = {
		level: 2,
		campaign_status: "offer_open",
		completed_day: 8,
		standing_points: 14,
		standing_label: "Barnwide",
		attribution: {
			style_id: "individual_merit",
			style_label: "Individual Merit",
			worker_id: 0,
			worker_name: "Mabel",
		},
		shift_evidence: {
			day: 8,
			eggs: 29,
			quota: 24,
			cracked: 2,
			golden: 1,
		},
	};
	const offerOpen = buildStatus(JSON.stringify({
		campaign_stage: "credit",
		campaign_day: 9,
		farmer_relations_gallery: gallery,
	}), context);
	assert.match(offerOpen, /closing credit filed/i);
	assert.match(offerOpen, /Farmer Relations Gallery level 2: public standing Barnwide, 14 points/);
	assert.match(offerOpen, /Closing attribution: Individual Merit for Mabel/);
	assert.match(offerOpen, /Day 8 evidence: 29 of 24 eggs, 2 cracked, 1 golden/);
	assert.match(offerOpen, /Layer Profile, Clutch Results Board, or Farmer's Method/);
	assert.match(offerOpen, /open Flockwatch, publish one campaign, or continue to skip/);

	const filed = buildStatus(JSON.stringify({
		campaign_stage: "credit",
		campaign_day: 9,
		farmer_relations_gallery: {
			...gallery,
			campaign_status: "filed",
			standing_points: 18,
			last_receipt: {
				day: 8,
				campaign_id: "layer_profile",
				campaign_label: "Layer Profile",
				standing_delta: 4,
				cost_cents: 600,
				payout_cents: 0,
				fund_delta_cents: -600,
			},
		},
	}), context);
	assert.match(filed, /Public campaign filed: Layer Profile; standing \+4 to 18, Feed Fund -\$6\.00/);
	assert.match(filed, /Objective: continue to the shift report/);

	const skipped = buildStatus(JSON.stringify({
		campaign_stage: "credit",
		campaign_day: 9,
		farmer_relations_gallery: {
			...gallery,
			campaign_status: "skipped",
		},
	}), context);
	assert.match(skipped, /No public campaign was filed for this closed shift/);
	assert.doesNotMatch(skipped, /authorize a credit decision/i);
});

test("announces Farmgate inventory, frozen route, and exact close settlement", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const status = buildStatus(JSON.stringify({
		campaign_stage: "farmer",
		campaign_day: 12,
		farmgate_dispatch: {
			enabled: true,
			level: 2,
			stock_count: 9,
			storage_capacity_eggs: 24,
			stock_value_cents: 2_450,
			oldest_age_shifts: 2,
			expiring_count: 1,
			active_mandate_label: "COUNTY AUCTION",
			season: { label: "AUTUMN RETENTION AUDIT" },
			last_settlement_receipt: {
				accepted: true,
				sold_eggs: 8,
				settlement_cash_delta_cents: 3_120,
			},
		},
	}), context);

	assert.match(status, /Farmgate Dispatch level 2: 9 of 24 eggs in cold store, worth \$24\.50/);
	assert.match(status, /COUNTY AUCTION under AUTUMN RETENTION AUDIT/);
	assert.match(status, /Oldest lot age 2 shifts; 1 expiring now/);
	assert.match(status, /Last settlement sold 8 eggs for \+\$31\.20/);
	assert.match(status, /Capital Blueprint compares permanent facilities, North Meadow utilities, and the three-deed Campus Portfolio/);
});

test("announces North Meadow land, service commissioning, route-safe placement, and operational benefits", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const planner = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campus_expansion_planner: {
			visible: true,
			selected_socket_id: "service_spine",
			accessible_text: "Service Spine. Route blocked: reserved for flock circulation.",
		},
		campus_portfolio_planner: {
			visible: true,
			selected_parcel_id: "orchard_row",
		},
	}), context);
	assert.match(planner, /Campus Expansion open, service spine selected/);
	assert.match(planner, /Route blocked: reserved for flock circulation/);
	assert.match(planner, /place or relocate the Egg Routing Pod on a route-safe socket/);
	assert.doesNotMatch(planner, /Campus Portfolio open/);

	const land = buildStatus(JSON.stringify({
		campaign_stage: "farmer",
		campaign_day: 6,
		campus_expansion: {
			visible: true,
			parcel_owned: false,
			parcel_quote: {
				cost_cents: 8_500,
				added_daily_cost_cents: 300,
				reason: "Commission Farmgate Dispatch level 1 or reach 12 standing.",
			},
		},
	}), context);
	assert.match(land, /North Meadow land filing: \$85\.00 capital and \$3\.00 per shift/);
	assert.match(land, /Commission Farmgate Dispatch level 1 or reach 12 standing/);

	const operational = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 9,
		shift_phase: 1,
		campus_expansion: {
			visible: true,
			parcel_owned: true,
			services: [
				{ id: "circulation", commissioned: true },
				{ id: "power", commissioned: true },
				{ id: "cold_chain", commissioned: true },
			],
			routing_pod: { placed: true, operational: true, current_socket_id: "meadow_west" },
			claim_capacity_bonus: 6,
			farmgate_capacity_bonus_eggs: 6,
			current_daily_cost_cents: 1_575,
		},
	}), context);
	assert.match(operational, /Egg Routing Pod operational at meadow west: \+6 live-file capacity and \+6 Farmgate cold-storage eggs/);
	assert.match(operational, /recurring cost \$15\.75 per shift/);
});

test("announces portfolio deeds, construction, shared resources, and named-hen staffing", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const campusPortfolio = {
		resources: {
			feed_fund_cents: 50_000,
			spendable_fund_cents: 22_500,
			protected_reserve_cents: 27_500,
			contractor_used: 1,
			contractor_capacity: 2,
			power_used: 3,
			power_capacity: 5,
			cold_used: 1,
			cold_capacity: 2,
		},
		parcels: [
			{ id: "north_meadow", name: "NORTH MEADOW", owned: true },
			{ id: "orchard_row", name: "ORCHARD ROW", owned: true },
			{ id: "creekside_yard", name: "CREEKSIDE YARD", owned: false },
		],
		projects: [
			{
				project_id: 7,
				module_id: "grain_recovery_mill",
				status: "active",
				status_label: "ACTIVE",
				stage_id: "frame",
				stage_label: "FRAME",
				remaining_shifts: 1,
			},
			{
				project_id: 8,
				module_id: "creekside_chilling_exchange",
				status: "queued",
				status_label: "QUEUED",
				stage_id: "queued",
				stage_label: "QUEUED",
				remaining_shifts: 3,
			},
		],
		modules: [
			{
				id: "collection_rail_hub",
				name: "COLLECTION RAIL HUB",
				installed: true,
				worker_id: 0,
				worker_name: "Mabel",
				staffed: true,
				operational: true,
			},
			{ id: "grain_recovery_mill", name: "GRAIN RECOVERY MILL", installed: false },
			{ id: "creekside_chilling_exchange", name: "CREEKSIDE CHILLING EXCHANGE", installed: false },
			{
				id: "contractor_roost",
				name: "CONTRACTOR ROOST",
				installed: true,
				worker_id: -1,
				staffed: false,
				operational: false,
			},
		],
		workers: [
			{ id: 0, name: "Mabel", assigned_module_id: "collection_rail_hub" },
			{ id: 1, name: "Dorothy", assigned_module_id: "" },
		],
		assignments: [
			{ module_id: "collection_rail_hub", worker_id: 0, worker_name: "Mabel" },
		],
	};

	const planner = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campus_portfolio: campusPortfolio,
		campus_portfolio_planner: {
			visible: true,
			selected_parcel_id: "orchard_row",
			selected_pad_id: "orchard_west",
			selected_module_id: "collection_rail_hub",
			accessible_text: "Orchard West Pad ready. Mabel is the current campus perch.",
		},
	}), context);
	assert.match(planner, /Campus Portfolio open, Orchard Row, Orchard West, Collection Rail Hub selected/);
	assert.match(planner, /2 of 3 deeds filed: North Meadow and Orchard Row; awaiting deed: Creekside Yard/);
	assert.match(planner, /Construction queue: Grain Recovery Mill, ACTIVE, FRAME, 1 shift remaining; Creekside Chilling Exchange, QUEUED, 3 shifts remaining/);
	assert.match(planner, /Portfolio resources: Feed Fund \$500\.00, spendable \$225\.00, protected reserve \$275\.00; contractors 1 of 2, power 3 of 5, cold 1 of 2/);
	assert.match(planner, /Campus staffing: Collection Rail Hub staffed by Mabel and operational; Contractor Roost unstaffed and offline/);
	assert.match(planner, /1 of 2 commissioned modules are operational/);
	assert.match(planner, /Orchard West Pad ready\. Mabel is the current campus perch/);
	assert.match(planner, /assign an available named hen after commissioning/);
	assert.match(planner, /North Meadow utility filings remain under North Meadow Details/);

	const running = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 10,
		shift_phase: 1,
		campus_portfolio: campusPortfolio,
		campus_expansion: {
			visible: true,
			parcel_owned: true,
			services: [
				{ id: "circulation", commissioned: true },
				{ id: "power", commissioned: true },
				{ id: "cold_chain", commissioned: true },
			],
			routing_pod: { placed: true, operational: true, current_socket_id: "meadow_west" },
			claim_capacity_bonus: 6,
			farmgate_capacity_bonus_eggs: 6,
			current_daily_cost_cents: 1_575,
		},
	}), context);
	assert.match(running, /Egg Routing Pod operational at meadow west: \+6 live-file capacity and \+6 Farmgate cold-storage eggs/);
	assert.match(running, /Campus portfolio: 2 of 3 deeds filed/);
	assert.match(running, /Campus staffing: Collection Rail Hub staffed by Mabel and operational/);
});

test("prioritizes Capital Blueprint and player-held commissioning narration", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const blueprint = buildStatus(JSON.stringify({
		campaign_stage: "active",
		capital_blueprint: {
			visible: true,
			active_filter_id: "ready",
			selected_facility_id: "farmgate_dispatch_depot",
			inspector_text: "Farmgate Dispatch Depot; ready; capital $120.00.",
		},
	}), context);
	assert.match(blueprint, /Capital Blueprint open, ready filter, farmgate dispatch depot selected/);
	assert.match(blueprint, /preview, pin, or commission the selected parcel/);

	const reveal = buildStatus(JSON.stringify({
		campaign_stage: "active",
		commissioning_reveal: {
			visible: true,
			receipt: {
				facility_name: "FARMGATE DISPATCH DEPOT",
				purchased_level: 1,
				cost_cents: 12_000,
				spendable_after_cents: 8_500,
			},
		},
	}), context);
	assert.match(reveal, /Facility commissioned: FARMGATE DISPATCH DEPOT, level 1/);
	assert.match(reveal, /\$120\.00 capital filed, \$85\.00 spendable Feed Fund remains/);
	assert.match(reveal, /continue to the office or return to Capital Blueprint/);
});

test("announces the transient perch commissioning receipt above the staffing ledger", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const status = buildStatus(JSON.stringify({
		campaign_stage: "active",
		flockwatch: {
			visible: true,
			current_page: "flock",
			current_page_title: "Flock staffing file",
		},
		capacity_commissioning: {
			active: true,
			phase: "commissioning",
			capacity: 5,
			perch_index: 4,
			cost_cents: 2_500,
			added_daily_operating_cents: 200,
		},
	}), context);
	assert.match(status, /^Perch 5 commissioned\./);
	assert.match(status, /\$25\.00 capital filed and \$2\.00 added to the protected operating reserve each shift/);
	assert.match(status, /new workstation is vacant/);
	assert.match(status, /review an applicant or return to the office/);
	assert.doesNotMatch(status, /Flockwatch open/);
});

test("announces a held campus build reveal above campus planners but below fixed commissioning", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const campusReveal = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campus_expansion_planner: {
			visible: true,
			selected_socket_id: "meadow_west",
		},
		campus_portfolio_planner: {
			visible: true,
			selected_parcel_id: "orchard_row",
			selected_pad_id: "orchard_west",
			selected_module_id: "collection_rail_hub",
		},
		campus_portfolio_reveal: {
			visible: true,
			accessible_text: "Collection Rail Hub completed at Orchard West Pad.\n Mabel now commutes to the campus perch.",
		},
	}), context);
	assert.match(campusReveal, /^Campus build reveal open\./);
	assert.match(campusReveal, /Collection Rail Hub completed at Orchard West Pad\. Mabel now commutes to the campus perch\./);
	assert.match(campusReveal, /choose Continue to return to the office, or Return to Portfolio to review the plan/);
	assert.doesNotMatch(campusReveal, /Campus Expansion open|Campus Portfolio open/);

	const fixedReveal = buildStatus(JSON.stringify({
		campaign_stage: "active",
		commissioning_reveal: {
			visible: true,
			receipt: {
				facility_name: "RECORDS ANNEX",
				purchased_level: 2,
				cost_cents: 8_000,
				spendable_after_cents: 6_500,
			},
		},
		campus_portfolio_reveal: {
			visible: true,
			accessible_text: "This campus narration must wait.",
		},
	}), context);
	assert.match(fixedReveal, /^Facility commissioned: RECORDS ANNEX, level 2/);
	assert.doesNotMatch(fixedReveal, /Campus build reveal|This campus narration must wait/);
});

test("prioritizes annual Board Mandate selection before quarterly policy and below campus reveals", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const mandateGateState = {
		campaign_stage: "senior_quarter",
		campaign_day: 18,
		senior_roost: {
			status: "quarter_choice",
			year: 3,
			quarter: 1,
			requires_annual_mandate: true,
			available_roost_marks: 2,
			mandate_seals: 1,
			eligible_mandate_tier: 1,
			mandate_tier_eligibility: { eligible_tier: 1, mandate_seals: 1 },
			mandate_mastery: { mastered_count: 2, total_count: 7 },
			last_annual_review: { year: 2, passed: false, score: 38 },
			annual_mandate_offers: [
				{
					id: "standard_board_book",
					name: "STANDARD BOARD BOOK",
					stake_marks: 0,
					seal_reward: 1,
					mastery_count: 2,
					available: true,
				},
				{
					id: "shell_stewardship",
					name: "SHELL STEWARDSHIP BOOK",
					stake_marks: 0,
					seal_reward: 1,
					mastery_count: 0,
					available: true,
				},
				{
					id: "rested_flock_covenant",
					name: "RESTED FLOCK COVENANT",
					stake_marks: 4,
					seal_reward: 3,
					mastery_count: 0,
					available: false,
					unavailable_reason: "2 more available Roost Marks are required.",
				},
			],
		},
		farm_treasury: {
			rating_label: "STEADY LEDGER",
			credit_rating: 1,
			credit_principal_cents: 7_500,
			credit_limit_cents: 7_500,
			credit_headroom_cents: 0,
			interest_basis_points: 400,
			vendor_arrears_cents: 600,
			interest_arrears_cents: 400,
			total_liabilities_cents: 8_500,
			capital_frozen: true,
		},
		career_sponsorship: {
			visible: true,
			available_marks: 2,
			mark_cost: 3,
		},
	};

	const mandateGate = buildStatus(JSON.stringify(mandateGateState), context);
	assert.match(mandateGate, /^Senior Year 3 annual Board Mandate planning\./);
	assert.match(mandateGate, /3 frozen books; 2 available with 2 available Roost Marks/);
	assert.match(mandateGate, /1 Board Seal, mandate tier 1/);
	assert.match(mandateGate, /Board Book portfolio: 2 of 7 mastered/);
	assert.match(mandateGate, /Recovery year terms: baseline plus two eggs and Farmer Favor minus five/);
	assert.match(mandateGate, /STANDARD BOARD BOOK, mastered 2 times, no mark stake, 1-seal reward, available/);
	assert.match(mandateGate, /SHELL STEWARDSHIP BOOK, new portfolio clear, no mark stake, 1-seal reward, available/);
	assert.match(mandateGate, /RESTED FLOCK COVENANT, new portfolio clear, 4-mark stake, 3-seal reward, locked: 2 more available Roost Marks are required/);
	assert.match(mandateGate, /Farm Treasury Steady Ledger rating: \$75\.00 principal on a \$75\.00 line, \$0\.00 headroom, 4 percent interest per shift/);
	assert.match(mandateGate, /\$85\.00 total liabilities, including \$6\.00 vendor arrears and \$4\.00 interest arrears/);
	assert.match(mandateGate, /Capital filings frozen/);
	assert.match(mandateGate, /press 1 through 3 to inspect a twelve-shift mandate/);
	assert.match(mandateGate, /A no-stake Book files immediately; an advanced stake requires C to confirm/);
	assert.doesNotMatch(mandateGate, /file one available capital policy|Optional Career Sponsorship/);

	const pendingStake = buildStatus(JSON.stringify({
		...mandateGateState,
		senior_roost: {
			...mandateGateState.senior_roost,
			pending_mandate_confirmation: {
				id: "mutual_assurance",
				title: "MUTUAL ASSURANCE GUARANTEE",
				stake_marks: 2,
			},
		},
	}), context);
	assert.match(pendingStake, /^Senior Year 3 annual Board Mandate planning\. MUTUAL ASSURANCE GUARANTEE inspected/);
	assert.match(pendingStake, /2 Roost Marks will be reserved for the twelve-shift Book/);
	assert.match(pendingStake, /Success returns the stake; failure permanently spends it/);
	assert.match(pendingStake, /press C to confirm this stake, or press 1 through 3 to inspect a different Book/);
	assert.doesNotMatch(pendingStake, /Quarterly policy choices|file one available capital policy/);

	const campusReveal = buildStatus(JSON.stringify({
		...mandateGateState,
		campus_portfolio_reveal: {
			visible: true,
			accessible_text: "Contractor Roost framed at Creekside East Pad.",
		},
	}), context);
	assert.match(campusReveal, /^Campus build reveal open\./);
	assert.doesNotMatch(campusReveal, /annual Board Mandate planning|Farm Treasury/);
});

test("announces every Senior quarterly policy with score and active-mandate fit", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const planning = buildStatus(JSON.stringify({
		campaign_stage: "senior_quarter",
		senior_roost: {
			status: "quarter_choice",
			year: 1,
			quarter: 1,
			requires_annual_mandate: false,
			quarterly_policy_offers: [
				{
					id: "merit_grants",
					title: "MERIT GRANTS",
					available: true,
					strategy: {
						score_edge: "COOP OBEDIENCE + TOP-HEN CAREER",
						score_watch: "FARMER FAVOR + FUND BUFFER",
						board_fit: "NO DIRECT TARGET EDGE // WATCH CURRENT PAYROLL",
					},
				},
				{
					id: "flock_dividend",
					title: "FLOCK DIVIDEND",
					available: false,
					unavailable_reason: "$4.00 more spendable Feed Fund is required.",
					strategy: {
						score_edge: "FLOCK WELFARE + QUOTA RELIABILITY",
						score_watch: "FARMER FAVOR + FUND BUFFER",
						board_fit: "EDGE RELIABLE CLUTCH + FLOCK CONTINUITY // WATCH CURRENT PAYROLL",
					},
				},
				{
					id: "harvest_forecast",
					title: "EXECUTIVE HARVEST FORECAST",
					available: true,
					strategy: {
						score_edge: "FARMER FAVOR + FUND BUFFER",
						score_watch: "QUOTA RELIABILITY + FLOCK WELFARE + OBEDIENCE",
						board_fit: "EDGE CURRENT PAYROLL // WATCH RELIABLE CLUTCH + FLOCK CONTINUITY",
					},
				},
			],
		},
	}), context);

	assert.match(planning, /^Senior Year 1, Quarter 1 planning\./);
	assert.match(planning, /Quarterly policy choices: 1, MERIT GRANTS, score edge COOP OBEDIENCE \+ TOP-HEN CAREER/);
	assert.match(planning, /2, FLOCK DIVIDEND, score edge FLOCK WELFARE \+ QUOTA RELIABILITY/);
	assert.match(planning, /Board fit EDGE RELIABLE CLUTCH \+ FLOCK CONTINUITY \/\/ WATCH CURRENT PAYROLL, held: \$4\.00 more spendable Feed Fund is required/);
	assert.match(planning, /3, EXECUTIVE HARVEST FORECAST, score edge FARMER FAVOR \+ FUND BUFFER, score watch QUOTA RELIABILITY \+ FLOCK WELFARE \+ OBEDIENCE/);
	assert.match(planning, /Objective: press 1 through 3 to file one available capital policy after comparing score edge, score watch, and Board fit/);
});

test("announces active annual mandate progress, its blocker, and the live Treasury posture", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const active = buildStatus(JSON.stringify({
		campaign_stage: "active",
		campaign_day: 12,
		shift_phase: 1,
		senior_roost: {
			status: "active",
			year: 2,
			quarter: 2,
			shift_in_quarter: 2,
			annual_mandate_progress: {
				visible: true,
				mandate_name: "EXECUTIVE HARVEST COMMITMENT",
				shifts_recorded: 4,
				shifts_target: 12,
				objectives_met: 1,
				objectives_total: 3,
				stake_marks: 2,
				all_targets_met: false,
				largest_recoverable_blocker: {
					metric: "closing_fund_cents",
					label: "FEED FUND FLOOR",
					comparison: "minimum",
					actual: 4_300,
					target: 6_000,
					gap: 1_700,
				},
			},
		},
		orders: { on_track: 2, total: 3 },
		economy: {
			farm_treasury: {
				rating_label: "FIELD FILE",
				credit_principal_cents: 1_300,
				credit_limit_cents: 2_000,
				credit_headroom_cents: 700,
				interest_percent: 5,
				vendor_arrears_cents: 200,
				interest_arrears_cents: 0,
				total_liabilities_cents: 1_500,
				capital_frozen: false,
			},
		},
	}), context);

	assert.match(active, /Annual Board Mandate EXECUTIVE HARVEST COMMITMENT: 4 of 12 annual shifts filed; 1 of 3 targets currently met; 2 Roost Marks staked/);
	assert.match(active, /Largest blocker: FEED FUND FLOOR, \$43\.00 against a minimum of \$60\.00; \$17\.00 short/);
	assert.match(active, /Farm Treasury Field File rating: \$13\.00 principal on a \$20\.00 line, \$7\.00 headroom, 5 percent interest per shift/);
	assert.match(active, /\$15\.00 total liabilities, including \$2\.00 vendor arrears/);
	assert.match(active, /Capital filings open/);
	assert.match(active, /Objective: route files and keep the objectives on track/);
});

test("announces successful and failed Board Mandate settlement economics at annual review", async () => {
	const buildStatus = await accessibleStatusBuilder();
	const context = { loaded: true, loadError: "", loadProgress: 100 };
	const successful = buildStatus(JSON.stringify({
		campaign_stage: "senior_annual",
		senior_roost: {
			status: "annual_review",
			year: 2,
			available_roost_marks: 7,
			mandate_seals: 4,
			mandate_mastery: { mastered_count: 2, total_count: 7 },
			mandate_success_counts: { mutual_assurance: 1 },
			last_annual_review: {
				score: 73,
				mandate_settlement: {
					mandate_id: "mutual_assurance",
					mandate_name: "MUTUAL ASSURANCE GUARANTEE",
					success: true,
					stake_returned: 2,
					stake_forfeited: 0,
					seal_reward: 2,
					mandate_seals_after: 4,
					available_roost_marks_after: 7,
				},
			},
		},
	}), context);
	assert.match(successful, /^Senior Year 2 annual review, score 73\./);
	assert.match(successful, /Board Mandate settlement: MUTUAL ASSURANCE GUARANTEE fulfilled/);
	assert.match(successful, /2 permanent Board Seals earned and 2 staked Roost Marks returned/);
	assert.match(successful, /4 total Board Seals and 7 available Roost Marks/);
	assert.match(successful, /New Book mastered\. Board Book portfolio: 2 of 7 mastered/);
	assert.match(successful, /Advanced mandate tier 2 unlocked for next-year planning/);
	assert.match(successful, /Objective: acknowledge the annual score and Board Mandate settlement, then open next-year planning/);

	const failed = buildStatus(JSON.stringify({
		campaign_stage: "senior_annual",
		senior_roost: {
			status: "annual_review",
			year: 4,
			mandate_mastery: { mastered_count: 2, total_count: 7 },
			mandate_success_counts: { rested_flock_covenant: 0 },
			last_annual_review: { score: 58 },
			last_mandate_settlement: {
				mandate_id: "rested_flock_covenant",
				mandate_name: "RESTED FLOCK COVENANT",
				success: false,
				stake_returned: 0,
				stake_forfeited: 4,
				seal_reward: 0,
				mandate_seals_after: 1,
				available_roost_marks_after: 0,
			},
		},
	}), context);
	assert.match(failed, /^Senior Year 4 annual review, score 58\./);
	assert.match(failed, /Board Mandate settlement: RESTED FLOCK COVENANT failed/);
	assert.match(failed, /no Board Seal earned and 4 staked Roost Marks were permanently forfeited/);
	assert.match(failed, /1 total Board Seal and 0 available Roost Marks/);
	assert.match(failed, /Board Book portfolio: 2 of 7 mastered/);

	const freeFailed = buildStatus(JSON.stringify({
		campaign_stage: "senior_annual",
		senior_roost: {
			status: "annual_review",
			year: 1,
			available_roost_marks: 0,
			mandate_seals: 0,
			last_annual_review: {
				score: 31,
				mandate_settlement: {
					mandate_name: "STANDARD BOARD BOOK",
					success: false,
					stake_returned: 0,
					stake_forfeited: 0,
					seal_reward: 0,
					mandate_seals_after: 0,
					available_roost_marks_after: 0,
				},
			},
		},
	}), context);
	assert.match(freeFailed, /Board Mandate settlement: STANDARD BOARD BOOK failed/);
	assert.match(freeFailed, /no Board Seal earned and no Roost Marks were at risk/);
});
