#!/usr/bin/env bash
# Smoke test: load the demo in a real headless browser and assert the things a
# static build check cannot — that JS actually ran (KaTeX renders, sidenotes
# flip), that there are no console errors, and that every language returns 200.
# This is the complement to check.sh: check.sh verifies build output; this
# verifies the built site behaves in a browser.
#
# Usage:  bash scripts/smoke.sh          # against the deployed demo
#         SMOKE_BASE=http://127.0.0.1:8899/hugo-theme-sigil bash scripts/smoke.sh
set -euo pipefail

BASE="${SMOKE_BASE:-https://ouatis.com/hugo-theme-sigil}"
cd "$(dirname "$0")/.."

python3 - "$BASE" <<'PY'
import sys
from playwright.sync_api import sync_playwright

base = sys.argv[1].rstrip("/")
# The pages a first-time visitor actually hits, per language.
PAGES = {
    "en home":     "",
    "zh-cn home":  "/zh-cn/",
    "ja home":     "/ja/",
    "en typography": "/posts/typography/",
    "zh typography": "/zh-cn/posts/typography/",
    "ja typography": "/ja/posts/typography/",
    "en docs":     "/docs/",
    "zh docs":     "/zh-cn/docs/",
    "ja docs":     "/ja/docs/",
}
# Console errors that are noise, not the site's fault (e.g. a pinned CDN ping).
IGNORE = ("Failed to load resource", "net::ERR")

failures = []
with sync_playwright() as p:
    browser = p.chromium.launch()
    for name, path in PAGES.items():
        ctx = browser.new_context()
        page = ctx.new_page()
        errors = []
        page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
        resp = page.goto(base + path, wait_until="networkidle")
        page.wait_for_timeout(800)
        status = resp.status if resp else 0
        real_errors = [e for e in errors if not any(ig in e for ig in IGNORE)]

        checks = []
        if status != 200:
            checks.append(f"HTTP {status}")
        if real_errors:
            checks.append(f"{len(real_errors)} console error(s): {real_errors[0][:80]}")

        # Typography pages must actually render math (KaTeX runs on DOMContentLoaded)
        # and carry sidenote markers.
        if "typography" in name:
            katex = page.locator(".katex").count()
            if katex == 0:
                checks.append("no .katex rendered")
            if page.locator(".sidenote-number").count() == 0:
                checks.append("no sidenote markers")

        if checks:
            failures.append(f"{name}: {'; '.join(checks)}")
            print(f"FAIL  {name}: {'; '.join(checks)}")
        else:
            extra = f", {page.locator('.katex').count()} katex" if "typography" in name else ""
            print(f"ok    {name} (200, no console errors{extra})")
        ctx.close()
    browser.close()

if failures:
    print(f"\nsmoke: FAIL — {len(failures)} page(s)")
    sys.exit(1)
print(f"\nsmoke: all {len(PAGES)} pages clean")
PY
