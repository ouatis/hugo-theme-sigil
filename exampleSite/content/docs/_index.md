---
title: "Documentation"
translationKey: "docs"
slug: docs
categories: []
---

# Documentation

Everything you need to make SIGIL your own. This page is the map; the
[configuration examples](../config-example/) are the copy-paste starting points,
and the [API contract](../api/) is the frozen reference. Requirements and
installation are in the
[README](https://github.com/ouatis/hugo-theme-sigil#install).

{{< page-anatomy >}}

## Getting Started

SIGIL runs on Hugo ≥ 0.166 extended with no build step. Set your
`baseURL`, pick a `[params]` block from the examples, and write posts in
Markdown. Out of the box you get Latin typography, sidenotes, search, and
dark mode; CJK needs the optional font subset
(`bash scripts/build-fonts.sh corpus`) if you want it to render in real Plex
rather than the system fallback.

## Writing with the features

Each feature is opt-in per page, so nothing loads unless a post asks for it.
In a post's front matter:

```toml
math    = true   # KaTeX for $...$ and \(...\)
mermaid = true   # Mermaid diagrams from ```mermaid blocks
lightbox = true  # click-to-enlarge images
```

- **Sidenotes** — write a footnote `[^1]` and define it `[^1]: note text`.
  On wide screens it floats to the margin; on narrow screens it collects at
  the end. Same Markdown, no theme-specific syntax.
- **Multilingual** — give translations the same `translationKey`; the language
  switcher jumps to the matching post. Pages without a translation fall back
  to that language's home. Right-to-left languages (Arabic, Persian, Hebrew,
  Central Kurdish) mirror the whole layout — sidenotes, the floating TOC,
  arrows — when the language declares `direction = "rtl"` in your site config.
- **Fonts** — `latin` (default, clean checkout), `corpus` (demo CJK, ~200 KB),
  or `full` (complete SC + JP, ~3 MB). Pick per site, not per page.

The [typography sample](../posts/typography/) shows all of this on one page —
read it to see the result before writing your own.

## Configuration

Use the [configuration examples](../config-example/) as the copy-paste starting
point. The [API contract](../api/) is the complete reference; the sections below
cover the choices most sites make first.

### Configure by task

| I want to… | Set | Scope |
| --- | --- | --- |
| Show a line above the homepage title | `sgKicker` | site |
| Change the homepage title or seal | `sgHomeTitle` / `sgSealImage` | site |
| Rotate a status line | any `sgReading` / `sgListening` / `sgWatching` / `sgPlaying` / `sgWriting` / `sgExploring` / `sgMotto` | site |
| Limit the homepage or add a series panel | `homePageSize` / `sgSeriesFrom` | site |
| Publish full articles in RSS | `ShowFullTextinRSS` | site |
| Add an index for agents | `LLMSTXT` and optionally `LLMSFULL` in `[outputs] home` | site |
| Generate an OG card without a cover | `ogAutoCard` (+ `ogCardFont` for CJK) | site |
| Add maths, diagrams, or a lightbox | `math` / `mermaid` / `lightbox` | page or site |
| Hide a page from the home list or search | `hiddenInHomeList` / `searchHidden` | page |
| Turn off related posts or comments | `showRelated: false` / `comments: false` | page |

### Essential site block

Common PaperMod options work as usual. This is the smallest useful SIGIL
block; omit the homepage lines you do not need:

```toml
[params]
  mainSections = ["posts"]
  sgKicker = "A Hugo theme"
  sgHomeTitle = "SIGIL"
  sgSealImage = "/images/seal.png"
  homePageSize = 10

  # Any subset; rotates every 6s and honours prefers-reduced-motion
  sgReading = "The Book of Disquiet"
  sgPlaying = "Disco Elysium"
  sgMotto = "Ink, paper, and everything in threes."

# Search needs JSON output and a search page
[outputs]
  home = ["HTML", "RSS", "JSON", "JSONFeed", "LLMSTXT", "LLMSFULL"]

[params.fuseOpts]
  isCaseSensitive = false
  shouldSort = true
  minMatchCharLength = 2
  keys = ["title", "summary", "content"]

# Tufte sidenotes need raw HTML in Markdown
[markup.goldmark.renderer]
  unsafe = true
```

### Machine-readable output

Add `LLMSTXT` for a page and post index and `LLMSFULL` for the same header
followed by every post's full text. Keep `JSON` in the same output list when
the client-side search page is enabled. The key-pages section finds About,
Archives, taxonomies, and RSS automatically; override
`layouts/home.llmstxt.txt` when you need to curate it.

Front-matter switches include `hiddenInHomeList`, `searchHidden`,
`showRelated: false`, and `comments: false`. See the [API contract](../api/) for
inherited PaperMod options and the complete SIGIL surface.

## Fonts and performance

The theme ships a Latin subset and works without a font build. Run
`bash scripts/build-fonts.sh corpus` when the demo's CJK should render in IBM
Plex; the current SC regular and bold corpus is about 200 KB. `full` provides
complete SC + JP coverage and is about 3 MB on a text-heavy page.

On the minified demo build, HTML plus CSS stays under 100 KB and JavaScript is
not loaded from an external runtime. Optional assets load only when requested:
search is about 18 KB, KaTeX about 300 KB plus fonts, GLightbox about 70 KB,
and the diagram renderer about 275 KB gzipped.
The densest demo page loads about 284 KB of bundled fonts in English/Chinese
and 222 KB in Japanese; the CI budget is 320 KB.

## API Reference

The theme's public contract is frozen as of v0.12.0 — listed parameters will
not be renamed or removed without a deprecation window. The
[API contract](../api/) lists every site param, front-matter param, CSS hook,
and extension point. Treat anything not listed there as internal, and safe to
change without notice.

## Recipes

Common builds on top of the theme — every one uses a mechanism that ships
today, nothing to install:

- **Shadow a partial.** Create `layouts/partials/extend_post_content.html` in
  your site; whatever it renders appears after every article's body — a
  colophon, a series CTA, a license line. `extend_head.html` and
  `extend_footer.html` work the same way.
- **Site-level styles.** Any rule in `assets/css/extended/*.css` of your site
  loads after the theme and wins ties — restyle rules, quiet the chrome, retune
  the palette without forking.
- **Fonts in CI.** Call the reusable workflow
  (`ouatis/hugo-theme-sigil/.github/workflows/fonts.yml`, `mode` input) and the
  font subsets arrive as an artifact for your `static/fonts`.
- **A series.** Point `sgSeriesFrom` at a curation page whose body list defines
  the reading order; the floating panel appears on every member post.
- **CJK OG cards.** Set `ogCardFont` to a subset TTF that can draw your titles
  and enable `ogAutoCard` — every coverless page ships with a paper card.
- **Per-page opt-ins.** `math`, `mermaid`, `lightbox`, `showRelated`,
  `hiddenInHomeList` — each page loads only what it asks for.
