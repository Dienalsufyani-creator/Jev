#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PROJECT_ROOT="$(pwd)"
export PROJECT_ROOT
/usr/bin/time -p test -n "${CAPTURE_URL:-}" || { echo "Set CAPTURE_URL and CAPTURE_DIR." >&2; exit 1; }
/usr/bin/time -p test -n "${CAPTURE_DIR:-}" || { echo "Set CAPTURE_URL and CAPTURE_DIR." >&2; exit 1; }
/usr/bin/time -p test -n "${RUNTIME_DIR:-}" || { echo "Set RUNTIME_DIR." >&2; exit 1; }
/usr/bin/time -p test -f "${RUNTIME_DIR}/scripts/default-capture.mjs" || { echo "Missing default-capture.mjs in RUNTIME_DIR." >&2; exit 1; }
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p node "${RUNTIME_DIR}/scripts/default-capture.mjs"
/usr/bin/time -p test -f "$CAPTURE_DIR/final-desktop.png" || { echo "Capture did not produce final-desktop.png" >&2; exit 1; }
/usr/bin/time -p test -f "$CAPTURE_DIR/final-mobile.png" || { echo "Capture did not produce final-mobile.png" >&2; exit 1; }
/usr/bin/time -p node -e 'const fs=require("fs"),path=require("path");const dir=process.env.CAPTURE_DIR;for(const n of ["final-desktop.png","final-mobile.png"]){const p=path.join(dir,n);const b=fs.readFileSync(p);if(b.length<24||b.subarray(0,8).toString("hex")!=="89504e470d0a1a0a"){console.error("Capture did not produce a PNG: "+n);process.exit(1);}console.log("verified "+p+" "+b.length+" bytes");}'
