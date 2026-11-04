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

# Python: assertions below parse build output with the stdlib (XML, JSON,
# HTML). Resolve it once, and actually RUN each candidate — `command -v
# python3` is not a working-interpreter test on Windows, where python3 is
# often the Store stub that exits 49 for every call. See scripts/lib-python.sh.
# shellcheck source=scripts/lib-python.sh
. "$SG_THEME_ROOT/scripts/lib-python.sh"
sg_resolve_python || fail "no working python3 — set SG_PYTHON to a real interpreter"
export SG_PY
# Assertion messages below contain non-ASCII (em dashes, CJK menu words). Python
# defaults stdout to the console codepage (cp936 on Chinese Windows), which turns
# those into U+FFFD; force UTF-8 so a failing assertion is readable everywhere.
export PYTHONIOENCODING=utf-8

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

# llms-full.txt: the whole corpus in one file. The template shipped long before
# the demo enabled the output, so this file could be advertised in the README
# while never being generated. Assert the file, the per-post sections, and the
# link that llms.txt is supposed to grow once the format is on.
[ -s public/llms-full.txt ] || fail "llms-full.txt missing or empty — is LLMSFULL in [outputs] home?"
grep -q "^# $SITE_TITLE" public/llms-full.txt \
    || fail "llms-full.txt lacks the site title (expected '# $SITE_TITLE')"
# Every post title listed in llms.txt must have a section of its own in the
# full text; that is the difference between the two files and the reason both
# exist. Titles are URL-decoded list links, so compare on the decoded text.
"$SG_PY" - <<'PY'
import io, re, sys

def fail(why):
    print(f"check: FAIL — {why}", file=sys.stderr)
    sys.exit(1)

index = io.open("public/llms.txt", encoding="utf-8").read()
if "llms-full.txt" not in index:
    fail("llms.txt does not advertise llms-full.txt")
full = io.open("public/llms-full.txt", encoding="utf-8").read()
# Only the '## All posts' section indexes the posts that llms-full expands; the
# '## Pages' links above it (About, Archives, ...) have no per-page section.
section = index.split("## All posts", 1)
if len(section) != 2:
    fail("llms.txt has no '## All posts' section")
titles = [m.group(1).strip() for m in re.finditer(r"^\s*-\s*\[(.+?)\]\(", section[1], re.M)]
if not titles:
    fail("llms.txt lists no posts — the llms-full section check would pass vacuously")
# Match a whole heading line: a substring test would accept a renamed heading
# such as '## Typography (renamed)' as still present.
missing = [t for t in titles if not re.search(rf"^## {re.escape(t)}[ \t]*$", full, re.M)]
if missing:
    fail(f"llms-full.txt lacks a section for {len(missing)} post(s), first: {missing[0]!r}")
size = len(full.encode("utf-8"))
if size <= len(index.encode("utf-8")):
    fail("llms-full.txt is not larger than llms.txt — the full text was not written")
# plainify strips tags but leaves entities behind; the body must be prose an agent
# can read, not `&#34;` and `&rsquo;` sitting between sentences.
entities = re.findall(r"&(?:[a-zA-Z][a-zA-Z0-9]*|#\d+|#[xX][0-9a-fA-F]+);", full)
if entities:
    fail(f"llms-full.txt carries {len(entities)} HTML entit(ies), first: {entities[0]!r}"
         " — pipe the body through htmlUnescape")
print(f"check: llms-full — {len(titles)} post sections in {size} bytes, no HTML entities")
PY

# No debug logging may reach the browser console. fastsearch.js used to dump the
# whole XHR body on a failed index fetch: that leaks server output to anyone with
# devtools open and is invisible in a browser smoke test (console.log is not an
# error). Scan the built bundles — concat + minify can only copy what the themes
# sources already contained, and the build output is what actually ships.
"$SG_PY" - <<'PY'
import glob, io, sys

def fail(why):
    print(f"check: FAIL — {why}", file=sys.stderr)
    sys.exit(1)

bundles = sorted(glob.glob("public/assets/js/*.js"))
if not bundles:
    fail("no built JavaScript under public/assets/js — the console.log check would pass vacuously")
for path in bundles:
    text = io.open(path, encoding="utf-8", errors="replace").read()
    if "console.log" in text:
        fail(f"console.log left in shipped JavaScript: {path}")
print(f"check: assets — {len(bundles)} built bundle(s) carry no console.log")
PY

# Search index. Nothing else in this script touches index.json, so the index
# Fuse reads could go empty, malformed or entity-riddled with every other
# assertion still green — and the search page renders results from JS, so the
# static build looks fine. `.Plain` strips tags but leaves entities behind
# (&rsquo;, &#34;, &lt;); indexed verbatim, "theme&rsquo;s" never matches a
# query for "theme's". Only `content` is asserted: `summary` is HTML by
# contract, where entities are correct.
"$SG_PY" - <<'PY'
import glob, json, os, re, sys
from urllib.parse import urlsplit

ENTITY = re.compile(r"&(?:[a-zA-Z][a-zA-Z0-9]*|#\d+|#[xX][0-9a-fA-F]+);")
FIELDS = ("title", "content", "permalink", "summary", "date", "category",
          "readingtime")


def fail(why):
    print(f"check: FAIL — {why}", file=sys.stderr)
    sys.exit(1)


with open("public/index.html", encoding="utf-8") as handle:
    home = handle.read()
canon = re.search(r'<link rel=canonical href=["\']?(https?://[^"\' >]+)', home)
if not canon:
    fail("public/index.html has no canonical link — cannot derive the site root")
root = canon.group(1)
origin = "{0.scheme}://{0.netloc}{1}".format(urlsplit(root), os.path.dirname(urlsplit(root).path).rstrip("/") + "/")

indexes = sorted(glob.glob("public/**/index.json", recursive=True))
if not indexes:
    fail("no index.json found under public/ — the search index is not being built")
for required in ("public/index.json", "public/zh-cn/index.json",
                 "public/ja/index.json"):
    if required.replace("/", os.sep) not in [p.replace("/", os.sep) for p in indexes]:
        fail(f"{required} is missing — that language has no searchable index")

entries = 0
for path in indexes:
    try:
        data = json.load(open(path, encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"{path} is not valid JSON: {exc}")
    if not isinstance(data, list):
        fail(f"{path} is not a JSON array")
    if not data:
        fail(f"{path} is empty — search would return nothing")
    seen = set()
    for rank, entry in enumerate(data):
        if not isinstance(entry, dict):
            fail(f"{path} entry #{rank} is not an object")
        missing = [k for k in FIELDS if k not in entry]
        if missing:
            fail(f"{path} entry #{rank} is missing {', '.join(missing)}")
        if not (entry.get("title") or "").strip():
            fail(f"{path} entry #{rank} has an empty title")
        link = entry.get("permalink") or ""
        if not link.startswith(origin):
            fail(f"{path} entry #{rank} permalink is not absolute under "
                 f"{origin}: {link!r}")
        if link in seen:
            fail(f"{path} lists {link} twice — duplicate search hit")
        seen.add(link)
        found = ENTITY.findall(entry.get("content") or "")
        if found:
            fail(f"{path} entry #{rank} ({entry.get('title')!r}) keeps HTML "
                 f"entities in content: {', '.join(sorted(set(found)))} — "
                 "pipe .Plain through htmlUnescape in index.json")
        entries += 1
print(f"check: search index — {entries} entries across {len(indexes)} index.json "
      f"files, no HTML entities in content")
PY

# feed.json: JSON Feed 1.1 alongside RSS
[ -s public/feed.json ] || fail "feed.json missing"

# Feed contracts. Feeds are read by machines: a malformed date or a missing
# required element breaks subscribers and aggregators while looking fine in a
# browser. Assert on values decoded by a real XML/JSON parser, never on raw
# bytes — Hugo escapes "+" in RSS dates as &#43; before --minify and leaves
# it bare after, so a regex over the raw file would depend on the bsd* flags.
"$SG_PY" - <<'PY'
import glob, json, sys
import xml.etree.ElementTree as ET
from datetime import datetime

RFC822 = "%a, %d %b %Y %H:%M:%S %z"

def fail(why):
    print(f"check: FAIL — {why}", file=sys.stderr)
    sys.exit(1)

def parse_rfc822(value):
    try:
        datetime.strptime(value, RFC822)
    except ValueError:
        return False
    return True

def parse_rfc3339(value):
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        datetime.fromisoformat(text)
    except ValueError:
        return False
    return True

feeds = sorted(glob.glob("public/**/index.xml", recursive=True))
if not feeds:
    fail("no RSS feed found under public/")

items = 0
for path in feeds:
    try:
        channel = ET.parse(path).getroot().find("channel")
    except ET.ParseError as exc:
        fail(f"RSS is not well-formed XML: {path} ({exc})")
    if channel is None:
        fail(f"RSS has no <channel>: {path}")
    # lastBuildDate is only emitted when the feed has items (template guard).
    build = channel.find("lastBuildDate")
    if build is not None and not parse_rfc822((build.text or "").strip()):
        fail(f"lastBuildDate is not RFC 822: {path} -> {build.text!r}")
    for tag in ("title", "link", "description"):
        if channel.find(tag) is None:
            fail(f"RSS channel lacks <{tag}>: {path}")
    self_link = channel.find("{http://www.w3.org/2005/Atom}link")
    if self_link is None or self_link.get("rel") != "self":
        fail(f"RSS channel lacks <atom:link rel=self>: {path}")
    for item in channel.findall("item"):
        items += 1
        for tag in ("title", "link", "guid"):
            element = item.find(tag)
            if element is None or not (element.text or "").strip():
                fail(f"RSS item lacks <{tag}>: {path}")
        if item.find("description") is None:
            fail(f"RSS item lacks <description>: {path}")
        pub = item.find("pubDate")
        if pub is None or not parse_rfc822((pub.text or "").strip()):
            fail(f"item pubDate is not RFC 822: {path} -> {None if pub is None else pub.text!r}")

# JSON Feed 1.1: top-level required keys and the per-item fields a reader
# dereferences (id/url/content + RFC 3339 dates when present).
with open("public/feed.json", encoding="utf-8") as handle:
    feed = json.load(handle)
if feed.get("version") != "https://jsonfeed.org/version/1.1":
    fail(f"feed.json is not JSON Feed 1.1: version={feed.get('version')!r}")
for key in ("title", "home_page_url", "feed_url", "language"):
    if not str(feed.get(key) or "").strip():
        fail(f"feed.json lacks top-level '{key}'")
entries = feed.get("items")
if not isinstance(entries, list) or not entries:
    fail("feed.json has no items")
seen = set()
for index, entry in enumerate(entries):
    for key in ("id", "url", "title"):
        if not str(entry.get(key) or "").strip():
            fail(f"feed.json item #{index} lacks '{key}'")
    if entry["id"] in seen:
        fail(f"feed.json item id is not unique: {entry['id']!r}")
    seen.add(entry["id"])
    if not (str(entry.get("content_html") or "").strip() or str(entry.get("content_text") or "").strip()):
        fail(f"feed.json item #{index} has neither content_html nor content_text")
    for key in ("date_published", "date_modified"):
        value = entry.get(key)
        if value is not None and not parse_rfc3339(str(value)):
            fail(f"feed.json item #{index} {key} is not RFC 3339: {value!r}")

print(f"check: feeds — {len(feeds)} RSS ({items} items) and JSON Feed 1.1: dates and required elements")
PY

# Full-text RSS overlay: theme.toml advertises full-text RSS and docs/api.md
# documents ShowFullTextinRSS, but the demo never enables it, so no other check
# ever builds the branch that emits <content:encoded>. That branch was broken:
# home.rss.xml declared only xmlns:atom while emitting a content:-prefixed
# element, and one undeclared prefix makes EVERY feed on the site unparseable
# ("unbound prefix") the moment the flag is on. The feeding of the gate and the
# namespace are the same contract — turn the gate on in a throwaway config,
# rebuild, and parse what comes out.
cp hugo.toml hugo.fulltext-check.toml
"$SG_PY" - <<'PY'
s = open("hugo.fulltext-check.toml", encoding="utf-8").read()
assert "[params]" in s, "demo config lost its [params] table"
open("hugo.fulltext-check.toml", "w", encoding="utf-8", newline="").write(
    s.replace("[params]", "[params]\nShowFullTextinRSS = true", 1))
PY
hugo --themesDir ../.. --minify --quiet --baseURL "$CHECK_BASE_URL" \
    --config hugo.fulltext-check.toml --destination public-fulltext-check \
    || { rm -rf public-fulltext-check hugo.fulltext-check.toml; fail "overlay build failed (ShowFullTextinRSS = true)"; }
if ! SG_FULLTEXT_DIR=public-fulltext-check "$SG_PY" - <<'PY'
import glob, os, sys
import xml.etree.ElementTree as ET

FULLTEXT = "{http://purl.org/rss/1.0/modules/content/}encoded"


def fail(why):
    print(f"check: FAIL — {why}", file=sys.stderr)
    sys.exit(1)


root = os.environ.get("SG_FULLTEXT_DIR", "public-fulltext-check")
feeds = sorted(glob.glob(os.path.join(root, "**", "index.xml"), recursive=True))
if not feeds:
    fail(f"no feeds under {root}/ — the overlay build produced nothing")

items = 0
encoded_items = 0
widest = 0.0
for path in feeds:
    try:
        tree = ET.parse(path)
    except ET.ParseError as exc:
        # The unbound-prefix regression lands here: one missing xmlns turns
        # every feed on the site into an unreadable document.
        fail(f"{path} does not parse as XML: {exc}")
    for index, item in enumerate(tree.getroot().iter("item")):
        items += 1
        summary = (item.findtext("description") or "").strip()
        encoded = item.find(FULLTEXT)
        if not summary:
            # Taxonomy term feeds list pages that have no body at all; the
            # template gates on .Content, so an absent element is correct here.
            continue
        if encoded is None:
            fail(f"{path} item #{index} has a summary but no content:encoded — "
                 "the ShowFullTextinRSS gate stopped emitting the body")
        body = (encoded.text or "").strip()
        if not body:
            fail(f"{path} item #{index} has an empty content:encoded")
        encoded_items += 1
        widest = max(widest, len(body) / len(summary))
if not items:
    fail("the overlay feeds carry no items — nothing was exercised")
if not encoded_items:
    fail("no item carried content:encoded — the overlay never exercised the gate")
if widest < 2:
    fail(f"the widest item body is only {widest:.1f}x its summary — "
         "content:encoded is not carrying the full text")
print(f"check: full-text RSS — {len(feeds)} feeds parse with ShowFullTextinRSS on; "
      f"{encoded_items}/{items} items carry content:encoded (widest {widest:.1f}x its summary)")
PY
then
    rm -rf public-fulltext-check hugo.fulltext-check.toml
    fail "full-text RSS contract violated"
fi
rm -rf public-fulltext-check hugo.fulltext-check.toml

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

# Machine-readable metadata and link semantics. Both fail silently: a JSON-LD
# block that stops parsing kills rich results, and a target=_blank without
# rel=noopener leaves the opener reachable. Parse the HTML for real — --minify
# strips attribute quotes and rewrites the doctype, so byte patterns are a
# trap. The sg-ext contract is scoped to .post-content: partials render
# static external links (footer, social) that deliberately have no door
# marker, so a global "every external link is tagged" rule would be wrong.
"$SG_PY" - <<'PY'
import glob, json, os, re, sys
from html.parser import HTMLParser
from urllib.parse import urlsplit

def fail(why):
    print(f"check: FAIL — {why}", file=sys.stderr)
    sys.exit(1)


class Audit(HTMLParser):
    """Collect <script type=application/ld+json> bodies and <a> attributes,
    tracking whether each anchor sits inside div.post-content."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ldjson = []
        self._id = ""
        self.anchors = []
        self._body = None
        self._post = 0
        self._divs = []

    def handle_starttag(self, tag, attrs):
        attr = dict(attrs)
        if tag == "script" and (attr.get("type") or "").lower() == "application/ld+json":
            self._body = []
            self._id = attr.get("id") or ""
        elif tag == "a":
            self.anchors.append((attr, self._post > 0))
        if tag == "div":
            inside = "post-content" in (attr.get("class") or "").split()
            self._divs.append(inside)
            self._post += 1 if inside else 0

    def handle_endtag(self, tag):
        if tag == "script" and self._body is not None:
            self.ldjson.append((self._id, "".join(self._body)))
            self._body = None
        elif tag == "div" and self._divs:
            if self._divs.pop():
                self._post -= 1

    def handle_data(self, data):
        if self._body is not None:
            self._body.append(data)


def read_page(path):
    with open(path, encoding="utf-8") as handle:
        audit = Audit()
        audit.feed(handle.read())
        audit.close()
    return audit


pages = {}
for path in glob.glob("public/**/*.html", recursive=True):
    pages[os.path.relpath(path, "public").replace("\\", "/")] = read_page(path)
if not pages:
    fail("no HTML found under public/")

# --- JSON-LD: every block must be parseable JSON with a schema.org @type.
blocks = 0
for path, page in sorted(pages.items()):
    for block_id, body in page.ldjson:
        blocks += 1
        if not block_id:
            fail(f"JSON-LD block has no id attribute: {path}")
        try:
            data = json.loads(body)
        except json.JSONDecodeError as exc:
            fail(f"JSON-LD does not parse: {path} ({exc.msg} at char {exc.pos})")
        if not isinstance(data, dict):
            fail(f"JSON-LD is not a JSON object: {path}")
        if "schema.org" not in str(data.get("@context", "")):
            fail(f"JSON-LD @context is not schema.org: {path} -> {data.get('@context')!r}")
        if not str(data.get("@type") or "").strip():
            fail(f"JSON-LD has no @type: {path}")

# Shape per page kind: the homepage carries exactly one Organization; every
# post carries BreadcrumbList + BlogPosting with the fields a rich result
# reads. author/image are omitted when the site configures none — absence is
# allowed, malformed presence is not.
homes = {"index.html", "zh-cn/index.html", "ja/index.html"}
for path in sorted(homes):
    if path not in pages:
        fail(f"missing homepage for the JSON-LD shape check: {path}")
    if len(pages[path].ldjson) != 1:
        fail(f"{path}: expected exactly 1 JSON-LD block, found {len(pages[path].ldjson)}")
    block_id, body = pages[path].ldjson[0]
    if block_id != "ld-org":
        fail(f"{path}: homepage JSON-LD id is {block_id!r}, expected 'ld-org'")
    if json.loads(body).get("@type") != "Organization":
        fail(f"{path}: homepage JSON-LD is not an Organization")

posts = sorted(p for p in pages
               if re.fullmatch(r"(?:[a-z-]+/)?posts/[^/]+/index[.]html", p))
if not posts:
    fail("no post pages found — JSON-LD shape check would pass vacuously")
for path in posts:
    ids = sorted(block_id for block_id, _ in pages[path].ldjson)
    if ids != ["ld-breadcrumb", "ld-post"]:
        fail(f"{path}: expected JSON-LD ids ['ld-breadcrumb', 'ld-post'], found {ids}")
    parsed = [json.loads(body) for _, body in pages[path].ldjson]
    types = sorted(d.get("@type") for d in parsed)
    if types != ["BlogPosting", "BreadcrumbList"]:
        fail(f"{path}: expected BreadcrumbList + BlogPosting JSON-LD, found {types}")
    post = next(d for d in parsed if d.get("@type") == "BlogPosting")
    for field in ("headline", "datePublished", "dateModified", "mainEntityOfPage"):
        if not str(post.get(field) or "").strip():
            fail(f"{path}: BlogPosting lacks '{field}'")
    # schema.org types wordCount as Integer; a quoted count is a string and
    # Google's validator reports it as a type mismatch.
    if not isinstance(post.get("wordCount"), int):
        fail(f"{path}: BlogPosting wordCount is {type(post.get('wordCount')).__name__}, expected int")

# --- link semantics: safety attributes and the door-marker contract.
site_host = ""
with open("public/index.html", encoding="utf-8") as handle:
    canonical = re.search("<link rel=canonical href=[\"']?([^\"' >]+)", handle.read())
if canonical:
    site_host = (urlsplit(canonical.group(1)).hostname or "").lower()
if not site_host:
    fail("cannot derive the site host from the homepage canonical link")

blank = 0
door = 0
for path, page in sorted(pages.items()):
    for attr, in_post in page.anchors:
        href = (attr.get("href") or "").strip()
        if (attr.get("target") or "") == "_blank":
            blank += 1
            tokens = set((attr.get("rel") or "").lower().split())
            if not {"noopener", "noreferrer"} <= tokens:
                fail(f"target=_blank without rel=noopener noreferrer: {path} -> {href}")
        if not in_post or not href.startswith(("http://", "https://")):
            continue
        host = (urlsplit(href).hostname or "").lower()
        external = site_host and host.replace("www.", "") != site_host.replace("www.", "")
        tagged = "sg-ext" in (attr.get("class") or "").split()
        if external and not tagged:
            fail(f"external link in post content lacks sg-ext: {path} -> {href}")
        if not external and tagged:
            fail(f"internal link in post content is tagged sg-ext: {path} -> {href}")
        door += 1 if tagged else 0

if blank == 0:
    fail("no target=_blank links found — the rel contract would pass vacuously")
print(f"check: metadata — {blocks} identified JSON-LD blocks parse; "
      f"{blank} target=_blank links carry rel; {door} post-content external links carry sg-ext")
PY

# opt-in isolation: typography opts into math/mermaid/lightbox,
# pages that don't ask for them must load none of them
for what in katex glightbox mermaid pele; do
    grep -q "$what" public/posts/typography/index.html \
        || fail "typography page missing $what"
    if grep -q "$what" public/posts/what-can-change/index.html; then
        fail "what-can-change leaks $what — opt-in isolation broken"
    fi
done

# Self-hosted assets only: the diagram engine used to come from a pinned CDN and
# now ships vendored, so a built page pulling a script from jsdelivr is a
# regression back to a third-party runtime request.
if grep -rqs 'cdn.jsdelivr.net' public/; then
    fail "a built page loads from cdn.jsdelivr.net — vendor the asset instead"
fi

# no resource path leaks into visible text: a bare {{ .RelPermalink }} in a
# partial prints e.g. katex font paths as body text. Assert none appear.
if grep -qE 'KaTeX_[A-Za-z-]+[.]woff2|/katex/fonts/' public/posts/typography/index.html; then
    fail "katex font paths leaked into visible HTML — a partial is printing .RelPermalink"
fi

# comments gate closed by default: the demo configures no comment system, so
# no page may load giscus — the overlay build below proves the open direction.
if grep -q 'giscus.app' public/posts/typography/index.html; then
    fail "giscus loaded without configuration — the comments gate must be closed by default"
fi

# Navigation hrefs must keep the deploy subpath directly after the host and
# the language code directly after the subpath. absLangURL interleaves the
# two: on a non-default language page it emits
# https://host/<lang>/<subpath>/page/ instead of
# https://host/<subpath>/<lang>/page/. Hugo's own canonical link gives the
# correct order for the audited page, so derive the site root from it and
# require every same-host absolute href to start with that root — never
# with a bare language code.
"$SG_PY" - <<'PY'
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
"$SG_PY" - <<'PY'
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
"$SG_PY" - <<'PY'
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

# RTL + opt-in overlay: the 47 i18n files include four right-to-left languages
# (ar/ckb/fa/he) — baseof emits dir from .Language.Direction, so a language
# declaring direction = "rtl" must build and carry dir=rtl on <html>. The same
# overlay turns the comments gate ON with a fake giscus block, proving the
# gate opens only under configuration. Both exist only for this check; the
# fa language is configured with no content, which is exactly the state a
# fresh RTL site starts in.
cp hugo.toml hugo.rtl-check.toml
# `comments = true` must land inside the EXISTING [params] table — a second
# [params] header is invalid TOML, and a bare dotted key appended after the
# [languages.fa] table would silently become languages.fa.params.comments.
"$SG_PY" - <<'PY'
s = open("hugo.rtl-check.toml", encoding="utf-8").read()
assert "[params]" in s, "demo config lost its [params] table"
open("hugo.rtl-check.toml", "w", encoding="utf-8").write(
    s.replace("[params]", "[params]\ncomments = true", 1))
PY
cat >> hugo.rtl-check.toml <<'EOF'

[languages.fa]
label = "فارسی"
direction = "rtl"
weight = 40

[params.giscus]
repo = "ouatis/sigil-demo"
repoId = "R_demo"
category = "Announcements"
categoryId = "DIC_demo"
EOF
hugo --themesDir ../.. --minify --quiet --baseURL "$CHECK_BASE_URL" \
    --config hugo.rtl-check.toml --destination public-rtl-check \
    || { rm -rf public-rtl-check hugo.rtl-check.toml; fail "overlay build failed (fa language + giscus)"; }
grep -qE '<html[^>]*dir=rtl' public-rtl-check/fa/index.html \
    || { rm -rf public-rtl-check hugo.rtl-check.toml; fail "fa language built without dir=rtl on <html>"; }
grep -q 'giscus.app/client.js' public-rtl-check/posts/typography/index.html \
    || { rm -rf public-rtl-check hugo.rtl-check.toml; fail "giscus script missing with [params.giscus] + comments configured"; }
grep -qE 'data-repo="?ouatis/sigil-demo' public-rtl-check/posts/typography/index.html \
    || { rm -rf public-rtl-check hugo.rtl-check.toml; fail "giscus data-repo did not come through the config"; }
rm -rf public-rtl-check hugo.rtl-check.toml
echo "check: overlay builds — fa carries dir=rtl, giscus renders only when configured"

# Font budget: measure what ONE language's page actually loads, and hold the
# budget to the worst language. The demo is multilingual (en/zh/ja); the SC
# and JP corpus subsets are scanned from their own language's pages, so a
# Chinese reader pays Latin+SC and never touches JP, a Japanese reader pays
# Latin+JP. Summing every subset across all languages (the old behaviour)
# reported a union nobody downloads. Any referenced CSS or font that is
# missing fails the check — a dangling import must never pass silently.
"$SG_PY" - <<'PY'
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
#
# 2026-11-01: the 280 default had drifted to 278 — 2KB of headroom — and a
# trilingual About section (~100 CJK characters) cost 6KB, so a content-only
# change failed the demo deploy. Raised to 320: still a real gate (a stray
# weight or a duplicated charset jumps far more than 40KB), but wide enough
# that writing pages does not trip it.
budget = int(os.environ.get("FONT_BUDGET_KB", "320"))
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

# WCAG 对比度审计:调色盘契约的一部分。node 或 bun 皆可,不许静默跳过。
if command -v node >/dev/null 2>&1; then
    node "$SG_THEME_ROOT/scripts/audit-contrast.mjs"
elif command -v bun >/dev/null 2>&1; then
    bun "$SG_THEME_ROOT/scripts/audit-contrast.mjs"
else
    fail "contrast audit needs node or bun on PATH"
fi

echo "check: all green"
