import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { spawn } from "node:child_process";
import { readFile } from "node:fs/promises";
import { createServer } from "node:net";
import { dirname, resolve } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const webRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");

async function availablePort() {
  const probe = createServer();
  await new Promise((resolveListen, reject) => {
    probe.once("error", reject);
    probe.listen(0, "127.0.0.1", resolveListen);
  });
  const address = probe.address();
  const port = typeof address === "object" && address != null ? address.port : 0;
  await new Promise((resolveClose) => probe.close(resolveClose));
  return port;
}

function waitForReady(child) {
  return new Promise((resolveReady, reject) => {
    let output = "";
    const timer = setTimeout(() => reject(new Error(`production server did not start:\n${output}`)), 20_000);
    const append = (chunk) => {
      output += chunk.toString();
      if (output.includes("[pecking-order] Production wrapper running")) {
        clearTimeout(timer);
        resolveReady();
      }
    };
    child.stdout.on("data", append);
    child.stderr.on("data", append);
    child.once("exit", (code) => {
      clearTimeout(timer);
      reject(new Error(`production server exited ${code}:\n${output}`));
    });
  });
}

test("production wrapper serves the rendered shell and complete Godot payload", { timeout: 30_000 }, async () => {
  const port = await availablePort();
  const child = spawn(process.execPath, ["scripts/start-production.mjs"], {
    cwd: webRoot,
    env: { ...process.env, HOST: "127.0.0.1", PORT: String(port) },
    stdio: ["ignore", "pipe", "pipe"],
  });

  try {
    await waitForReady(child);

    const rootResponse = await fetch(`http://127.0.0.1:${port}/`);
    assert.equal(rootResponse.status, 200);
    const rootHtml = await rootResponse.text();
    assert.match(rootHtml, /PECKING ORDER/);

    const bootstrapPath = rootHtml.match(/import\("([^"]+\.js)"\)/)?.[1];
    assert.ok(bootstrapPath, "rendered shell should reference its hashed bootstrap module");
    const bootstrapResponse = await fetch(`http://127.0.0.1:${port}${bootstrapPath}`);
    assert.equal(bootstrapResponse.status, 200);
    assert.match(bootstrapResponse.headers.get("content-type") ?? "", /javascript/);
    assert.match(
      bootstrapResponse.headers.get("cache-control") ?? "",
      /immutable/,
      "hashed client modules should be served with immutable caching",
    );
    assert.ok((await bootstrapResponse.arrayBuffer()).byteLength > 0);

    const stylesheetPath = rootHtml.match(/href="([^"]+\.css)"/)?.[1];
    assert.ok(stylesheetPath, "rendered shell should reference its hashed stylesheet");
    const stylesheetResponse = await fetch(`http://127.0.0.1:${port}${stylesheetPath}`);
    assert.equal(stylesheetResponse.status, 200);
    assert.match(stylesheetResponse.headers.get("content-type") ?? "", /text\/css/);
    assert.ok((await stylesheetResponse.arrayBuffer()).byteLength > 0);

    const expectedPayload = await readFile(resolve(webRoot, "public", "game", "index.pck"));
    const payloadResponse = await fetch(`http://127.0.0.1:${port}/game/index.pck`);
    assert.equal(payloadResponse.status, 200);
    assert.equal(payloadResponse.headers.get("content-type"), "application/octet-stream");
    assert.equal(payloadResponse.headers.get("x-content-type-options"), "nosniff");
    const servedPayload = Buffer.from(await payloadResponse.arrayBuffer());
    assert.equal(servedPayload.length, expectedPayload.length);
    assert.equal(
      createHash("sha256").update(servedPayload).digest("hex"),
      createHash("sha256").update(expectedPayload).digest("hex"),
    );
  } finally {
    child.kill("SIGTERM");
    await new Promise((resolveExit) => {
      if (child.exitCode != null) {
        resolveExit();
        return;
      }
      const killTimer = setTimeout(() => {
        child.kill("SIGKILL");
        resolveExit();
      }, 5_000);
      child.once("exit", () => {
        clearTimeout(killTimer);
        resolveExit();
      });
    });
  }
});
