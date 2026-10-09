#!/usr/bin/env bash
# One-shot verification for agents and CI: clear caches, build exampleSite
# with --minify, then assert the artifacts that matter. Clean exit = green.
# resources/ goes first: Hugo's processed-image cache does not key on
# images.Text font bytes, so a stale cache produces lying green builds.
set -euo pipefail

cd "$(dirname "$0")/../exampleSite"
rm -rf public resources

fail() { echo "check: FAIL — $1" >&2; exit 1; }

# --baseURL mirrors the deployed demo (https://ouatis.com/hugo-theme-sigil/).
# Without a subpath every URL assertion degenerates: the language-prefix /
# subpath bug this script catches only exists when the site is NOT at the
# domain root. Override with CHECK_BASE_URL for local runs.
CHECK_BASE_URL="${CHECK_BASE_URL:-https://ouatis.com/hugo-theme-sigil/}"

hugo --themesDir ../.. --minify --quiet --baseURL "$CHECK_BASE_URL" \
    || fail "example site build failed (run without --quiet to see the error)"

# llms.txt: machine-readable site index generated for agents
[ -s public/llms.txt ] || fail "llms.txt missing or empty"
grep -q "^# Sigil" public/llms.txt || fail "llms.txt lacks the site title"
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

# no resource path leaks into visible text: a bare {{ .RelPermalink }} in a
# partial prints e.g. katex font paths as body text. Assert none appear.
if grep -qE 'KaTeX_[A-Za-z-]+[.]woff2|/katex/fonts/' public/posts/typography/index.html; then
    fail "katex font paths leaked into visible HTML — a partial is printing .RelPermalink"
fi

# Navigation hrefs must keep the deploy subpath directly after the host and
# the language code directly after the subpath. absLangURL interleaves the
# two: on a non-default language page it emits
# https://host/<lang>/<subpath>/page/ instead of
# https://host/<subpath>/<lang>/page/. Hugo's own canonical link gives the
# correct order for the audited page, so derive the site root from it and
# require every same-host absolute href to start with that root — never
# with a bare language code.
python3 - <<'PY'
import os, re
LANG_CODES = {"en", "zh-cn", "ja"}

def hrefs(page):
    raw = open(os.path.join("public", page), encoding="utf-8").read()
    body = re.sub(r"<script[\s\S]*?</script>", "", raw)
    return re.findall(r'href=["\']?([^"\'\s>]+)', body)

pages = ["index.html", "zh-cn/index.html", "ja/index.html"]
root = None
for page in pages:
    if not os.path.exists(os.path.join("public", page)):
        print(f"check: FAIL — missing page for nav audit: {page}")
        raise SystemExit(1)
    raw = open(os.path.join("public", page), encoding="utf-8").read()
    m = re.search(r'<link rel=canonical href=([^ >]+)', raw)
    if not m:
        print(f"check: FAIL — no canonical on {page}, cannot derive the site root")
        raise SystemExit(1)
    scheme, _, after = m.group(1).partition("://")
    host, _, rest = after.partition("/")
    subpath = "/" + rest.split("/")[0].strip("/")      # hugo-theme-sigil
    root = f"{scheme}://{host}{subpath}/"
    bad = []
    for href in hrefs(page):
        if not href.startswith("http"):
            continue
        h_scheme, _, h_after = href.partition("://")
        if f"{h_scheme}://{h_after.split('/')[0]}" != f"{scheme}://{host}":
            continue                                   # external link, not ours
        tail = h_after[len(host):].lstrip("/")
        first = tail.split("/")[0] if tail else ""
        if first in LANG_CODES:
            # a language code is legal only after the subpath
            if not tail.startswith(subpath.strip("/") + "/"):
                bad.append(href)
        elif not ("/" + tail).startswith(subpath + "/") and "/" + tail != subpath + "/":
            bad.append(href)
    if bad:
        for href in bad[:8]:
            print(f"check: FAIL — nav href breaks the subpath/language order: {page} -> {href}")
        print(f"check: expected every same-host href to start with {root}")
        raise SystemExit(1)
print("check: nav hrefs keep the deploy subpath before any language code")
PY

# Font budget: the demo is multilingual (en/zh/ja), and the corpus SC subset
# is scanned from the whole example site, so a real Plex-rendered CJK demo
# costs more than a single-page measurement suggests. Budget 200KB covers
# the multilingual corpus with headroom. Any referenced CSS or font that is
# missing fails the check — a dangling import (e.g. a wrong relative path)
# must never pass silently.
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
budget = int(os.environ.get("FONT_BUDGET_KB", "200"))
if kb > budget:
    print(f"check: FAIL — fonts {kb}KB > budget {budget}KB")
    raise SystemExit(1)
print(f"check: fonts {kb}KB <= {budget}KB")
PY

echo "check: all green"
