# Sigil Public API — frozen as of v0.9.0

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

### Sigil-native

| Param | Purpose |
| --- | --- |
| `sgKicker` | Small line above the homepage title |
| `sgHomeTitle` | Hero title override (browser-tab `<title>` stays the site title) |
| `sgSealImage` | Seal image on the homepage |
| `sgReading` / `sgPlaying` / `sgMotto` | Rotating status under the hero seal |
| `sgDaysInCage` | Status line day counter, "Day N in the Cage" |
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
  `LLMSTXTFULL` (`/llms-full.txt`), `JSONFeed` (`/feed.json`),
  search index (`index.json`). All opt-in via `outputs.home`.

## Extension points

- Partials a site may override by shadowing: `extend_head.html`,
  `extend_footer.html`, `post_meta.html`, `author.html`.
- `layouts/shortcodes/` shipped with the theme are part of the contract:
  site-specific custom shortcodes belong to the site, not the theme.
- i18n keys: adding keys is additive; renaming a key is a breaking change.

## Machine surfaces

`AGENTS.md` (repo-level maintainer notes) and `scripts/check.sh` (one-shot
verification) are addressed to AI agents and CI; their *behavior* is part of
the contract, their wording is not.
