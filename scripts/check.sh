#!/usr/bin/env bash
# One-shot verification for agents and CI: clear caches, build exampleSite
# with --minify, then assert the artifacts that matter. Clean exit = green.
# resources/ goes first: Hugo's processed-image cache does not key on
# images.Text font bytes, so a stale cache produces lying green builds.
set -euo pipefail

cd "$(dirname "$0")/../exampleSite"
rm -rf public resources

fail() { echo "check: FAIL — $1" >&2; exit 1; }

hugo --themesDir ../.. --minify --quiet || fail "example site build failed (run without --quiet to see the error)"

# llms.txt: machine-readable site index generated for agents
[ -s public/llms.txt ] || fail "llms.txt missing or empty"
grep -q "^# sigil-demo" public/llms.txt || fail "llms.txt lacks the site title"
grep -q "^## All posts" public/llms.txt || fail "llms.txt lacks the posts section"

# feed.json: JSON Feed 1.1 alongside RSS
[ -s public/feed.json ] || fail "feed.json missing"

# OG auto card: generated and referenced on a page without any cover
# (patterns are quote-agnostic — --minify strips attribute quotes)
grep -qE 'og:image[^>]*og/base_hu_' \
    public/posts/what-can-change/index.html \
    || fail "og:image auto card missing on what-can-change"

# door marker: the render hook tags external links only
grep -q 'sg-ext' public/posts/what-can-change/index.html \
    || fail "external link missing the sg-ext door marker"
if grep -qE 'href="?/[^ >]*"? class="?sg-ext' public/posts/what-can-change/index.html; then
    fail "internal link wrongly tagged sg-ext"
fi

# opt-in isolation: typography opts into math/mermaid/lightbox,
# pages that don't ask for them must load none of them
for what in katex glightbox mermaid; do
    grep -q "$what" public/posts/typography/index.html \
        || fail "typography page missing $what"
    if grep -q "$what" public/posts/what-can-change/index.html; then
        fail "what-can-change leaks $what — opt-in isolation broken"
    fi
done

# Font budget: the demo ships Latin webfonts; corpus mode (CI) adds a small
# SC subset. Budget 128KB covers latin+corpus with headroom. Any referenced
# CSS or font that is missing fails the check — a dangling import (e.g. a
# wrong relative path) must never pass silently.
command -v python3 >/dev/null 2>&1 || fail "python3 not found — required for font checks"
python3 - <<'PY'
import html, os, re
raw = open("public/posts/typography/index.html", encoding="utf-8").read()
text = html.unescape(re.sub(r"<script[\s\S]*?</script>|<style[\s\S]*?</style>", "", raw))
cps = {ord(c) for c in text if not c.isspace()} | {0x2234}
faces = []
missing = []
def load(path):
    if not os.path.exists(path):
        missing.append(path)
        return
    css = open(path, encoding="utf-8").read()
    for imp in re.findall(r"@import\s+url\([\"']?([^\"')]+)[\"']?\)", css):
        load(os.path.normpath(os.path.join(os.path.dirname(path), imp)))
    for block in re.findall(r"@font-face\s*\{[^}]+\}", css):
        src = re.search(r'url\(["\']?([^"\')]+\.woff2)', block)
        ur = re.search(r'unicode-range:\s*([^;}]+)', block)
        if not src: continue
        ranges = []
        if ur:
            for part in ur.group(1).replace("U+", "").split(","):
                bits = part.strip().split("-")
                try:
                    if len(bits) == 2: ranges.append((int(bits[0],16), int(bits[1],16)))
                    elif len(bits) == 1 and bits[0]: v=int(bits[0],16); ranges.append((v,v))
                except ValueError: pass
        fpath = os.path.normpath(os.path.join(os.path.dirname(path), src.group(1)))
        faces.append((ranges, fpath))
load("public/fonts/ibm-plex/result.css")
if missing:
    print(f"check: FAIL — referenced CSS not found: {missing}")
    raise SystemExit(1)
total = 0
for ranges, fpath in faces:
    if not os.path.exists(fpath):
        print(f"check: FAIL — referenced font not found: {fpath}")
        raise SystemExit(1)
    if not ranges or any(any(a <= c <= b for a, b in ranges) for c in cps):
        total += os.path.getsize(fpath)
kb = total // 1024
budget = int(os.environ.get("FONT_BUDGET_KB", "128"))
if kb > budget:
    print(f"check: FAIL — fonts {kb}KB > budget {budget}KB")
    raise SystemExit(1)
print(f"check: fonts {kb}KB <= {budget}KB")
PY

echo "check: all green"
