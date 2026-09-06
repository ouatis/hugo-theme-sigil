#!/usr/bin/env bash
# Prepare the IBM Plex Sans family for the theme demo.
#
# The official split woff2 files are extracted from pinned IBM Plex npm
# packages. SC and JP keep their own unicode-range CSS so Japanese kanji do
# not accidentally use simplified-Chinese glyphs.
#
# Usage: build-fonts.sh [full|latin]
#   full  (default) latin + SC + JP
#   latin           latin only — the bootstrap subset committed to the repo
#
# A pure-python equivalent lives in build-fonts.py (no bash required).
set -euo pipefail

cd "$(dirname "$0")/.."

IBM_PLEX_VERSION="1.1.0"
FONT_DIR="static/fonts/ibm-plex"
CACHE_DIR="${IBM_PLEX_CACHE_DIR:-.cache/ibm-plex}"
MODE="${1:-full}"

case "$MODE" in
    full|latin) ;;
    *) echo "usage: $0 [full|latin]" >&2; exit 1 ;;
esac

mkdir -p "$CACHE_DIR" "$FONT_DIR"

command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }

fetch_package() {
    local pkg="$1"
    local archive="${CACHE_DIR}/${pkg}-${IBM_PLEX_VERSION}.tgz"
    local url="https://registry.npmjs.org/@ibm/${pkg}/-/${pkg}-${IBM_PLEX_VERSION}.tgz"
    local tmp="${archive}.tmp.$$"

    if [ -s "$archive" ] && tar -tzf "$archive" >/dev/null 2>&1; then
        return
    fi

    rm -f "$archive" "$tmp"
    echo "Downloading @ibm/${pkg}@${IBM_PLEX_VERSION}..."
    curl -fL --retry 3 --retry-all-errors --connect-timeout 20 -o "$tmp" "$url"
    tar -tzf "$tmp" >/dev/null
    mv "$tmp" "$archive"
}

if [ "$MODE" = "latin" ]; then
    fetch_package "plex-sans"
else
    for pkg in plex-sans plex-sans-sc plex-sans-jp; do
        fetch_package "$pkg"
    done
fi

rm -rf "static/fonts/split" "static/fonts/charset.txt" "${FONT_DIR}"
mkdir -p "${FONT_DIR}/latin"
if [ "$MODE" = "full" ]; then
    mkdir -p "${FONT_DIR}/sc" "${FONT_DIR}/jp"
fi

for weight in Regular SemiBold Bold; do
    tar -xzf "${CACHE_DIR}/plex-sans-${IBM_PLEX_VERSION}.tgz" \
        -C "${FONT_DIR}/latin" --strip-components=4 --wildcards \
        "package/fonts/split/woff2/IBMPlexSans-${weight}*.css" \
        "package/fonts/split/woff2/IBMPlexSans-${weight}*.woff2"
    if [ "$MODE" = "full" ]; then
        tar -xzf "${CACHE_DIR}/plex-sans-sc-${IBM_PLEX_VERSION}.tgz" \
            -C "${FONT_DIR}/sc" --strip-components=5 --wildcards \
            "package/fonts/split/woff2/hinted/IBMPlexSansSC-${weight}*.css" \
            "package/fonts/split/woff2/hinted/IBMPlexSansSC-${weight}*.woff2"
        tar -xzf "${CACHE_DIR}/plex-sans-jp-${IBM_PLEX_VERSION}.tgz" \
            -C "${FONT_DIR}/jp" --strip-components=5 --wildcards \
            "package/fonts/split/woff2/hinted/IBMPlexSansJP-${weight}*.css" \
            "package/fonts/split/woff2/hinted/IBMPlexSansJP-${weight}*.woff2"
    fi
done

{
    printf '%s\n' "/* IBM Plex Sans family, generated from @ibm/plex-sans ${IBM_PLEX_VERSION} packages. */"
    printf '%s\n' '@import url("./latin/IBMPlexSans-Regular.css");'
    printf '%s\n' '@import url("./latin/IBMPlexSans-SemiBold.css");'
    printf '%s\n' '@import url("./latin/IBMPlexSans-Bold.css");'
    if [ "$MODE" = "full" ]; then
        printf '%s\n' '@import url("./sc/IBMPlexSansSC-Regular.css");'
        printf '%s\n' '@import url("./sc/IBMPlexSansSC-SemiBold.css");'
        printf '%s\n' '@import url("./sc/IBMPlexSansSC-Bold.css");'
        printf '%s\n' '@import url("./jp/IBMPlexSansJP-Regular.css");'
        printf '%s\n' '@import url("./jp/IBMPlexSansJP-SemiBold.css");'
        printf '%s\n' '@import url("./jp/IBMPlexSansJP-Bold.css");'
    fi
} > "${FONT_DIR}/result.css"

find "${FONT_DIR}" -type f -name '*.bin' -delete
printf 'IBM Plex assets (%s mode): ' "$MODE"
find "${FONT_DIR}" -type f | wc -l
