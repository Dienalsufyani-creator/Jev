#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"
PORT="${PORT:-3000}"
DIST_DIR="$PROJECT_ROOT/dist"
WEB_DIR="${OPENCODE_WEB_DIR:-/home/runner/work/_temp/omgithub-web}"
export PROJECT_ROOT PORT WEB_DIR
/usr/bin/time -p mkdir -p "$DIST_DIR" "$WEB_DIR"
if /usr/bin/time -p test -f "$PROJECT_ROOT/package.json"; then
  if /usr/bin/time -p test -f "$PROJECT_ROOT/package-lock.json"; then
    /usr/bin/time -p npm ci --no-audit --no-fund
  else
    /usr/bin/time -p npm install --no-audit --no-fund
  fi
  if /usr/bin/time -p node -e "const p=require('./package.json');process.exit(p.scripts&&p.scripts.build?0:1)"; then
    /usr/bin/time -p npm run build
  fi
fi
if ! /usr/bin/time -p test -f "$DIST_DIR/index.html"; then
  echo "Static deployment output must contain index.html at $DIST_DIR/index.html" >&2
  exit 1
fi
/usr/bin/time -p node -e 'const fs=require("fs"),path=require("path");const root=process.env.PROJECT_ROOT||process.cwd();const web=process.env.WEB_DIR;const dist=path.join(root,"dist");const out=path.join(web,"deployment-output.json");fs.mkdirSync(web,{recursive:true});fs.writeFileSync(out,JSON.stringify({project:root,directory:dist}));console.log("wrote "+out)'
PROJECT_ROOT="$PROJECT_ROOT" WEB_DIR="$WEB_DIR" PORT="$PORT" /usr/bin/time -p node --eval '
const http = require("http");
const fs = require("fs");
const path = require("path");
const root = process.env.PROJECT_ROOT || process.cwd();
const dist = path.join(root, "dist");
const port = Number(process.env.PORT || "3000");
const mime = {".html":"text/html",".js":"application/javascript",".mjs":"application/javascript",".css":"text/css",".json":"application/json",".svg":"image/svg+xml",".png":"image/png",".jpg":"image/jpeg",".jpeg":"image/jpeg",".webp":"image/webp",".wasm":"application/wasm",".glb":"model/gltf-binary",".ico":"image/x-icon",".txt":"text/plain",".map":"application/json"};
const server = http.createServer((req, res) => {
  try {
    const url = new URL(req.url, "http://localhost");
    let rel = decodeURIComponent(url.pathname);
    if (rel.includes("\0")) { res.writeHead(400); res.end(); return; }
    let filePath = path.resolve(dist, "." + rel);
    if (filePath !== dist && !filePath.startsWith(dist + path.sep)) { res.writeHead(404); res.end("Not found"); return; }
    let stat;
    try { stat = fs.statSync(filePath); } catch { res.writeHead(404); res.end("Not found"); return; }
    if (stat.isDirectory()) filePath = path.join(filePath, "index.html");
    try {
      const data = fs.readFileSync(filePath);
      res.setHeader("Content-Type", mime[path.extname(filePath).toLowerCase()] || "application/octet-stream");
      res.setHeader("Cache-Control", "no-cache");
      res.end(data);
    } catch { res.writeHead(404); res.end("Not found"); }
  } catch { res.writeHead(500); res.end("Error"); }
});
server.listen(port, "0.0.0.0", () => console.log("serving " + dist + " on :" + port));
'
