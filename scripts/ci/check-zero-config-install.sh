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

hugo --source "$SITE_DIR" --destination "$SITE_DIR/public"
test -s "$SITE_DIR/public/index.html"
test -s "$SITE_DIR/public/posts/hello/index.html"
grep -q '<title>Hello from a fresh install' "$SITE_DIR/public/posts/hello/index.html"
printf 'OK: fresh site with one theme setting and one post rendered\n'
