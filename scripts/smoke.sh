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

# Python: see scripts/lib-python.sh (python3 on Windows is often the Store
# stub that exits 49 with no output).
# shellcheck source=scripts/lib-python.sh
. scripts/lib-python.sh
sg_resolve_python || { echo "smoke: no working python3 — set SG_PYTHON" >&2; exit 1; }
export SG_PY

"$SG_PY" - "$BASE" <<'PY'
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
    "en search":   "/search/?q=typography",
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

        # Search runs entirely in the browser: index.json is fetched, Fuse
        # builds an index, ?q= is read and results are rendered. A static
        # build check can only see the JSON file, so this is the one place
        # that proves the chain from index to visible hit.
        if "search" in name:
            try:
                page.wait_for_selector("#searchResults li.sg-entry", timeout=10000)
            except Exception:
                checks.append("no search results for ?q=typography")
            else:
                hits = page.locator("#searchResults li.sg-entry").count()
                # The visible title lives in the entry's <h3>; the <a> is an
                # empty stretched link carrying only an aria-label.
                title = page.locator("#searchResults li.sg-entry h3").first.inner_text()
                title = title.strip()
                if hits == 0:
                    checks.append("no search results for ?q=typography")
                elif not title:
                    checks.append("a search hit rendered without a title")
                elif "typography" not in title.lower():
                    checks.append(f"first hit for ?q=typography is {title[:40]!r}")

        if checks:
            failures.append(f"{name}: {'; '.join(checks)}")
            print(f"FAIL  {name}: {'; '.join(checks)}")
        else:
            extra = ""
            if "typography" in name:
                extra = f", {page.locator('.katex').count()} katex"
            elif "search" in name:
                extra = f", {page.locator('#searchResults li.sg-entry').count()} hits"
            print(f"ok    {name} (200, no console errors{extra})")
        ctx.close()
    browser.close()

if failures:
    print(f"\nsmoke: FAIL — {len(failures)} page(s)")
    sys.exit(1)
print(f"\nsmoke: all {len(PAGES)} pages clean")
PY
