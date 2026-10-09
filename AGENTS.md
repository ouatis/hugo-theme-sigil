# AGENTS.md

Notes for AI agents working on this repository. Humans: the README is your
entry point; this file is the maintainer's cheat sheet.

## What this is

Sigil — a restrained literary blog theme for Hugo (≥ 0.166), deep fork of
[PaperMod](https://github.com/adityatelange/hugo-PaperMod). The MIT license
and the PaperMod attribution chain in `LICENSE` / `NOTICE.md` must survive
every change.

## Build & verify

```bash
# interactive preview
cd exampleSite && hugo server --themesDir ../..

# one-shot verification (clears caches, builds with --minify, asserts artifacts)
bash scripts/check.sh
```

A clean exit from `scripts/check.sh` is the definition of "works". Run it
before proposing any change. CI (`.github/workflows/demo.yml`) builds
exampleSite for the demo site; fonts are regenerated there on every deploy.

Environment: Hugo 0.166 (match CI). Font tooling needs python3 with
fonttools + brotli. On Windows, `python3` may be the Store stub — the local
setup uses a shim earlier in PATH; in Git Bash, PATH entries must use POSIX
form (`/c/...`), a `C:/...` entry silently does not take effect. Never pipe a
foreground `hugo server` into `head` (SIGPIPE kills it).

## Map

- `assets/css/extended/sigil.css` — the design layer (palette, typography,
  components). `assets/css/core/theme-vars.css` — legacy PaperMod color vars.
- `assets/css/extended/` — the **concat contract**: `head.html` concatenates
  the theme's own `sigil.css`/`fonts.css` FIRST, then every site-level
  `css/extended/*.css` LAST. Site overrides always win ties. Do not fix
  specificity with `html:root` hacks — the concat order is the mechanism.
- `layouts/partials/templates/` — OG / Twitter / Schema partials. Call
  partials with the FULL path (`templates/_funcs/get-page-images`); short
  names resolve inconsistently and broke og:image silently once.
- Site override points (never edit core templates to customize):
  `extend_head.html`, `extend_footer.html`, `comments.html` (intentionally an
  empty stub), render hooks under `_default/_markup/`, anything in the site's
  `layouts/` or `assets/css/extended/`.

## Page parameter contract (for content generators)

Front matter or site params the theme reads:

| Param | Effect |
| --- | --- |
| `math` / `mermaid` / `lightbox` | opt-ins; nothing loads on pages that don't set them |
| `ogAutoCard` | build-time OG card from title (needs `ogCardFont` on CJK sites) |
| `showRelated` | related-posts block (default on) |
| `cover.image` / `cover.relative` | cover image, supersedes the OG card |
| `searchHidden`, `placeholder` | search index exclusion / search input placeholder |
| `hiddenInHomeList` | keep a post out of the homepage feed |
| `sgSeriesFrom`, `sgSeriesTab` | series navigation (site-level) |
| `archives.showAuthor` | author on archive rows (default off) |

Sigil-specific site params use the `sg*` prefix (`sgKicker`, `sgHomeTitle`,
`sgReading`, `sgPlaying`, `sgMotto`, `sgSealImage`, `sgDaysInCage`,
`sgSearchEmpty`, `sgSeriesFrom`, `sgSeriesTab`). Inherited PaperMod params
keep their names.

## Pitfalls (each cost a real debugging session)

1. **Hugo's processed-image cache (`resources/_gen`) does not key on
   `images.Text` font bytes.** After changing any font, `rm -rf resources`
   before trusting a local pass — stale cache produces green builds that are
   lies.
2. **pyftsubset output flavor defaults to the input's.** Subsetting a
   `.woff2` into a `.ttf` filename still writes `wOF2` bytes, which Go's
   sfnt parser rejects (`sfnt: invalid font`). Use `--flavor=none`.
3. **goldmark passthrough config key is `enable`, not `enabled`** — wrong key
   is a silent no-op, inline `\(...\)` math then gets eaten by markdown.
4. **Partial names must be full paths** from `partials/`, including the
   `templates/` prefix.
5. **IBM Plex has no U+2234 (∴) glyph** — the OG card's mark is baked into
   `assets/og/base.png`; don't try to draw it with `images.Text`.
6. **`check.sh` asserts uncommitted `static/fonts/` artifacts** — fresh
   clone: `bash scripts/build-fonts.sh corpus` first; a failed download
   wipes `static/fonts/` (`git checkout -- static/` restores).

## Conventions

- i18n: strings go through `i18n "key" | default "English"`; fill
  `en`, `zh-CN`, `zh`, `ja`; the other ~45 languages fall back gracefully.
- Third-party code gets vendored only with an attribution note in
  `NOTICE.md`; large dependencies that can't be vendored use a pinned CDN
  with SRI (see mermaid).
- exampleSite keeps **exactly three posts**. Feature demos fold into
  `posts/typography/` (which enables math + mermaid + lightbox); do not add
  pages.
- New features are opt-in per page or site, and load nothing when disabled.

## Public contract

`docs/api.md` is the frozen public API (params, `sg-*` classes, output
formats, data shapes) as of v0.9.0. Renames need a deprecation window;
removals wait for a major. Check it before touching any param or class name.
