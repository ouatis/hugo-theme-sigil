# hugo-theme-sigil

**English** | [中文](README.zh.md) | [日本語](README.ja.md)

**A minimal literary theme for [Hugo](https://gohugo.io/): old paper, three
inks, and typography that stays out of the way.**

[![Hugo Themes](https://img.shields.io/badge/Hugo--Themes-@sigil-blue)](https://themes.gohugo.io/themes/hugo-theme-sigil/)
[![Minimum Hugo Version](https://img.shields.io/static/v1?label=Hugo&message=v0.156.0%2B&color=blue&logo=hugo)](https://github.com/gohugoio/hugo/releases)
[![Release](https://img.shields.io/github/v/tag/ouatis/hugo-theme-sigil?sort=semver&label=release)](https://github.com/ouatis/hugo-theme-sigil/releases)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

> A deep customization of
> [PaperMod](https://github.com/adityatelange/hugo-PaperMod) — see
> [why it is a separate theme](#why-a-separate-theme-not-a-papermod-pr).

|  |  |
| --- | --- |
| **Live demo** | <https://ouatis.com/hugo-theme-sigil/> |
| **Typography showcase** | <https://ouatis.com/hugo-theme-sigil/posts/typography/> |
| **Example site source** | [exampleSite/](exampleSite/) |

![Screenshot](https://raw.githubusercontent.com/ouatis/hugo-theme-sigil/main/images/screenshot.png)

---

## Features

`∴ vermilion responds · ink-green informs · amber highlights`

- **Tufte-style sidenotes** -- footnotes set in the margin beside their
  reference on wide screens (≥1280px); endnotes on narrow ones.
- **Circular-reveal theme toggle** -- dark mode opens from the click point via
  the View Transitions API; a soft transition where unsupported.
- **Ghost-year archives** -- each year set as a large background numeral on
  the archives page.
- **Full-text RSS** -- whole articles in the feed, not summaries.
- **CJK font subsetting** -- `build-fonts.sh` emits IBM Plex woff2 slices
  keyed by unicode-range; readers download kilobytes, not megabytes.
- **Three-color system** -- vermilion, ink-green, amber; nothing else.
- **PaperMod essentials** -- Fuse.js search, taxonomies, breadcrumbs, TOC,
  code copy buttons, Open Graph / Twitter / Schema metadata, and built-in
  zh-CN / en / ja strings.

## Install

Try it from the example site:

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

Use it in your own site:

```bash
# as a git submodule (recommended for CI deployments)
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# or a plain clone
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
```

Set `baseURL` to your own domain before deploying (the example site ships
with `https://example.com/`).

## Configuration

Theme-specific params:

| Param | Default | Description |
| --- | --- | --- |
| `sgKicker` | hidden | Small line above the homepage title |
| `sgReading` / `sgPlaying` / `sgMotto` | hidden | Rotating status under the hero seal |
| `sgSealImage` | ∴ glyph | Seal image on the homepage |
| `ShowFullTextinRSS` | `false` | Full article content in the RSS feed |
| `ShowAllPagesInArchive` | `false` | Archives list all pages, not only posts |
| `disableLangToggle` | `false` | Hide the language switcher |
| `disableSpecial1stPost` | `false` | Plain styling for the first home entry |

Commonly used params inherited from PaperMod work as-is:

| Param | Default | Description |
| --- | --- | --- |
| `defaultTheme` | `auto` | `light` / `dark` / `auto` |
| `ShowToc` / `TocOpen` | `false` | Table of contents on posts |
| `ShowCodeCopyButtons` | `false` | Copy button on code blocks |
| `ShowBreadCrumbs` | `false` | Breadcrumbs on posts |
| `ShowReadingTime` / `ShowWordCount` | `false` | Post meta |
| `ShowPostNavLinks` | `false` | Prev / next links |
| `showRelated` | `true` | Related posts below an article |
| `editPost` | hidden | "Edit" link under posts (`URL`, `Text`) |
| `socialIcons` | hidden | Profile icons; github / rss / steam use Phosphor, the rest fall back to the built-in set |
| `homeInfoParams` / `profileMode` | — | Homepage mode and its content |
| `hideFooter`, `hideMeta`, `hideSummary`, … | `false` | Per-page overrides |

Sidenotes, the ghost-year archive background, and the circular-reveal theme
toggle are automatic — no param needed. See
[exampleSite/hugo.toml](exampleSite/hugo.toml) for a complete example. The
example site is in English; the theme ships with zh-CN / en / ja strings.

## Fonts & sidenotes

Before your first build:

```bash
pip install "fonttools[woff]"
scripts/build-fonts.sh
```

The script emits woff2 slices keyed by unicode-range from the glyphs your site
actually uses — readers download a few KB on demand; without it the theme
falls back to system fonts. Footnotes render as margin notes beside their
reference on wide screens (≥1280px, Tufte-style) and fall back to endnotes on
narrow screens.

## Performance

Accessibility 100 · Best Practices 96 · CLS 0 on the live demo
([Lighthouse](https://developer.chrome.com/docs/lighthouse/), mobile). Run
your own audit via
[PageSpeed Insights](https://pagespeed.web.dev/report?url=https%3A%2F%2Fouatis.com%2Fhugo-theme-sigil%2F).

## Why a separate theme (not a PaperMod PR)

Sigil is a deep customization of PaperMod, but it departs from it in ways that
would not fit upstream:

- **Tufte-style sidenotes**: footnotes are cloned into the margin next to
  their reference on wide screens and fall back to endnotes when narrow.
- **Circular-reveal theme toggle**: dark mode switches through a View
  Transitions API circle expanding from the click point, with a soft fallback.
- **Ghost-year archives**: the archives page sets each year as a large
  background numeral instead of a heading row.
- **Full-text RSS** and a **font-subsetting pipeline**: `build-fonts.sh`
  generates IBM Plex woff2 slices keyed by unicode-range, so CJK readers
  download kilobytes, not megabytes.
- A strict three-color literary design system (vermilion / ink-green / amber)
  and zh-CN-first multilingual strings.

## License

MIT — see [LICENSE](LICENSE).

Based on [PaperMod](https://github.com/adityatelange/hugo-PaperMod) · fonts
[IBM Plex](https://github.com/IBM/plex) (SIL OFL 1.1) · icons
[Phosphor Icons](https://phosphoricons.com/) (MIT) · search
[Fuse.js](https://github.com/krisk/fuse) (Apache-2.0)
