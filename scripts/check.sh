#!/usr/bin/env bash
# One-shot verification for agents and CI: clear caches, build exampleSite
# with --minify, then assert the artifacts that matter. Clean exit = green.
# resources/ goes first: Hugo's processed-image cache does not key on
# images.Text font bytes, so a stale cache produces lying green builds.
set -euo pipefail

cd "$(dirname "$0")/../exampleSite"
rm -rf public resources

hugo --themesDir ../.. --minify --quiet

fail() { echo "check: FAIL — $1" >&2; exit 1; }

# llms.txt: machine-readable site index generated for agents
[ -s public/llms.txt ] || fail "llms.txt missing or empty"
grep -q "^# sigil-demo" public/llms.txt || fail "llms.txt lacks the site title"
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

echo "check: all green"
