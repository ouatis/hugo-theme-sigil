# hugo-theme-sigil

**English** | [中文](README.zh.md) | [日本語](README.ja.md)

A minimal Hugo blog theme: an old-paper background, a three-color system of
vermilion / ink-green / amber, IBM Plex Sans CJK typography, Tufte-style
sidenotes, full-text RSS, and a font-subsetting pipeline. A deep customization
of [PaperMod](https://github.com/adityatelange/hugo-PaperMod) (MIT).

**[Live demo](https://ouatis.com/hugo-theme-sigil/)**

![Screenshot](docs/screenshot.png)

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

| Param | Description | Default |
| --- | --- | --- |
| `params.sgKicker` | Small line above the homepage title | hidden |
| `params.sgReading` / `params.sgPlaying` / `params.sgMotto` | Rotating status below the Hero seal | hidden |
| `params.sgSealImage` | Homepage seal image; unset shows a ∴ glyph seal | ∴ glyph |
| `params.mainSections` | Content section for the home list and RSS | `["posts"]` |
| `params.author` | Post byline (RSS and article meta) | hidden |

See [exampleSite/hugo.toml](exampleSite/hugo.toml) for a complete example. The example site is in
English; the theme ships with zh-CN / en / ja strings.

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
