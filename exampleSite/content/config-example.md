---
title: "Configuration examples"
slug: config-example
date: 2026-02-10
---

Copy-paste starting points for `hugo.toml`. Everything shown here is part of
the [public API](https://github.com/ouatis/hugo-theme-sigil/blob/main/docs/api.md),
frozen as of v0.9.0.

## Minimal

SIGIL works with no configuration beyond the Hugo basics:

```toml
baseURL = "https://example.org/"
title = "My notebook"
theme = ["github.com/ouatis/hugo-theme-sigil"]

[params]
  mainSections = ["posts"]
```

## Hero and status

The homepage hero shows a seal, a kicker line, and an optional rotating
status (Reading / Playing / a motto). Omit what you don't want:

```toml
[params]
  sgKicker = "NOTES FROM THE DESK"
  sgHomeTitle = "My notebook"          # hero title; tab title stays site title
  sgSealImage = "avatar.png"
  sgReading = "W. G. Sebald"
  sgPlaying = "Crusader Kings III"
  # sgMotto = "A STRING OF WORDS"
  # sgDaysInCage = true                 # "Day N in the Cage", from earliest post
  homeInfoParams.content = "A few essays a year."
```

## List and reading experience

```toml
[params]
  homePageSize = 9          # posts per homepage page
  ShowTotalWords = true     # "46 posts · 218K words" next to the count
  ShowToc = true
  TocOpen = false
  ShowCodeCopyButtons = true
  defaultTheme = "auto"
```

## Search

Search is client-side over a JSON index. Keys and weights are yours to tune:

```toml
[params.fuseOpts]
  threshold = 0.4           # 0.2 loses typo tolerance for CJK; 0.4 is a good floor
  ignorelocation = true
  keys = [
    { name = "title", weight = 3 },
    { name = "category", weight = 2.5 },
    { name = "summary", weight = 2 },
    { name = "content", weight = 1 },
    { name = "link", weight = 0.5 },
  ]
```

## Machine surfaces

The theme can advertise itself to machines as well as humans:

```toml
[outputs]
  home = ["HTML", "RSS", "JSON", "LLMSTXT", "LLMSFULL", "JSONFeed"]

[params]
  llmsTxtIntro = "A slow blog about X and Y."
```

## Per-page OG cards

Pages without a cover get a build-time 1200×630 card (title + site name on a
paper background). The font must cover your titles' script:

```toml
[params]
  ogAutoCard = true
  # Optional: point at a TTF that covers your titles' script. The theme
  # ships a Latin IBM Plex Serif by default (assets/og/plex-serif-regular.ttf);
  # CJK sites should subset their own and reference it here.
  # ogCardFont = "fonts/og/my-serif.ttf"
```

## Series

Point `sgSeriesFrom` at a normal page whose body is an ordered list; every
post linked from that list gets series navigation and a floating panel:

```toml
[params]
  sgSeriesFrom = "/lectures/"    # a curation page you write
  sgSeriesTab = "Lectures"       # tab label
```

## Languages and right-to-left

SIGIL ships 47 interface languages. Right-to-left ones (Arabic, Persian,
Hebrew, Central Kurdish) mirror the whole layout — sidenotes, the floating
TOC, arrows — when the language declares its direction:

```toml
[languages.fa]
  label = "فارسی"
  direction = "rtl"    # Hugo ≥ 0.158; the old key was languageDirection
  weight = 3
```

Add the `[languages.xx]` block **before** adding `content/.xx.md` files: a
translation file for a language that is not configured gets folded into the
default language's own pages.

## Comments (giscus)

Off by default — zero requests until both switches are set. The `comments`
switch comes from PaperMod; `[params.giscus]` carries the widget config from
[giscus.app](https://giscus.app/setup):

```toml
[params]
  comments = true

[params.giscus]
  repo = "you/your-repo"        # public repo with Discussions enabled
  repoId = "R_..."              # both IDs from giscus.app/setup
  category = "Announcements"
  categoryId = "DIC_..."
  # mapping = "pathname"        # pathname | url | title | og:title | number
  # theme = "light"             # light | dark | a custom CSS URL; light/dark follow the site toggle
  # lang = "en"                 # defaults from the site language (zh -> zh-CN, ja -> ja)
```

A single post opts out with `comments: false` in its front matter.

## Views counter and sparkline

Provide `data/analytics.json` with `{"total": 0, "since": "2026-01-01",
"days": {"2026-01-01": 12}}` and the footer renders a cumulative counter with
a 120-day sparkline. Regenerate it on your side (CI cron is a good place).
