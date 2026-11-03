#!/usr/bin/env bash
# Smoke test: load the demo in a real headless browser and assert the things a
# static build check cannot — that JS actually ran (KaTeX renders, sidenotes
# flip), that search renders a hit, that the extended page set returns 200, and
# that axe-core finds no accessibility violations in either theme.
# This is the complement to check.sh: check.sh verifies build output; this
# verifies the built site behaves in a browser.
#
# axe-core is injected from the Python package axe-playwright-python (installed
# in CI), not from a vendored JS copy:
#     python -m pip install axe-playwright-python
#
# Usage:  bash scripts/smoke.sh          # against the deployed demo
#         SMOKE_BASE=http://127.0.0.1:8899 bash scripts/smoke.sh
set -euo pipefail

BASE="${SMOKE_BASE:-https://ouatis.com/hugo-theme-sigil}"
cd "$(dirname "$0")/.."

# Python: see scripts/lib-python.sh (python3 on Windows is often the Store
# stub that exits 49 with no output).
# shellcheck source=scripts/lib-python.sh
. scripts/lib-python.sh
sg_resolve_python || { echo "smoke: no working python3 — set SG_PYTHON" >&2; exit 1; }
export SG_PY
# axe-playwright-python reads its bundled axe.min.js with Path.read_text(), so
# on a non-UTF-8 locale (cp936 on Chinese Windows) the import dies decoding the
# file before any check runs. Python UTF-8 mode fixes the import; force UTF-8
# output too so failure messages with em dashes are readable (AGENTS.md #8).
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8

"$SG_PY" - "$BASE" <<'PY'
import sys

from playwright.sync_api import sync_playwright

try:
    from axe_playwright_python.sync_playwright import Axe
except ImportError:
    sys.exit(
        "smoke: axe-playwright-python is required — "
        "install it with `python -m pip install axe-playwright-python`"
    )

base = sys.argv[1].rstrip("/")

# Every route a visitor can land on, plus the pages the sitemap hides behind
# links. The selector is asserted to exist: a 200 with an empty <main> is not a
# working page. 404 may be served as 404 by a static host, so it accepts both.
PAGES = [
    ("en home",           "",                          "#main-content",  {200}),
    ("zh-cn home",        "/zh-cn/",                   "#main-content",  {200}),
    ("ja home",           "/ja/",                      "#main-content",  {200}),
    ("en typography",     "/posts/typography/",        ".katex",          {200}),
    ("zh typography",     "/zh-cn/posts/typography/",  ".katex",          {200}),
    ("ja typography",     "/ja/posts/typography/",     ".katex",          {200}),
    ("en docs",           "/docs/",                    ".post-content",   {200}),
    ("zh docs",           "/zh-cn/docs/",              ".post-content",   {200}),
    ("ja docs",           "/ja/docs/",                 ".post-content",   {200}),
    ("en archives",       "/archives/",                ".archive-entry-title", {200}),
    ("en tags",           "/tags/",                    ".terms-tags",     {200}),
    ("en tag demo",       "/tags/demo/",               ".post-entry",     {200}),
    ("en about",          "/about/",                   ".post-content",   {200}),
    ("en api",            "/api/",                     ".post-content",   {200}),
    ("en config example", "/config-example/",          ".post-content",   {200}),
    ("404",               "/404.html",                 "#lost-lane-title", {200, 404}),
    ("en search",         "/search/?q=typography",     "#searchResults li.sg-entry", {200}),
]

# Console errors that are noise, not the site's fault (e.g. a pinned CDN ping).
IGNORE = ("Failed to load resource", "net::ERR")

# The theme switches by setting data-theme on <html>. Driving the attribute
# directly is deterministic and, unlike prefers-color-scheme emulation, proves
# both palettes from one page load (same DOM, same scripts, same build).
THEMES = ("light", "dark")

axe = Axe()
failures = 0
axe_core_version = None


def axe_snapshot(theme, violations):
    lines = []
    for violation in violations:
        impact = violation.get("impact") or "unknown"
        nodes = violation["nodes"]
        lines.append(f"axe[{theme}] {violation['id']} ({impact}, {len(nodes)} node(s))")
        for node in nodes[:3]:
            target = " ".join(node.get("target") or ["?"])
            lines.append(f"    target: {target}")
        if len(nodes) > 3:
            lines.append(f"    ... +{len(nodes) - 3} more node(s)")
    return lines


with sync_playwright() as p:
    browser = p.chromium.launch()
    ctx = browser.new_context()
    for name, path, selector, allowed_status in PAGES:
        page = ctx.new_page()
        errors = []
        page.on("console", lambda m: errors.append(m.text) if m.type == "error" else None)
        resp = page.goto(base + path, wait_until="networkidle")
        page.wait_for_timeout(800)
        status = resp.status if resp else 0
        real_errors = [e for e in errors if not any(ig in e for ig in IGNORE)]

        issues = []
        if status not in allowed_status:
            issues.append(f"HTTP {status}")
        if real_errors:
            issues.append(f"{len(real_errors)} console error(s): {real_errors[0][:80]}")

        # A 200 with no page body is a broken route, not a pass.
        try:
            page.wait_for_selector(selector, timeout=10000)
        except Exception:
            issues.append(f"missing selector {selector!r}")

        # Typography pages must actually render math (KaTeX runs on
        # DOMContentLoaded) and carry sidenote markers.
        if "typography" in name:
            page.wait_for_selector(".katex", timeout=10000)
            if page.locator(".sidenote-number").count() == 0:
                issues.append("no sidenote markers")

        # Search runs entirely in the browser: index.json is fetched, Fuse
        # builds an index, ?q= is read and results are rendered. A static
        # build check can only see the JSON file, so this is the one place
        # that proves the chain from index to visible hit.
        if "search" in name:
            hits = page.locator("#searchResults li.sg-entry").count()
            if hits == 0:
                issues.append("no search results for ?q=typography")
            else:
                # The visible title lives in the entry's <h3>; the <a> is an
                # empty stretched link carrying only an aria-label.
                title = page.locator("#searchResults li.sg-entry h3").first.inner_text().strip()
                if not title:
                    issues.append("a search hit rendered without a title")
                elif "typography" not in title.lower():
                    issues.append(f"first hit for ?q=typography is {title[:40]!r}")

        # Freeze transitions/animations before axe: a mid-fade element can
        # report a half-faded color as a contrast failure. Inject first, then
        # give the whole document 250ms to settle before the first audit.
        page.add_style_tag(
            content="*, *::before, *::after { transition: none !important; animation: none !important; }"
        )
        page.wait_for_timeout(250)

        violations_by_theme = {}
        for theme in THEMES:
            page.evaluate(
                "(theme) => document.documentElement.setAttribute('data-theme', theme)",
                theme,
            )
            page.wait_for_timeout(250)
            try:
                violations = axe.run(page).response["violations"]
            except Exception as exc:
                issues.append(f"axe[{theme}] failed: {exc}")
                violations = []
            violations_by_theme[theme] = violations
            if axe_core_version is None:
                try:
                    axe_core_version = page.evaluate("axe.version")
                except Exception:
                    pass

        page_failed = bool(issues) or any(violations_by_theme.values())
        if page_failed:
            failures += 1
            print(f"FAIL  {name}")
            for issue in issues:
                print(f"  {issue}")
            for theme in THEMES:
                for line in axe_snapshot(theme, violations_by_theme[theme]):
                    print(f"  {line}")
        else:
            extra = ""
            if "typography" in name:
                extra = f", {page.locator('.katex').count()} katex"
            elif "search" in name:
                extra = f", {page.locator('#searchResults li.sg-entry').count()} hits"
            print(
                f"ok    {name} (HTTP {status}, no console errors{extra}, "
                f"axe clean light+dark)"
            )
        page.close()
    ctx.close()
    browser.close()

if failures:
    print(f"\nsmoke: FAIL — {failures} page(s) with errors")
    sys.exit(1)
print(
    f"\nsmoke: all {len(PAGES)} pages clean in {len(THEMES)} themes "
    f"({len(PAGES) * len(THEMES)} axe audits, 0 violations, "
    f"axe-core {axe_core_version})"
)
PY
