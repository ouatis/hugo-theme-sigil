# hugo-theme-sigil

**English** | [中文](README.zh.md) | [日本語](README.ja.md)

A minimal Hugo blog theme: an old-paper background, a three-color system of
vermilion / ink-green / amber, IBM Plex Sans CJK typography, Tufte-style
sidenotes, full-text RSS, and a font-subsetting pipeline. A deep customization
of [PaperMod](https://github.com/adityatelange/hugo-PaperMod) (MIT).

**[Live demo](https://ouatis.com/hugo-theme-sigil/)**

![Screenshot](https://raw.githubusercontent.com/ouatis/hugo-theme-sigil/main/images/screenshot.png)

## Why a separate theme (not a PaperMod PR)

Sigil is a deep customization of PaperMod, but it departs from it in ways that
would not fit upstream:

- **Tufte-style sidenotes**: footnotes are cloned into the margin next to their
  reference on wide screens and fall back to endnotes when narrow.
- **Circular-reveal theme toggle**: dark mode switches through a View
  Transitions API circle expanding from the click point, with a soft fallback.
- **Ghost-year archives**: the archives page sets each year as a large
  background numeral instead of a heading row.
- **Full-text RSS** and a **font-subsetting pipeline**: `build-fonts.sh`
  generates IBM Plex woff2 slices keyed by unicode-range, so CJK readers
  download kilobytes, not megabytes.
- A strict three-color literary design system (vermilion / ink-green / amber)
  and zh-CN-first multilingual strings.

## Quick start

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

To use it in your own site:

```bash
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# in hugo.toml: theme = "hugo-theme-sigil"
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

## License

MIT — see [LICENSE](LICENSE). Based on
[PaperMod](https://github.com/adityatelange/hugo-PaperMod); fonts
[IBM Plex](https://github.com/IBM/plex) (IBM open-source font license); icons
[Phosphor Icons](https://phosphoricons.com/) (MIT).
