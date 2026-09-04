# hugo-theme-sigil

[中文](README.md) | **English** | [日本語](README.ja.md)

**A literary Hugo theme — ink, paper, and everything in threes.**

> [!IMPORTANT]
> **This theme is built primarily for Chinese writers.** The font pipeline,
> typographic settings, column width and line height all revolve around the
> Chinese reading experience. Other languages work, but the design and optimization prioritize the Chinese reading experience. (中文说明见 [README.md](README.md)；日本語は [README.ja.md](README.ja.md)。)

A literary Hugo theme based on a deep customization of
[PaperMod](https://github.com/adityatelange/hugo-PaperMod) (MIT): an old-paper
background, a three-color system of vermilion / ink-green / amber, IBM Plex Sans CJK
typography, Tufte-style sidenotes, full-text RSS, and a font-subsetting
pipeline that prepares the official IBM Plex Sans Latin, Chinese SC and Japanese split assets.

![Screenshot](docs/screenshot.png)

## Features

- **Three-color system** — vermilion (interaction) · ink-green (metadata) ·
  amber (highlight), with dark & light modes
- **Tufte-style sidenotes** — on wide screens, footnotes appear in the margin
  right beside their reference; falls back to endnotes on narrow screens
- **Font subsetting pipeline** — `scripts/build-fonts.sh` extracts the IBM Plex Sans Latin, Chinese SC and Japanese split assets
  from the official IBM Plex split assets; first-time visitors download a few
  KB instead of a 20 MB font
- **Full-text RSS**
- **Search-as-you-type** (fuse)
- **Archives / taxonomies / breadcrumbs / reading progress**
- **Multilingual** — zh-CN / en / ja strings built in
- Paper grain, a three-part colophon footer, hover-synced seal, and other
  quiet details

## Quick start

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

To use it in your own site:

```bash
git clone https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
# in hugo.toml:
# theme = "hugo-theme-sigil"
```

## Configuration

| Param | Description | Default |
| --- | --- | --- |
| `params.sgKicker` | Small line above the homepage title | hidden |
| `params.sgColophon` | Motif in the middle of the three-part footer | hidden |
| `params.sgSealImage` | Image for the homepage seal; unset shows a default ∴ glyph seal | ∴ glyph |
| `params.mainSections` | Content section for the home list and RSS | `["posts"]` |
| `params.author` | Post byline (used in RSS and article meta) | hidden |

See [exampleSite/hugo.toml](exampleSite/hugo.toml) for a complete example. The example site is intentionally Chinese-only; the theme itself supports zh-CN, en and ja configurations.

## Font subsetting

The theme uses IBM Plex Sans, IBM Plex Sans SC and IBM Plex Sans JP (IBM open-source font license). Chinese pages prefer IBM Plex Sans SC; Japanese pages prefer IBM Plex Sans JP. Before your first build, run:

```bash
pip install "fonttools[woff]"
scripts/build-fonts.sh
```

The script scans every glyph your site uses and emits woff2 slices keyed by
unicode-range — readers download a few KB on demand instead of a 20 MB font.
Without it, the theme falls back to system sans-serif fonts.

## Sidenotes

Footnotes automatically render as margin notes beside their reference on wide
screens (≥1440px, Tufte-style). Hovering a reference highlights its note and
vice versa; narrow screens fall back to end-of-post footnotes; printing
restores the endnote list; browsers without `:has` keep plain footnotes.

## Credits

Based on [PaperMod](https://github.com/adityatelange/hugo-PaperMod) (MIT).
Font: [IBM Plex](https://github.com/IBM/plex) (IBM open-source font license).

## License

MIT — see [LICENSE](LICENSE).
