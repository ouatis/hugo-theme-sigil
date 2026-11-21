#!/usr/bin/env bash
# Build this checkout as a theme in a brand-new Hugo site.
# The site deliberately has one config line and one post: this catches install
# regressions that exampleSite's richer configuration can hide.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
THEME_ROOT="${THEME_ROOT:-$(cd -- "$SCRIPT_DIR/../.." && pwd)}"
TEMP_ROOT=""
SITE_DIR="${SITE_DIR:-}"

cleanup() {
  if [[ -n "$TEMP_ROOT" ]]; then
    rm -rf "$TEMP_ROOT"
  fi
}
trap cleanup EXIT

if [[ -z "$SITE_DIR" ]]; then
  TEMP_ROOT="$(mktemp -d)"
  SITE_DIR="$TEMP_ROOT/sigil-zero-config"
else
  rm -rf "$SITE_DIR"
fi

hugo new site "$SITE_DIR" --force
mkdir -p "$SITE_DIR/themes" "$SITE_DIR/content/posts"

# A symlink keeps the test on the exact checkout under test. GitHub's Ubuntu
# runner supports it; the copy fallback keeps this helper usable on Windows
# checkouts where creating directory links may be disabled.
if ! ln -s "$THEME_ROOT" "$SITE_DIR/themes/hugo-theme-sigil" 2>/dev/null; then
  cp -R "$THEME_ROOT" "$SITE_DIR/themes/hugo-theme-sigil"
fi

# `hugo new site` writes a sample baseURL/title/locale. Replace that sample
# config so the installation contract really has only the theme declaration.
printf 'theme = "hugo-theme-sigil"\n' > "$SITE_DIR/hugo.toml"
cat > "$SITE_DIR/content/posts/hello.md" <<'MD'
---
title: "Hello from a fresh install"
---

A fresh Hugo site with one post is enough to render SIGIL.
MD

grep -qx 'theme = "hugo-theme-sigil"' "$SITE_DIR/hugo.toml"
[[ "$(wc -l < "$SITE_DIR/hugo.toml")" -eq 1 ]]
[[ "$(find "$SITE_DIR/content" -type f -name '*.md' | wc -l)" -eq 1 ]]

BUILD_LOG="$(hugo --logLevel info --source "$SITE_DIR" --destination "$SITE_DIR/public" 2>&1)" || {
  printf '%s\n' "$BUILD_LOG" >&2
  exit 1
}
if BAD="$(printf '%s\n' "$BUILD_LOG" | grep -E '^(WARN|ERROR|INFO[[:space:]]+deprecated:)' || true)" && [[ -n "$BAD" ]]; then
  printf '%s\n' "$BAD" >&2
  echo "FAIL: zero-config build emitted Hugo warnings or deprecation notices" >&2
  exit 1
fi
test -s "$SITE_DIR/public/index.html"
test -s "$SITE_DIR/public/posts/hello/index.html"
grep -q '<title>Hello from a fresh install' "$SITE_DIR/public/posts/hello/index.html"
printf 'OK: fresh site with one theme setting and one post rendered\n'
