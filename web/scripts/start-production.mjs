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

  res.writeHead(200, {
    "Content-Type": contentTypes.get(extname(resolvedPath.candidate).toLowerCase()) ?? "application/octet-stream",
    "Content-Length": String(file.size),
    "Cache-Control": resolvedPath.pathname.startsWith("/assets/")
      ? "public, max-age=31536000, immutable"
      : "no-cache",
    "X-Content-Type-Options": "nosniff",
  });
  if (req.method === "HEAD") {
    res.end();
    return true;
  }
  createReadStream(resolvedPath.candidate).pipe(res);
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

server.listen(port, host, () => {
  console.log(`[pecking-order] Production wrapper running at http://${host}:${port}`);
});

function close() {
  server.close(() => upstream.server.close());
}

process.on("SIGINT", close);
process.on("SIGTERM", close);
