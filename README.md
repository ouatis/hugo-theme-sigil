# hugo-theme-sigil

**English** | [中文](README.zh.md) | [日本語](README.ja.md)

A restrained literary theme for [Hugo](https://gohugo.io/), based on
[PaperMod](https://github.com/adityatelange/hugo-PaperMod).

Demo: <https://ouatis.com/hugo-theme-sigil/>

## Features

- Tufte-style sidenotes on wide screens, endnotes on narrow screens
- Ghost-year archive index
- Circular-reveal dark-mode toggle
- Full-text RSS
- IBM Plex typography with CJK font subsetting
- Search, taxonomies, breadcrumbs, TOC, code-copy buttons, and multilingual strings

## Install

```bash
git submodule add https://github.com/ouatis/hugo-theme-sigil themes/hugo-theme-sigil
```

```toml
# hugo.toml
theme = "hugo-theme-sigil"
```

Preview the example site:

```bash
git clone https://github.com/ouatis/hugo-theme-sigil
cd hugo-theme-sigil/exampleSite
hugo server --themesDir ../..
```

## Configuration

Common PaperMod options work as usual. Sigil-specific options:

| Parameter | Default | Purpose |
| --- | --- | --- |
| `sgKicker` | hidden | Text above the homepage title |
| `sgHomeTitle` | site title | Homepage title |
| `sgReading` / `sgPlaying` / `sgMotto` | hidden | Homepage status line |
| `sgSealImage` | `∴` | Homepage seal image |
| `ShowFullTextinRSS` | `false` | Include full articles in RSS |
| `ShowAllPagesInArchive` | `false` | Include all pages in archives |
| `homePageSize` | all | Homepage posts per page |

Frequently used inherited options include `defaultTheme`, `ShowToc`,
`TocOpen`, `ShowCodeCopyButtons`, `ShowBreadCrumbs`, `ShowReadingTime`,
`ShowWordCount`, `ShowPostNavLinks`, `showRelated`, and `socialIcons`.

See [exampleSite/hugo.toml](exampleSite/hugo.toml) for a complete example.

## Fonts

Latin IBM Plex files are included. Rebuild CJK subsets with:

```bash
bash scripts/build-fonts.sh
# or
python scripts/build-fonts.py
```

## License

MIT. See [LICENSE](LICENSE).

Based on PaperMod. Fonts: IBM Plex, SIL OFL 1.1. Icons: Phosphor Icons, MIT.
Search: Fuse.js, Apache-2.0.
