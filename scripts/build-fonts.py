#!/usr/bin/env python3
"""Prepare the IBM Plex Sans family for the theme demo — no bash required.

Python equivalent of build-fonts.sh (same cache, same output layout), for
environments without curl/tar (e.g. Windows). The official split woff2 files
are extracted from pinned IBM Plex npm packages; SC and JP keep their own
unicode-range CSS so Japanese kanji do not accidentally use simplified-Chinese
glyphs.

Usage:
    python scripts/build-fonts.py            # latin + SC + JP
    python scripts/build-fonts.py --latin    # latin only (the committed bootstrap)
"""
import argparse
import os
import tarfile
import urllib.request
from pathlib import Path

IBM_PLEX_VERSION = "1.1.0"
FONT_DIR = Path(__file__).resolve().parent.parent / "static" / "fonts" / "ibm-plex"
CACHE_DIR = Path(os.environ.get("IBM_PLEX_CACHE_DIR", ".cache/ibm-plex"))

WEIGHTS = ("Regular", "SemiBold", "Bold")
# package name -> (tar prefix depth handled implicitly, font family name)
PACKAGES = {
    "plex-sans": "IBMPlexSans",
    "plex-sans-sc": "IBMPlexSansSC",
    "plex-sans-jp": "IBMPlexSansJP",
}
# SC/JP woff2 live under a hinted/ subdirectory in the npm package.
HINTED = {"plex-sans": "", "plex-sans-sc": "hinted/", "plex-sans-jp": "hinted/"}
# output directory for each package's slices under static/fonts/ibm-plex/
OUT_DIR = {"plex-sans": "latin", "plex-sans-sc": "sc", "plex-sans-jp": "jp"}

RESULT_CSS_HEADER = (
    f"/* IBM Plex Sans family, generated from @ibm/plex-sans {IBM_PLEX_VERSION} packages. */\n"
)


def fetch_package(pkg: str) -> Path:
    """Download (once) and validate the pinned npm tarball for pkg."""
    archive = CACHE_DIR / f"{pkg}-{IBM_PLEX_VERSION}.tgz"
    if archive.is_file() and archive.stat().st_size > 0:
        try:
            with tarfile.open(archive, "r:gz") as probe:
                probe.getmembers()
            return archive
        except (tarfile.TarError, EOFError):
            pass

    url = f"https://registry.npmjs.org/@ibm/{pkg}/-/{pkg}-{IBM_PLEX_VERSION}.tgz"
    print(f"Downloading @ibm/{pkg}@{IBM_PLEX_VERSION}...")
    archive.parent.mkdir(parents=True, exist_ok=True)
    tmp = archive.with_suffix(".tgz.tmp")
    with urllib.request.urlopen(url, timeout=120) as resp, open(tmp, "wb") as out:
        out.write(resp.read())
    with tarfile.open(tmp, "r:gz") as probe:
        probe.getmembers()
    tmp.replace(archive)
    return archive


def extract_weight(archive: Path, pkg: str, weight: str, dest: Path) -> int:
    """Extract one weight's split css/woff2 files (basenames only) into dest."""
    family = PACKAGES[pkg]
    prefix = f"package/fonts/split/woff2/{HINTED[pkg]}{family}-{weight}"
    count = 0
    with tarfile.open(archive, "r:gz") as tar:
        for member in tar.getmembers():
            if not member.isfile():
                continue
            if member.name.startswith(prefix) and member.name.endswith((".css", ".woff2")):
                dest.mkdir(parents=True, exist_ok=True)
                data = tar.extractfile(member).read()
                (dest / Path(member.name).name).write_bytes(data)
                count += 1
    return count


def write_result_css(mode: str) -> None:
    lines = [RESULT_CSS_HEADER]
    for weight in WEIGHTS:
        lines.append(f'@import url("./latin/IBMPlexSans-{weight}.css");\n')
    if mode == "full":
        for pkg in ("plex-sans-sc", "plex-sans-jp"):
            for weight in WEIGHTS:
                lines.append(f'@import url("./{OUT_DIR[pkg]}/{PACKAGES[pkg]}-{weight}.css");\n')
    (FONT_DIR / "result.css").write_text("".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--latin", action="store_true",
                        help="latin bootstrap only (SC/JP stay system fonts)")
    args = parser.parse_args()
    mode = "latin" if args.latin else "full"

    wanted = ["plex-sans"] if mode == "latin" else list(PACKAGES)
    archives = {pkg: fetch_package(pkg) for pkg in wanted}

    import shutil
    shutil.rmtree(FONT_DIR, ignore_errors=True)

    total = 0
    for pkg in wanted:
        dest = FONT_DIR / OUT_DIR[pkg]
        for weight in WEIGHTS:
            total += extract_weight(archives[pkg], pkg, weight, dest)

    write_result_css(mode)
    print(f"IBM Plex assets ({mode} mode): {total} files -> {FONT_DIR}")


if __name__ == "__main__":
    main()
