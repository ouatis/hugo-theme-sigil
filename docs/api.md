# SIGIL Public API — frozen as of v0.9.0

This document defines the **public contract** of the theme. Items listed here
will not be renamed or removed in any minor release; breaking changes require a
major version (1.0 → 2.0) and a deprecation window (see policy below).
Anything **not** listed here is internal and may change without notice.

## Deprecation policy

1. Renaming or re-homing a frozen item: the old name keeps working for at
   least **two minor releases** and logs a Hugo `deprecated` warning.
2. Removal of a deprecated name happens no earlier than the next **major**
   release.
3. New params are **additive** (minor releases) unless they change the meaning
   of an existing frozen param.

## Site params

### SIGIL-native

| Param | Purpose |
| --- | --- |
| `sgKicker` | Small line above the homepage title |
| `sgHomeTitle` | Hero title override (browser-tab `<title>` stays the site title) |
| `sgSealImage` | Seal image on the homepage |
| `sgReading` / `sgListening` / `sgWatching` / `sgPlaying` / `sgWriting` / `sgExploring` / `sgMotto` | Rotating status under the hero seal. Each renders an icon + i18n label item; set any subset |
| `sgDaysInCage` | Status line day counter, "Day N in the Cage" (from earliest post). Opt-in |
| `sgSeriesFrom` | Points to a curation page whose body list defines a series reading order |
| `sgSeriesTab` | Tab label of the floating series panel |
| `sgSearchEmpty` | Custom empty-state text for search |
| `ShowTotalWords` | Total word count next to the homepage post count |
| `ShowDefaultLanguageContent` | Non-default-language homes/archives/RSS/search list the default language's content |
| `ShowContentLanguageNote` | i18n `posts_language_note` on non-default-language homes |
| `ShowFullTextinRSS` | Full article content in RSS `<content:encoded>` |
| `homePageSize` | Posts per homepage page |
| `ogAutoCard` | Build-time 1200×630 OG card per page without a cover |
| `ogCardFont` | Font used by `ogAutoCard` (SC subset TTF) |
| `llmsTxtIntro` | Intro paragraph of the theme-generated `llms.txt` |
| `lightbox` | Enable the GLightbox image lightbox (opt-in) |
| `math` / `mermaid` | Enable KaTeX / Mermaid (opt-in) |
| `fuseOpts` | Search index options, forwarded to Fuse.js |
| `giscus.*` | Giscus comments (opt-in): `repo` / `repoId` / `category` / `categoryId` are required; optional `mapping` / `strict` / `reactionsEnabled` / `emitMetadata` / `inputPosition` / `theme` / `lang` forward to the giscus script with sane defaults |

### Inherited from PaperMod

`defaultTheme`, `ShowToc`, `TocOpen`, `ShowReadingTime`, `ShowWordCount`,
`ShowBreadCrumbs`, `ShowCodeCopyButtons`, `ShowPostNavLinks`, `ShowShareButtons`,
`ShareButtons`, `ShowCanonicalLink`, `CanonicalLinkText`, `ShowRssButtonInSectionTermList`,
`ShowAllPagesInArchive`, `ShowPageNums`, `disableThemeToggle`, `disableLangToggle`,
`disableScrollToTop`, `disableSpecial1stPost`, `disableAnchoredHeadings`,
`disableReadingProgress`, `hideFooter`, `hideMeta`, `hideSummary`, `hideAuthor`,
`hideArticleMeta`, `mainSections`, `DateFormat`, `env`, `robotsNoIndex`,
`label.*`, `assets.*`, `homeInfoParams.*`, `profileMode.*`, `cover.*`,
`editPost.*`, `socialIcons`, `schema.*`, `analytics.*`, `footer.hideCopyright`,
`comments`, `searchHidden`.

These behave as in upstream PaperMod. Deviations are documented in the README.

One deviation: with `[params.giscus]` configured, the `comments` switch renders the theme's built-in giscus block (off by default, zero requests otherwise); front matter `comments: false` opts a page out.

## Front-matter params

`hiddenInHomeList` (exclude a post from the homepage list),
`searchHidden` (exclude from the search index),
`showRelated` (default true; set `false` to drop the related-posts block),
`robotsNoIndex`, plus standard Hugo front matter and the PaperMod
front matter family (`cover.*`, `editPost.*`, `canonicalURL`, …).

## CSS contract

- All theme-owned classes carry the **`sg-` prefix** (e.g. `sg-hero`,
  `sg-entry`, `sg-toc`, `sg-now`). These names are frozen.
- Site-level `assets/css/extended/*.css` is concatenated **after** the theme's
  stylesheet (since v0.7.1): site rules of equal specificity always win. Do not
  add specificity hacks.
- Non-prefixed classes (`post-content`, `paginav`, `related-posts`, …) are
  inherited from PaperMod and kept for compatibility; treat them as read-mostly.

## Data contracts

- `data/analytics.json`: optional. Recognized fields: `total` (int),
  `since` (YYYY-MM-DD), `days` (map, renders the footer sparkline).
- Output formats shipped by the theme: `LLMSTXT` (`/llms.txt`),
  `LLMSFULL` (`/llms-full.txt`), `JSONFeed` (`/feed.json`),
  search index (`index.json`). All opt-in via `outputs.home`.

## Extension points

- Partials a site may override by shadowing: `extend_head.html`,
  `extend_footer.html`, `post_meta.html`, `author.html`,
  `comments.html` (built-in giscus; shadow it for any other comment system).
- `layouts/shortcodes/` shipped with the theme are part of the contract:
  `zerthimon`-style custom shortcodes belong to the site, not the theme.
- i18n keys: adding keys is additive; renaming a key is a breaking change.

### Optional project figures

`assets/css/components/project-figures.css` styles an illustrated index using
`sg-index--illustrated`, `sg-index__figure`, and `sg-project-figure`. A site owns
its project data, shortcode, and inline SVGs; explicitly load this stylesheet
only on the pages using them. It uses the host palette, needs no JavaScript,
and respects keyboard focus and reduced motion. The plain index is unchanged.

Anatomy-style shading tones (2026-10-24): `sg-figure__lo` (base, feet),
`sg-figure__mid` (structure), `sg-figure__hi` (the subject), `sg-figure__lit`
(the one accent to watch), `sg-figure__faint` (grooves, inset outlines),
`sg-figure__cable-lit` (a lit patch cable), plus the original
`sg-figure__{top,side,end,metal,paper,ink,accent,rule,print,metal-line,cable,
wheel,shadow,glow,light,press-head}` classes. Figures stay static site content;
the tones only map them onto the host palette in both schemes.

### Explanatory shortcodes

- `{{</* volume-shelf */>}}` renders native links from the current page's actual
  level-two heading fragments. It preserves order and explicit IDs and does
  not imply publication or completion. Use standard (`<`, not `%`) notation.
  Spine widths reflect the summed Hugo `WordCount` of published local pages
  linked by numbered Markdown entries under each h2. Root-relative and same-host
  absolute permalinks resolve across languages; duplicates within a volume count
  once. Placeholders, drafts, future/expired pages, external links, and other
  shelf pages do not count. Fenced examples are ignored. Unresolvable catalogues
  keep equal-width spines. The bounded scale shows relative content, not page
  count or completion; title text exposes approximate counts, refreshed at build.
- `{{</* page-anatomy */>}}` is a five-part article-page schematic. Buttons select
  a part, the checkbox separates the parts, and Escape closes it. Without JS,
  the drawing and all descriptions remain visible. Reduced motion removes
  transitions without disabling the controls.

Assets are loaded only on pages using these shortcodes. A site overriding
`extend_head.html` must call `partials/figures/assets.html`. The shelf needs
no JS; only the page diagram loads the small `page-anatomy.js` module.
The figures use the host palette and English, Chinese, and Japanese labels,
with an English fallback elsewhere. They are diagrams, not screenshots.

## Machine surfaces

`AGENTS.md` (repo-level maintainer notes) and `scripts/check.sh` (one-shot
verification) are addressed to AI agents and CI; their *behavior* is part of
the contract, their wording is not.
