#!/usr/bin/env bash
# Start the example site on localhost with an explicit baseURL.
#
# Why this exists. `hugo server` does NOT re-read its startup configuration
# when hugo.toml changes on disk — it keeps serving the baseURL it was launched
# with. The theme's own check.sh builds the demo against the deployed URL
# (https://ouatis.com/hugo-theme-sigil/) via CHECK_BASE_URL, so a preview left
# running across a check.sh run comes back answering with that production host:
# every link in the header points off-box and looks broken in the browser.
#
# Passing --baseURL here is what actually pins it. Verified: the same command
# with an explicit --baseURL renders localhost:1313 and zero ouatis.com; a
# server that lost the flag keeps answering with the deployed host.
#
# Usage: scripts/preview.sh [port]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${1:-1313}"
LOG="${SG_PREVIEW_LOG:-/tmp/hugo-preview.log}"

# Stop whatever holds the port first, so a stale process cannot keep serving.
if pgrep -f "hugo server" >/dev/null 2>&1; then
    pkill -f "hugo server" || true
    sleep 2
fi

# A stale build cache would carry the previous baseURL into the first paint.
# The destination is private to this server on purpose. check.sh builds the same
# site into exampleSite/public with the DEPLOYED baseURL to test deployment
# layout; if the server watched that directory it would republish the
# production-host build the moment check.sh ran, and every header link would
# point off-box. Separate destinations keep the two from fighting.
DEST="$ROOT/exampleSite/public-preview"
rm -rf "$DEST"

cd "$ROOT/exampleSite"
hugo server \
    --themesDir ../.. \
    --baseURL "http://localhost:${PORT}/" \
    --destination "$DEST" \
    --port "$PORT" \
    --bind 127.0.0.1 \
    >"$LOG" 2>&1 &

# Wait for the port to answer rather than sleeping a fixed guess.
for _ in $(seq 1 40); do
    if curl -fsS -o /dev/null "http://127.0.0.1:${PORT}/" 2>/dev/null; then
        break
    fi
    sleep 0.5
done

# Verify the thing that actually broke, not just that a port is open.
bad=$(curl -s "http://127.0.0.1:${PORT}/" | grep -c "ouatis.com" || true)
local=$(curl -s "http://127.0.0.1:${PORT}/" | grep -c "localhost:${PORT}" || true)
if [ "${bad:-0}" -gt 0 ]; then
    echo "preview: FAIL — ${bad} link(s) still point at the deployed host" >&2
    echo "preview: check $LOG" >&2
    exit 1
fi
if [ "${local:-0}" -eq 0 ]; then
    echo "preview: FAIL — no links point at localhost:${PORT}" >&2
    echo "preview: check $LOG" >&2
    exit 1
fi

echo "preview: http://localhost:${PORT}/  (${local} local links, 0 deployed)"
echo "preview: log $LOG"
echo "preview: turn OFF 'reduce motion' or the seal's eyes will not move"
