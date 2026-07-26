import assert from "node:assert/strict";
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

const url = process.argv[2] ?? "http://localhost:3000/?build=notification-preferences-audit";
const outputDirectory = path.resolve(
  process.argv[3] ?? "../output/web-game/notification-preferences-audit",
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

async function state() {
  return JSON.parse(await page.evaluate(() => window.render_game_to_text?.() ?? "{}"));
}

async function waitForState(predicateSource, label, timeout = 30_000) {
  try {
    await page.waitForFunction((source) => {
      try {
        const snapshot = JSON.parse(window.render_game_to_text?.() ?? "{}");
        return Function("snapshot", `return (${source})(snapshot);`)(snapshot);
      } catch {
        return false;
      }
    }, predicateSource, { timeout });
  } catch {
    const latest = await state();
    throw new Error(`${label} timed out; latest=${JSON.stringify({
      stage: latest.campaign_stage,
      shiftPhase: latest.shift_phase,
      feedPartyActive: latest.production?.feed_party_active,
      camera: latest.camera,
      notifications: latest.notifications,
      settings: {
        visible: latest.settings?.visible,
        noticeLevel: latest.settings?.notice_level,
        browserMirrorStatus: latest.settings?.browser_mirror_status,
      },
    })}`);
  }
  return state();
}

async function clickAuthored(x, y) {
  const bounds = await page.locator("#canvas").boundingBox();
  assert.ok(bounds, "the Godot canvas must remain mounted");
  await page.mouse.click(
    bounds.x + bounds.width * x / 1280,
    bounds.y + bounds.height * y / 720,
  );
}

async function openSettings() {
  const canvas = page.locator("#canvas");
  await canvas.click({ position: { x: 8, y: 8 } });
  await page.keyboard.press("F10");
  return waitForState(
    "snapshot => snapshot.settings?.visible === true",
    "Settings open",
  );
}

async function focusNoticeLevelSelector() {
  // Settings opens on its Return button. Ten audio controls and the first five
  // display selectors precede the sixth selector, Transient Notices.
  for (let index = 0; index < 16; index += 1) await page.keyboard.press("Tab");
}

async function chooseNextNoticeLevel(expected) {
  await page.keyboard.press("Enter");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Enter");
  return waitForState(
    `snapshot => snapshot.settings?.notice_level === '${expected}' && snapshot.settings?.browser_mirror_status === 'saved'`,
    `${expected} notice preference save`,
  );
}

const evidence = {
  url,
  priorityMode: {},
  archiveOnlyMode: {},
  persistence: [],
  errors,
};

try {
  await page.goto(url, { waitUntil: "domcontentloaded" });
  await waitForState(
    "snapshot => snapshot.loaded === true && snapshot.campaign_stage === 'title'",
    "fresh title boot",
    90_000,
  );
  await clickAuthored(640, 594);
  await waitForState(
    "snapshot => snapshot.campaign_stage === 'active'",
    "new campaign activation",
  );
  await page.keyboard.press("Enter");
  await page.waitForTimeout(500);
  await page.keyboard.press("Digit1");
  await page.keyboard.press("Enter");
  await waitForState(
    "snapshot => snapshot.shift_phase === 1 && snapshot.pending_decision_kind === '' && snapshot.first_clutch?.visible === true",
    "opening decision with First Clutch visible",
    20_000,
  );

  const opened = await openSettings();
  assert.equal(opened.settings.notice_level, "all");
  assert.match(opened.settings.accessible_text, /transient notices all/i);
  await focusNoticeLevelSelector();
  await page.screenshot({
    path: path.join(outputDirectory, "notice-level-all.png"),
    fullPage: true,
  });
  const priority = await chooseNextNoticeLevel("priority");
  assert.match(priority.settings.accessible_text, /transient notices priority/i);
  evidence.priorityMode.setting = priority.settings.notice_level;
  await page.waitForTimeout(400);
  await page.screenshot({
    path: path.join(outputDirectory, "notice-level-priority.png"),
    fullPage: true,
  });

  await page.keyboard.press("F10");
  await waitForState(
    "snapshot => snapshot.settings?.visible === false",
    "return to opening floor",
  );
  await page.locator("#canvas").press("KeyP");
  const funded = await waitForState(
    "snapshot => snapshot.production?.feed_party_active === true && snapshot.notifications?.recent?.some(entry => entry.priority === 'milestone' && entry.copy.includes('MANDATORY FEED PARTY'))",
    "funded Feed Party milestone archive",
  );
  evidence.priorityMode.funded = funded.notifications;

  // Exercise the same allow-listed semantic action used by the touch wrapper.
  // This avoids a focused worker card consuming the physical number key while
  // still routing through Office's authored pause/speed-lock behavior.
  await page.evaluate(() => window.__pecking_order_mobile_action?.("pause"));
  const importantNotice = await waitForState(
    "snapshot => snapshot.notifications?.toast_visible === true && snapshot.notifications?.toast_priority === 'action' && snapshot.notifications?.toast_copy?.includes('CLOCK LOCKED')",
    "priority action toast",
  );
  evidence.priorityMode.important = importantNotice.notifications;

  await page.evaluate(() => window.__pecking_order_mobile_action?.("cycle_hen"));
  const routineNotice = await waitForState(
    "snapshot => snapshot.notifications?.toast_visible === true && snapshot.notifications?.toast_priority === 'action' && snapshot.notifications?.latest_priority === 'routine' && snapshot.notifications?.recent?.some(entry => entry.priority === 'routine')",
    "routine notice archived behind held action",
  );
  const labels = routineNotice.notifications.recent.map((entry) => entry.label);
  assert.ok(labels.includes("MILESTONE"), "the recent record must retain the funded Feed Party milestone");
  assert.ok(labels.includes("ACTION"), "the recent record must retain the actionable clock notice");
  assert.ok(labels.includes("ROUTINE"), "the recent record must retain the muted routine clock receipt");
  evidence.priorityMode.routine = routineNotice.notifications;
  await page.screenshot({
    path: path.join(outputDirectory, "priority-routine-archived.png"),
    fullPage: true,
  });
  const settled = await waitForState(
    "snapshot => snapshot.notifications?.toast_visible === false && snapshot.notifications?.latest_priority === 'routine'",
    "priority toast hold expiry",
    90_000,
  );
  evidence.priorityMode.settled = settled.notifications;

  await page.reload({ waitUntil: "domcontentloaded" });
  const priorityRestored = await waitForState(
    "snapshot => snapshot.loaded === true && snapshot.settings?.notice_level === 'priority' && snapshot.settings?.browser_mirror_status === 'loaded'",
    "priority preference restoration",
    60_000,
  );
  evidence.persistence.push({
    level: priorityRestored.settings.notice_level,
    browserMirrorStatus: priorityRestored.settings.browser_mirror_status,
  });

  await openSettings();
  await focusNoticeLevelSelector();
  await page.screenshot({
    path: path.join(outputDirectory, "notice-level-priority-restored.png"),
    fullPage: true,
  });
  const archiveOnly = await chooseNextNoticeLevel("archive_only");
  assert.match(archiveOnly.settings.accessible_text, /transient notices archive only/i);
  evidence.archiveOnlyMode.setting = archiveOnly.settings.notice_level;
  await page.waitForTimeout(400);
  await page.screenshot({
    path: path.join(outputDirectory, "notice-level-archive-only.png"),
    fullPage: true,
  });

  await page.keyboard.press("F10");
  await page.reload({ waitUntil: "domcontentloaded" });
  const archiveRestored = await waitForState(
    "snapshot => snapshot.loaded === true && snapshot.settings?.notice_level === 'archive_only' && snapshot.settings?.browser_mirror_status === 'loaded'",
    "archive-only preference restoration",
    60_000,
  );
  evidence.persistence.push({
    level: archiveRestored.settings.notice_level,
    browserMirrorStatus: archiveRestored.settings.browser_mirror_status,
  });
} finally {
  await browser.close();
}

fs.writeFileSync(
  path.join(outputDirectory, "audit.json"),
  JSON.stringify(evidence, null, 2),
);
assert.deepEqual(errors, [], "notification preference audit must produce no browser errors");
