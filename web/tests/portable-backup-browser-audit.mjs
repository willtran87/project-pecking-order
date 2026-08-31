import assert from "node:assert/strict";
import { mkdir, writeFile } from "node:fs/promises";
import { fileURLToPath } from "node:url";

const { chromium } = await import(process.env.PLAYWRIGHT_MODULE ?? "playwright");

const outputDirectory = new URL("../../output/web-game/portable-backup-browser-audit/", import.meta.url);
await mkdir(outputDirectory, { recursive: true });

const browser = await chromium.launch({
  headless: true,
  args: ["--use-gl=angle", "--use-angle=swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const errors = [];
page.on("console", (message) => {
  if (message.type() === "error") errors.push(`console: ${message.text()}`);
});
page.on("pageerror", (error) => errors.push(`page: ${String(error)}`));

function parseState(value) {
  return typeof value === "string" ? JSON.parse(value) : {};
}

async function state() {
  return parseState(await page.evaluate(() => window.render_game_to_text?.() ?? "{}"));
}

try {
  await page.goto("http://localhost:3000/", { waitUntil: "domcontentloaded" });
  await page.waitForFunction(() => {
    if (typeof window.render_game_to_text !== "function") return false;
    try {
      return JSON.parse(window.render_game_to_text()).loaded === true;
    } catch {
      return false;
    }
  }, { timeout: 45_000 });

  const canvas = page.locator("#canvas");
  await page.keyboard.press("KeyN");
  await page.waitForFunction(() => {
    try {
      return JSON.parse(window.render_game_to_text?.() ?? "{}").campaign_stage === "active";
    } catch {
      return false;
    }
  });
  await page.keyboard.press("F10");
  await page.waitForFunction(() => {
    try {
      return JSON.parse(window.render_game_to_text?.() ?? "{}").settings?.visible === true;
    } catch {
      return false;
    }
  });

  const opened = await state();
  assert.match(opened.settings.accessible_text, /backup export is available/i);
  assert.equal(await page.evaluate(() => typeof window.__pecking_order_choose_backup_file), "function");
  assert.equal(await page.evaluate(() => typeof window.__pecking_order_offer_backup), "function");

  const fileInput = page.locator('input[type="file"][accept=".json,application/json"]');
  await fileInput.setInputFiles({
    name: "browser-bridge.json",
    mimeType: "application/json",
    buffer: Buffer.from("{}", "utf8"),
  });
  await page.waitForFunction(() => {
    try {
      return /Career backup staged/i.test(
        JSON.parse(window.render_game_to_text?.() ?? "{}").settings?.accessible_text ?? "",
      );
    } catch {
      return false;
    }
  });
  const staged = await state();
  assert.match(staged.settings.accessible_text, /awaiting replacement confirmation/i);
  await canvas.screenshot({
    path: fileURLToPath(new URL("staged-confirmation.png", outputDirectory)),
  });

  await page.keyboard.press("Enter");
  await page.waitForFunction(() => {
    try {
      return /Career restore held/i.test(
        JSON.parse(window.render_game_to_text?.() ?? "{}").settings?.accessible_text ?? "",
      );
    } catch {
      return false;
    }
  });
  const rejected = await state();
  assert.match(rejected.settings.accessible_text, /JSON parse|schema_version|save format/i);
  assert.equal(rejected.campaign_stage, "active");
  assert.equal(rejected.checkpoint.has_candidate, true);
  assert.equal(await fileInput.inputValue(), "");

  await fileInput.setInputFiles({
    name: "oversized-backup.json",
    mimeType: "application/json",
    buffer: Buffer.alloc(8 * 1024 * 1024 + 1, 0x20),
  });
  await page.waitForFunction(() => {
    try {
      return /exceeds the 8 MiB safety limit/i.test(
        JSON.parse(window.render_game_to_text?.() ?? "{}").settings?.accessible_text ?? "",
      );
    } catch {
      return false;
    }
  });
  const oversized = await state();
  assert.equal(oversized.campaign_stage, "active");
  assert.equal(oversized.checkpoint.has_candidate, true);
  assert.equal(await fileInput.inputValue(), "");
  await canvas.screenshot({
    path: fileURLToPath(new URL("oversized-rejection.png", outputDirectory)),
  });

  assert.deepEqual(errors, []);
  await writeFile(
    new URL("audit.json", outputDirectory),
    JSON.stringify({
      passed: true,
      stages: {
        opened: opened.settings.accessible_text,
        staged: staged.settings.accessible_text,
        rejected: rejected.settings.accessible_text,
        oversized: oversized.settings.accessible_text,
      },
      campaign_stage: oversized.campaign_stage,
      checkpoint_candidate: oversized.checkpoint.has_candidate,
      errors,
    }, null, 2),
  );
} finally {
  await browser.close();
}
