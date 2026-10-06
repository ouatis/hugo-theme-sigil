#!/usr/bin/env python3
"""Build the demo's SC corpus subset from the example site's own characters.

Scans exampleSite content/config for the characters it actually uses, then
subsets IBM Plex Sans SC (Regular/Bold) down to exactly those glyphs. The
demo's CJK renders in real IBM Plex for a fraction of the full-font weight.

Reads:  .cache/ibm-plex/work/IBMPlexSansSC-{Regular,Bold}.woff2  (the complete
        hinted fonts, extracted by build-fonts.sh corpus)
Writes: static/fonts/ibm-plex/sc/IBMPlexSansSC-{weight}-corpus.woff2
        static/fonts/ibm-plex/sc/corpus.css  (@font-face fragment)
"""
import glob
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

chars = set()
for pat in ["exampleSite/content/**/*.md", "exampleSite/hugo.toml",
            "exampleSite/layouts/**/*.html"]:
    for path in glob.glob(pat, recursive=True):
        try:
            chars |= set(open(path, encoding="utf-8").read())
        except UnicodeDecodeError:
            pass
chars.add("\u21a9")  # goldmark 脚注回链
subset = "".join(sorted(c for c in chars if ord(c) >= 0x2000))
if not subset:
    print("corpus: 示例站无 CJK 字符,跳过 SC 子集")
    sys.exit(0)

os.makedirs("static/fonts/ibm-plex/sc", exist_ok=True)
faces = []
for weight, wnum in (("Regular", 400), ("Bold", 700)):
    src = f".cache/ibm-plex/work/IBMPlexSansSC-{weight}.woff2"
    out = f"static/fonts/ibm-plex/sc/IBMPlexSansSC-{weight}-corpus.woff2"
    subprocess.run([sys.executable, "-m", "fontTools.subset", src,
                    f"--text={subset}", "--flavor=woff2",
                    f"--output-file={out}", "--layout-features=*"], check=True)
    ords = sorted(ord(c) for c in subset)
    runs, start, prev = [], ords[0], ords[0]
    for o in ords[1:]:
        if o == prev + 1:
            prev = o
            continue
        runs.append(f"U+{start:X}" if start == prev else f"U+{start:X}-{prev:X}")
        start = prev = o
    runs.append(f"U+{start:X}" if start == prev else f"U+{start:X}-{prev:X}")
    faces.append(
        "@font-face {\n"
        '  font-family: "IBM Plex Sans SC";\n'
        "  font-style: normal;\n"
        f"  font-weight: {wnum};\n"
        "  font-display: swap;\n"
        f'  src: url("./sc/IBMPlexSansSC-{weight}-corpus.woff2") format("woff2");\n'
        f"  unicode-range: {','.join(runs)};\n"
        "}\n")
    print(f"corpus: IBMPlexSansSC-{weight}-corpus.woff2 "
          f"({os.path.getsize(out) // 1024}KB)")

open("static/fonts/ibm-plex/sc/corpus.css", "w", encoding="utf-8").write(
    "/* SC corpus subset: the example site's own characters. */\n"
    + "\n".join(faces))
print(f"corpus: {len(subset)} chars -> corpus.css")
