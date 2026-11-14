#!/usr/bin/env python3
"""Link integrity for the built site: internal links, fragments, ids, assets.

Checks, per built HTML page (stdlib only — html.parser, not byte regexes,
because --minify strips attribute quotes and byte patterns lie):
  * every <a> that stays on this site resolves to a built page or asset,
  * every fragment (#target) resolves to an existing id on its target page,
  * every id is unique within its page,
  * every local <img>/<script>/<link>/<use> target exists as a file.

Out of scope: other hosts, mailto/tel/data/javascript targets, and — on a
subpath deployment — same-host URLs that leave the deploy subpath (the demo
links to the author's site at the domain root; that is the one documented
exit). A SITE-ABSOLUTE href ("/posts/…") that skips the subpath is however a
failure: it is exactly how content links break a subpath deployment while
every nav audit still looks green.

Usage: python3 scripts/check-links.py [public-dir]   (default: ./public)
Expects the cwd (or the given dir) to be a built Hugo site.
"""
import glob
import os
import re
import sys
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote


def fail(why):
    print(f"check: FAIL — {why}", file=sys.stderr)
    sys.exit(1)


PUBLIC = sys.argv[1] if len(sys.argv) > 1 else "public"
if not os.path.isdir(PUBLIC):
    fail(f"build dir not found: {PUBLIC}/ — run a build first")

ASSET_TAGS = {"img", "script", "link", "use"}


class Page(HTMLParser):
    """Collect ids (for fragment + uniqueness checks) and every URL-carrying
    attribute this checker must verify."""

    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.urls = []          # (tag, raw url)
        self.dups = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        ident = a.get("id")
        if ident:
            if ident in self.ids:
                self.dups.append(ident)
            self.ids.add(ident)
        if tag == "a" and a.get("name"):
            self.ids.add(a["name"])  # legacy named anchor
        url = None
        if tag == "a":
            url = a.get("href")
        elif tag in ("img", "script"):
            url = a.get("src")
        elif tag == "link":
            url = a.get("href")
        elif tag == "use":
            url = a.get("href") or a.get("xlink:href")
        if url:
            self.urls.append((tag, url.strip()))


pages = {}
for path in sorted(glob.glob(os.path.join(PUBLIC, "**", "*.html"), recursive=True)):
    rel = os.path.relpath(path, PUBLIC).replace(os.sep, "/")
    with open(path, encoding="utf-8") as handle:
        page = Page()
        page.feed(handle.read())
        page.close()
    pages[rel] = page
if not pages:
    fail(f"no HTML found under {PUBLIC}/")

for rel, page in sorted(pages.items()):
    if page.dups:
        uniq = sorted(set(page.dups))
        fail(f"{rel}: duplicate id(s) {', '.join(repr(d) for d in uniq[:4])}"
             f"{' …' if len(uniq) > 4 else ''}")

# Site root from the homepage canonical link (same derivation every other
# check here uses): scheme://host/<subpath>/  — subpath may be "/".
with open(os.path.join(PUBLIC, "index.html"), encoding="utf-8") as handle:
    canon = re.search(r'<link[^>]*rel=["\']?canonical["\']?[^>]*>', handle.read())
if canon:
    href = re.search(r'href=["\']?([^"\' >]+)', canon.group(0))
else:
    href = None
if not href:
    fail("index.html has no canonical link — cannot derive the site root")
split = urlsplit(href.group(1))
host = (split.hostname or "").lower()
subpath = split.path.rstrip("/")
root = f"{split.scheme}://{split.netloc}{subpath}/"

if not host:
    fail("canonical link has no host")


def fs_candidates(path):
    """URL path -> filesystem candidates under PUBLIC (pretty URLs first)."""
    path = unquote(path.split("?", 1)[0])
    if not path or path.endswith("/"):
        return [path + "index.html"]
    return [path, path + "/index.html", path + ".html"]


def resolve_file(path):
    for cand in fs_candidates(path):
        p = os.path.join(PUBLIC, *cand.split("/"))
        if os.path.isfile(p):
            return p
    return None


def page_key(path):
    """URL path -> relpath of the built page holding it, or None."""
    for cand in fs_candidates(path):
        rel = "/".join(cand.split("/"))
        if rel in pages:
            return rel
    return None


def page_dir(rel):
    return os.path.dirname(rel)


checked_links = 0
checked_fragments = 0
checked_assets = 0
broken = []

for rel, page in sorted(pages.items()):
    for tag, url in page.urls:
        if url.startswith(("mailto:", "tel:", "javascript:", "data:")):
            continue
        if url.startswith("#"):
            target = url[1:]
            if not target or target not in page.ids:
                broken.append(f"{rel} -> {url} (no id {target!r} on this page)")
            else:
                checked_fragments += 1
            continue
        split = urlsplit(url)
        scheme = split.scheme.lower()
        path = unquote(split.path)

        if scheme in ("http", "https"):
            hostname = (split.hostname or "").lower()
            if hostname.replace("www.", "") != host.replace("www.", ""):
                continue                       # other site, out of scope
            if not path.startswith(subpath + "/") and path != subpath:
                # same host but outside the deploy subpath: the documented
                # exit to the author's site. Nothing to resolve here.
                continue
            url_path = path[len(subpath):] or "/"
        elif scheme == "":
            if path.startswith("/"):           # site-absolute
                if subpath != "" and not path.startswith(subpath + "/") and path != subpath:
                    broken.append(f"{rel} -> {url} (site-absolute href skips the "
                                  f"deploy subpath {subpath}/)")
                    continue
                url_path = path[len(subpath):] or "/"
            else:                              # relative to this page's dir
                base = page_dir(rel)
                joined = os.path.normpath(os.path.join(base, path)).replace(os.sep, "/")
                url_path = joined.lstrip("/")
        else:
            continue                           # unknown scheme, not ours

        target = resolve_file(url_path)
        if target is None:
            broken.append(f"{rel} -> {url} (no such page or asset in the build)")
            continue
        checked_links += 1

        fragment = split.fragment
        if fragment:
            key = os.path.relpath(target, PUBLIC).replace(os.sep, "/")
            page2 = pages.get(key)
            if page2 is not None:
                if fragment not in page2.ids:
                    broken.append(f"{rel} -> {url} (no id {fragment!r} on {key})")
                    continue
                checked_fragments += 1
        if tag in ASSET_TAGS:
            checked_assets += 1

if broken:
    for line in broken[:10]:
        print(f"check: FAIL — {line}", file=sys.stderr)
    if len(broken) > 10:
        print(f"check: FAIL — and {len(broken) - 10} more", file=sys.stderr)
    fail(f"{len(broken)} broken link(s)/fragment(s) across {len(pages)} pages")

print(f"check: links — {len(pages)} pages, {checked_links} internal links, "
      f"{checked_fragments} fragments, {checked_assets} local assets: all resolve")
