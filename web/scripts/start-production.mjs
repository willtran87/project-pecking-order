import { createReadStream } from "node:fs";
import { stat } from "node:fs/promises";
import { createServer, request as requestHttp } from "node:http";
import { extname, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { startProdServer } from "vinext/server/prod-server";

const requestedPort = Number.parseInt(process.env.PORT ?? "3000", 10);
const port = Number.isFinite(requestedPort) ? requestedPort : 3000;
const host = process.env.HOST ?? "0.0.0.0";
const webRoot = resolve(fileURLToPath(new URL("..", import.meta.url)));
const clientRoot = resolve(webRoot, "dist", "client");
const gameRoot = resolve(clientRoot, "game");
const contentTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".pck", "application/octet-stream"],
  [".png", "image/png"],
]);

const upstream = await startProdServer({
  port: 0,
  host: "127.0.0.1",
  outDir: resolve(webRoot, "dist"),
});

function safeGamePath(rawUrl) {
  let pathname;
  try {
    pathname = decodeURIComponent(new URL(rawUrl ?? "/", "http://localhost").pathname);
  } catch {
    return null;
  }
  if (!pathname.startsWith("/game/")) return null;
  const relative = pathname.slice("/game/".length);
  if (relative.length === 0 || relative.includes("\0")) return null;
  const candidate = resolve(gameRoot, relative);
  if (candidate !== gameRoot && !candidate.startsWith(`${gameRoot}${sep}`)) return null;
  return candidate;
}

async function serveGameFile(req, res) {
  const filePath = safeGamePath(req.url);
  if (filePath == null) return false;

  let file;
  try {
    file = await stat(filePath);
  } catch {
    return false;
  }
  if (!file.isFile()) return false;

  res.writeHead(200, {
    "Content-Type": contentTypes.get(extname(filePath).toLowerCase()) ?? "application/octet-stream",
    "Content-Length": String(file.size),
    "Cache-Control": "no-cache",
    "X-Content-Type-Options": "nosniff",
  });
  if (req.method === "HEAD") {
    res.end();
    return true;
  }
  createReadStream(filePath).pipe(res);
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
  if (await serveGameFile(req, res)) return;
  proxyToVinext(req, res);
});

server.listen(port, host, () => {
  console.log(`[pecking-order] Production wrapper running at http://${host}:${port}`);
});

function close() {
  server.close(() => upstream.server.close());
}

process.on("SIGINT", close);
process.on("SIGTERM", close);
