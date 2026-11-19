import { createReadStream } from "node:fs";
import { stat, readFile } from "node:fs/promises";
import { gzip } from "node:zlib";
import { promisify } from "node:util";
import { createServer, request as requestHttp } from "node:http";
import { extname, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { startProdServer } from "vinext/server/prod-server";

const requestedPort = Number.parseInt(process.env.PORT ?? "3000", 10);
const port = Number.isFinite(requestedPort) ? requestedPort : 3000;
const host = process.env.HOST ?? "0.0.0.0";
const webRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const clientRoot = resolve(webRoot, "dist", "client");
const compress = promisify(gzip);
const compressedGameFiles = new Map();

async function compressedGameFile(path, version) {
  const cached = compressedGameFiles.get(path);
  if (cached?.version === version) return cached.bytes;
  const bytes = readFile(path).then(data => compress(data));
  compressedGameFiles.set(path, { version, bytes });
  try {
    return await bytes;
  } catch (error) {
    compressedGameFiles.delete(path);
    throw error;
  }
}
const contentTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".json", "application/json; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".pck", "application/octet-stream"],
  [".png", "image/png"],
  [".svg", "image/svg+xml"],
  [".webp", "image/webp"],
  [".woff", "font/woff"],
  [".woff2", "font/woff2"],
]);

// Prepare the two large responses while the renderer starts. First visitors
// should not pay the one-off gzip cost before WASM streaming can begin.
// Rebuilt exports still invalidate entries through the normal file validator.
const startupCompression = Promise.all(["index.wasm", "index.pck"].map(async name => {
  try {
    const path = resolve(clientRoot, "game", name);
    const file = await stat(path);
    await compressedGameFile(path, `W/"${file.size.toString(16)}-${file.mtimeMs.toString(16)}"`);
  } catch { /* Missing assets or unavailable compression retain request-time fallback. */ }
}));

const upstream = await startProdServer({
  port: 0,
  host: "127.0.0.1",
  outDir: resolve(webRoot, "dist"),
});

function safeClientPath(rawUrl) {
  let pathname;
  try {
    pathname = decodeURIComponent(new URL(rawUrl ?? "/", "http://localhost").pathname);
  } catch {
    return null;
  }
  if (pathname === "/" || pathname.includes("\0")) return null;
  const relative = pathname.replace(/^\/+/, "");
  if (relative.length === 0 || relative.includes("\0")) return null;
  const candidate = resolve(clientRoot, relative);
  if (candidate !== clientRoot && !candidate.startsWith(`${clientRoot}${sep}`)) return null;
  return { candidate, pathname };
}

async function serveClientFile(req, res) {
  const resolvedPath = safeClientPath(req.url);
  if (resolvedPath == null) return false;

  let file;
  try {
    file = await stat(resolvedPath.candidate);
  } catch {
    return false;
  }
  if (!file.isFile()) return false;

  const etag = `W/"${file.size.toString(16)}-${file.mtimeMs.toString(16)}"`;
  const compressible = ["/game/index.wasm", "/game/index.pck"].includes(resolvedPath.pathname);
  const acceptsGzip = (req.headers["accept-encoding"] ?? "").split(",").some(entry => {
    const [coding, ...parameters] = entry.trim().split(";");
    const quality = parameters.find(value => value.trim().startsWith("q="));
    return coding === "gzip" && (quality === undefined || Number(quality.trim().slice(2)) > 0);
  });
  const headers = {
    "Content-Type": contentTypes.get(extname(resolvedPath.candidate).toLowerCase()) ?? "application/octet-stream",
    "Content-Length": String(file.size),
    "Cache-Control": resolvedPath.pathname.startsWith("/assets/")
      ? "public, max-age=31536000, immutable"
      : "no-cache",
    "X-Content-Type-Options": "nosniff",
    "ETag": etag,
    "Last-Modified": file.mtime.toUTCString(),
  };
  if (compressible) headers["Vary"] = "Accept-Encoding";
  // Revalidate stable URLs so a reload reuses the engine/assets, while rebuilt
  // exports are picked up immediately instead of mixing versions in the cache.
  const matches = req.headers["if-none-match"]?.split(",").map(value => value.trim());
  if ((req.method === "GET" || req.method === "HEAD") && (matches?.includes(etag) || matches?.includes("*"))) {
    delete headers["Content-Length"];
    res.writeHead(304, headers);
    res.end();
    return true;
  }
  if (compressible && acceptsGzip) {
    try {
      const compressed = await compressedGameFile(resolvedPath.candidate, etag);
      headers["Content-Encoding"] = "gzip";
      headers["Content-Length"] = String(compressed.length);
      res.writeHead(200, headers);
      res.end(req.method === "HEAD" ? undefined : compressed);
      return true;
    } catch {
      // An unavailable compression cache must never prevent the game loading.
    }
  }
  res.writeHead(200, headers);
  if (req.method === "HEAD") {
    res.end();
    return true;
  }
  const stream = createReadStream(resolvedPath.candidate);
  stream.on("error", () => res.destroy());
  res.on("close", () => stream.destroy());
  stream.pipe(res);
  return true;
}

function proxyToVinext(req, res) {
  const upstreamRequest = requestHttp(
    {
      host: "127.0.0.1",
      port: upstream.port,
      method: req.method,
      path: req.url,
      headers: {
        ...req.headers,
        host: `127.0.0.1:${upstream.port}`,
      },
    },
    (upstreamResponse) => {
      res.writeHead(
        upstreamResponse.statusCode ?? 502,
        upstreamResponse.statusMessage,
        upstreamResponse.headers,
      );
      upstreamResponse.pipe(res);
    },
  );
  upstreamRequest.on("error", (error) => {
    if (!res.headersSent) res.writeHead(502, { "Content-Type": "text/plain; charset=utf-8" });
    res.end(`Production renderer unavailable: ${error.message}`);
  });
  req.pipe(upstreamRequest);
}

const server = createServer(async (req, res) => {
  if (await serveClientFile(req, res)) return;
  proxyToVinext(req, res);
});

await startupCompression;
server.listen(port, host, () => {
  console.log(`[pecking-order] Production wrapper running at http://${host}:${port}`);
});

function close() {
  server.close(() => upstream.server.close());
}

process.on("SIGINT", close);
process.on("SIGTERM", close);
