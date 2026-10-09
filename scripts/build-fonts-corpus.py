#!/usr/bin/env python3
"""Build the demo's SC and JP corpus subsets from the example site's own
characters.

Scans exampleSite content/config for the characters it actually uses, then
subsets IBM Plex Sans SC and IBM Plex Sans JP (Regular/Bold) down to exactly
those glyphs. The demo's CJK renders in real IBM Plex for a fraction of the
full-font weight.

SC covers every non-ASCII character on the site (Chinese pages, plus Chinese
that appears inside English or Japanese copy). JP is narrower on purpose: it
covers only the characters the Japanese pages use, so Japanese kanji get
Japanese glyph forms instead of simplified-Chinese ones. sigil.css prefers
IBM Plex Sans JP under html:lang(ja) for exactly that reason.

Reads:  .cache/ibm-plex/work/IBMPlexSans{SC,JP}-{Regular,Bold}.woff2  (the
        complete hinted fonts, extracted by build-fonts.sh corpus)
Writes: static/fonts/ibm-plex/sc/corpus.css and .../sc/*-corpus.woff2
        static/fonts/ibm-plex/jp/corpus.css and .../jp/*-corpus.woff2
"""
import glob
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

# CSS output uses LF regardless of this script's own line endings.
NL = "\n"

SCAN = ["exampleSite/content/**/*.md", "exampleSite/hugo.toml",
        "exampleSite/layouts/**/*.html"]

site_chars, ja_chars = set(), set()
for pat in SCAN:
    for path in glob.glob(pat, recursive=True):
        try:
            text = open(path, encoding="utf-8").read()
        except UnicodeDecodeError:
            continue
        # SC covers every CJK glyph anywhere on the site — including the
        # traditional-character poem quoted in footnotes on the English page.
        # IBM Plex Sans SC carries those forms; if they are missing from the
        # subset the page falls back to a system font, or worse, pulls in JP
        # for kanji that should be SC glyphs. JP is narrower: only the
        # Japanese pages need it, chiefly for kana.
        site_chars |= set(text)
        if path.endswith(".ja.md"):
            ja_chars |= set(text)

# goldmark footnote return arrow, and the nav labels from i18n/ that every
# language's pages show — each subset needs the glyphs it actually renders.
site_chars.add(chr(0x21A9))
ja_chars.add(chr(0x21A9))
for path in glob.glob("exampleSite/i18n/**/*", recursive=True):
    if os.path.isfile(path):
        try:
            nav = open(path, encoding="utf-8").read()
        except UnicodeDecodeError:
            continue
        site_chars |= set(nav)
        ja_chars |= set(nav)


def build(family, prefix, chars, outdir):
    """Subset one font family down to `chars`; write corpus.css into outdir."""
    subset = "".join(sorted(c for c in chars if ord(c) >= 0x2000))
    if not subset:
        print(f"corpus: {family} has no glyphs to keep, skipping")
        return
    os.makedirs(outdir, exist_ok=True)
    faces = []
    for weight, wnum in (("Regular", 400), ("Bold", 700)):
        src = f".cache/ibm-plex/work/{prefix}-{weight}.woff2"
        out = f"{outdir}/{prefix}-{weight}-corpus.woff2"
        subprocess.run([sys.executable, "-m", "fontTools.subset", src,
                        f"--text={subset}", "--flavor=woff2",
                        f"--output-file={out}",
                        "--layout-features=*"], check=True)
        ords = sorted(ord(c) for c in subset)
        runs, start, prev = [], ords[0], ords[0]
        for o in ords[1:]:
            if o == prev + 1:
                prev = o
                continue
            runs.append(f"U+{start:X}" if start == prev else f"U+{start:X}-{prev:X}")
            start = prev = o
        runs.append(f"U+{start:X}" if start == prev else f"U+{start:X}-{prev:X}")
        face = NL.join([
            "@font-face {",
            f'  font-family: "{family}";',
            "  font-style: normal;",
            f"  font-weight: {wnum};",
            "  font-display: swap;",
            f'  src: url("./{prefix}-{weight}-corpus.woff2") format("woff2");',
            f"  unicode-range: {','.join(runs)};",
            "}",
        ])
        faces.append(face)
        print(f"corpus: {prefix}-{weight}-corpus.woff2 "
              f"({os.path.getsize(out) // 1024}KB)")
    with open(f"{outdir}/corpus.css", "w", encoding="utf-8") as fh:
        fh.write(f"/* {family} corpus subset: the example site's own characters. */" + NL)
        fh.write(NL.join(faces))
    print(f"corpus: {family} {len(subset)} chars -> {outdir}/corpus.css")


build("IBM Plex Sans SC", "IBMPlexSansSC", site_chars, "static/fonts/ibm-plex/sc")
build("IBM Plex Sans JP", "IBMPlexSansJP", ja_chars, "static/fonts/ibm-plex/jp")
