#!/usr/bin/env bash
# One-shot verification for agents and CI: clear caches, build exampleSite
# with --minify, then assert the artifacts that matter. Clean exit = green.
# resources/ goes first: Hugo's processed-image cache does not key on
# images.Text font bytes, so a stale cache produces lying green builds.
set -euo pipefail

# Remember the theme root before cd'ing away: assertions below read theme
# templates, not just the built site.
SG_THEME_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SG_THEME_ROOT/exampleSite"
rm -rf public resources

fail() { echo "check: FAIL — $1" >&2; exit 1; }

# --baseURL mirrors the deployed demo (https://ouatis.com/hugo-theme-sigil/).
# Without a subpath every URL assertion degenerates: the language-prefix /
# subpath bug this script catches only exists when the site is NOT at the
# domain root. Override with CHECK_BASE_URL for local runs.
CHECK_BASE_URL="${CHECK_BASE_URL:-https://ouatis.com/hugo-theme-sigil/}"
export SG_THEME_ROOT

hugo --themesDir ../.. --minify --quiet --baseURL "$CHECK_BASE_URL" \
    || fail "example site build failed (run without --quiet to see the error)"

# llms.txt: machine-readable site index generated for agents
[ -s public/llms.txt ] || fail "llms.txt missing or empty"
# Read the title from the config rather than hardcoding it, so renaming the
# demo site does not require editing this assertion.
SITE_TITLE="$(sed -n 's/^title *= *"\(.*\)"/\1/p' hugo.toml | head -1)"
[ -n "$SITE_TITLE" ] || fail "could not read title from hugo.toml"
grep -q "^# $SITE_TITLE" public/llms.txt \
    || fail "llms.txt lacks the site title (expected '# $SITE_TITLE')"
grep -q "^## All posts" public/llms.txt || fail "llms.txt lacks the posts section"

# feed.json: JSON Feed 1.1 alongside RSS
[ -s public/feed.json ] || fail "feed.json missing"

# OG auto card: generated and referenced on a page without any cover
# (patterns are quote-agnostic — --minify strips attribute quotes)
grep -qE 'og:image[^>]*og/base_hu_' \
    public/posts/what-can-change/index.html \
    || fail "og:image auto card missing on what-can-change"

# door marker: the render hook tags external links only.
# what-can-change carries the quote post and links out to Wikiquote; it is also
# the page that hosts the footnote/margin-note demo.
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

# Menu shape: tools belong after the words, not among them. The search icon is
# lifted out of the menu run and re-emitted last, so a reader scanning the words
# meets About/Archives/Docs/Typography and then one tool. Assert the words, the
# count, the position and that nothing is a dead link — a dropped {{ end }} or a
# pageRef with no translation renders a plausible-looking header and would pass
# every other check in this file.
python3 - <<'PY'
import os, re

# Menu labels are localized, so each language is checked against its own
# wording. What must hold everywhere is the shape: the words in configured
# order, then exactly one tool.
EXPECTED = {
    "index.html":       ["About", "Archives", "Docs", "Typography"],
    "zh-cn/index.html": ["关于", "归档", "排版", "文档"],
    "ja/index.html":    ["About", "アーカイブ", "ドキュメント", "組版"],
}

for page, expected in EXPECTED.items():
    path = os.path.join("public", page)
    if not os.path.exists(path):
        print(f"check: FAIL — missing page for menu audit: {page}")
        raise SystemExit(1)
    raw = open(path, encoding="utf-8").read()
    m = re.search(r"<ul[^>]*\bid=menu[^>]*>([\s\S]*?)</ul>", raw)
    if not m:
        print(f"check: FAIL — no #menu on {page}")
        raise SystemExit(1)
    items = re.findall(r"<li>([\s\S]*?)</li>", m.group(1))
    texts = [re.sub(r"<[^>]+>", "", it).strip() for it in items]
    if texts[:-1] != expected:
        print(f"check: FAIL — menu words out of order: {page} -> {texts}")
        print(f"check: expected {expected} then one tool")
        raise SystemExit(1)
    if len(items) != len(expected) + 1:
        print(f"check: FAIL — menu should hold {len(expected)} words + 1 tool, "
              f"found {len(items)}: {page}")
        raise SystemExit(1)
    if "<svg" not in items[-1]:
        print(f"check: FAIL — the trailing item is not the magnifier: {page}")
        raise SystemExit(1)
    if "accesskey=/" not in items[-1]:
        print(f"check: FAIL — trailing search item lost its Alt+/ shortcut: {page}")
        raise SystemExit(1)
    # A dead menu entry is the quiet failure: the build succeeds, the header
    # still looks right, and only a reader finds it goes nowhere. An empty href
    # is what a pageRef leaves behind when its target has no translation yet.
    for it in items:
        if re.search(r'href=(?:""|\s|>)', it):
            label = re.sub(r"<[^>]+>", "", it).strip()
            print(f"check: FAIL — menu entry has an empty href on {page}: {label!r}")
            print("check: its pageRef has no page in this language — add a "
                  "translated content file, or drop the entry for that language")
            raise SystemExit(1)
print("check: menu keeps four words in order, the search icon last, no dead links")
PY

# The external-link arrow is hand-written SVG in header.html. One dropped
# character there does not fail the build — Hugo still emits HTML and the browser
# paints no glyph — so nothing else here would notice. The demo has no external
# menu entry, so the arrow never reaches the output; assert on the template.
# Resolve the path from this script's own location so the check works whatever
# the caller's directory is.
#
# The arc needs its separators. "a2 2 0 01-2 2" and "a2 2 0 012-2" draw
# different curves; the second is what a careless retyping produces.
python3 - <<'PY'
import os, re

ROOT = os.environ["SG_THEME_ROOT"].rstrip("/")
path = os.path.join(ROOT, "layouts", "partials", "header.html")
if not os.path.exists(path):
    print(f"check: FAIL — cannot find header.html at {path}")
    raise SystemExit(1)
raw = open(path, encoding="utf-8").read()

ARC = "M18 13v6a2 2 0 01-2 2H5"
if ARC not in raw:
    print("check: FAIL — external-link arrow path is not the expected drawing")
    print(f"check: expected the arc to start with {ARC!r}")
    raise SystemExit(1)
# The whole path as it stands:
#   M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6
# The trailing arc is at risk because "a2 2 0 01-2-2" and "a2 2 0 012-2" differ
# by a single character, and only one of them draws the box the author meant.
RISK = "V8a2 2 0 012-2h6"
if RISK not in raw:
    print(f"check: FAIL — the arrow's closing arc is malformed in header.html")
    print(f"check: expected to find {RISK!r}")
    raise SystemExit(1)
print("check: external-link arrow path is intact")
PY

# Font budget: measure what ONE language's page actually loads, and hold the
# budget to the worst language. The demo is multilingual (en/zh/ja); the SC
# and JP corpus subsets are scanned from their own language's pages, so a
# Chinese reader pays Latin+SC and never touches JP, a Japanese reader pays
# Latin+JP. Summing every subset across all languages (the old behaviour)
# reported a union nobody downloads. Any referenced CSS or font that is
# missing fails the check — a dangling import must never pass silently.
command -v python3 >/dev/null 2>&1 || fail "python3 not found — required for font checks"
python3 - <<'PY'
import html, os, re

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
        fam = re.search(r'font-family:\s*["\']?([^"\';]+)', block)
        wt = re.search(r'font-weight:\s*([^;}]+)', block)
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
        family = fam.group(1).strip() if fam else ""
        weight = wt.group(1).strip() if wt else ""
        faces.append((family, weight, ranges, fpath))
load("public/fonts/ibm-plex/result.css")
if missing:
    print(f"check: FAIL — referenced CSS not found: {missing}")
    raise SystemExit(1)
for family, weight, ranges, fpath in faces:
    if not os.path.exists(fpath):
        print(f"check: FAIL — referenced font not found: {fpath}")
        raise SystemExit(1)

def page_cost(page, stack, weights):
    raw = open(f"public/{page}", encoding="utf-8").read()
    text = html.unescape(re.sub(r"<script[\s\S]*?</script>|<style[\s\S]*?</style>", "", raw))
    cps = {ord(c) for c in text if not c.isspace()} | {0x2234}
    # For each (glyph, weight) pair the browser walks the family stack in
    # order and downloads the first @font-face whose family AND weight match
    # and whose unicode-range covers the glyph. Weight matters: a glyph set
    # in both 400 and 700 pulls both files, and stopping at the first family
    # (ignoring weight) undercounts by missing the bold face.
    needed = set()
    for c in cps:
        for w in weights:
            for fam in stack:
                for ffam, fw, franges, fpath in faces:
                    if ffam != fam or fw != w:
                        continue
                    if not franges or any(a <= c <= b for a, b in franges):
                        needed.add(fpath)
                        break
                else:
                    continue
                break
    total = sum(os.path.getsize(fp) for fp in needed)
    return total // 1024

# Mirror sigil.css stacks in stack order (first-match wins):
#   html:lang(zh) -> SC before Latin; html:lang(ja) -> JP before Latin;
#   default (en) -> SC, then JP, then Latin. A glyph both SC and JP cover
#   resolves to the earlier family. Weights present on the page are summed:
# a glyph used in body (400) and bold (700) downloads both faces.
STACKS = {
    "en":     ["IBM Plex Sans SC", "IBM Plex Sans JP", "IBM Plex Sans"],
    "zh-cn":  ["IBM Plex Sans SC", "IBM Plex Sans"],
    "ja":     ["IBM Plex Sans JP", "IBM Plex Sans"],
}
WEIGHTS = ["400", "600", "700"]
pages = {"en": "posts/typography/index.html",
         "zh-cn": "zh-cn/posts/typography/index.html",
         "ja": "ja/posts/typography/index.html"}
costs = {}
for lang, page in pages.items():
    if not os.path.exists(os.path.join("public", page)):
        print(f"check: FAIL — missing page for font budget: {page}")
        raise SystemExit(1)
    costs[lang] = page_cost(page, STACKS[lang], WEIGHTS)
worst = max(costs.values())
detail = " ".join(f"{lang}={kb}KB" for lang, kb in costs.items())

# Budget for the theme's bundled typography fonts ONLY. It gates the theme's own
# asset growth — a CJK corpus that keeps widening, an added weight, a new
# charset, a CSS error that double-downloads. It deliberately EXCLUDES
# optional third-party libraries such as KaTeX: those load only when a page
# opts in (math: true), come from a fixed vendor, and are not the theme's
# typography. Mixing them in would let a feature switch trip a "font" check
# and hide which of the two actually grew.
#
# Note the corpus is scanned SITE-WIDE, so any page that adds CJK content
# (a new About, a new essay) grows the SC/JP face for every language at
# once — the English page loads SC too. The budget must sit above the
# current worst with room for normal content growth, not flush against it.
budget = int(os.environ.get("FONT_BUDGET_KB", "280"))
if worst > budget:
    print(f"check: FAIL — bundled fonts worst={worst}KB > budget {budget}KB ({detail})")
    raise SystemExit(1)
print(f"check: bundled fonts worst={worst}KB <= {budget}KB ({detail})")

# Informational only (no threshold): the math pages additionally load KaTeX
# fonts, which are opt-in and vendor-fixed. How much depends on which glyphs
# the rendered formulas use (KaTeX subsets by unicode-range, like the theme
# fonts), so it is reported as a pointer rather than a static number — a
# false-precise total here would mislead. Measured ~46KB on the demo's
# typography page via a real browser.
print("check: math pages additionally load KaTeX fonts (opt-in, excluded from budget)")
PY

echo "check: all green"
