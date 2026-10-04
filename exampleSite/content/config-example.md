---
title: "Configuration examples"
slug: config-example
categories:
  - demo
date: 2026-02-10
---

Copy-paste starting points for `hugo.toml`. Everything shown here is part of
the [public API](https://github.com/ouatis/hugo-theme-sigil/blob/main/docs/api.md),
frozen as of v0.9.0.

## Minimal

Sigil works with no configuration beyond the Hugo basics:

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
  home = ["HTML", "RSS", "JSON", "LLMSTXT", "LLMSTXTFULL", "JSONFeed"]

[params]
  llmsTxtIntro = "A slow blog about X and Y."
```

## Per-page OG cards

Pages without a cover get a build-time 1200×630 card (title + site name on a
paper background). The font must cover your titles' script:

```toml
[params]
  ogAutoCard = true
  ogCardFont = "fonts/og/og-card.ttf"   # build it with scripts/build-fonts.sh
```

## Series

Point `sgSeriesFrom` at a normal page whose body is an ordered list; every
post linked from that list gets series navigation and a floating panel:

```toml
[params]
  sgSeriesFrom = "/lectures/"    # a curation page you write
  sgSeriesTab = "Lectures"       # tab label
```

## Views counter and sparkline

Provide `data/analytics.json` with `{"total": 0, "since": "2026-01-01",
"days": {"2026-01-01": 12}}` and the footer renders a cumulative counter with
a 120-day sparkline. Regenerate it on your side (CI cron is a good place).
