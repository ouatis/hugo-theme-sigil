# Changelog

One line per tag; `git log` carries the details. Nothing below touches the
frozen API except the additive `archives.showAuthor` (v0.9.11) — see
[docs/api.md](docs/api.md).

## v0.9.19 — 2026-10-06

- Revert v0.9.18: the header returns to wordmark + theme toggle + language
  exits on the left, navigation on the right (maintainer's call).

## v0.9.18 — 2026-10-06

- Header reorganization: theme toggle into the menu tail, language exits to
  the footer. Reverted in v0.9.19.

## v0.9.17 — 2026-10-06

- Search menu item becomes a magnifier icon (aria-label and accesskey kept).

## v0.9.16 — 2026-10-06

- Language switcher lists only the other languages; separator / → ·.

## v0.9.15 — 2026-10-06

- Revert v0.9.13's homepage header mark: the wordmark is back on every page.

## v0.9.14 — 2026-10-06

- Status strip rotates every 6 s (was 8 s).

## v0.9.13 — 2026-10-06

- Homepage typography: hero title 72px/600 with CJK tracking; seal 280px with
  a single ring (the outer ring now exists only as the hover ripple); dark
  filter reads as charcoal instead of X-ray; hero bottom border removed;
  entry hairlines lightened; issue numbers become ghost numerals.

## v0.9.12 — 2026-10-06

- Archives drop the month layer — entries sit directly under the ghost year;
  row meta carries month-day.

## v0.9.11 — 2026-10-06

- Archives rows: compact ledger meta (day + reading time); author moves
  behind the new additive `archives.showAuthor` (default off).
- check.sh no longer swallows a failed exampleSite build behind --quiet.

## v0.9.10 — 2026-10-06

- `page-header-flat` variant: the archives header keeps its hairline and
  drops the red accent segment.

## v0.9.9 — 2026-10-06

- Archives layout renders the page body (`.archive-intro`) between the header
  and the year groups.
- build-fonts.sh drops the GNU-only `--wildcards` flag (macOS bsdtar).

## v0.9.8 — 2026-10-06

- Corpus font mode for the demo (`scripts/build-fonts.sh corpus`): real Plex
  CJK at ~1/36th the weight; README badges; CI font tooling.

## v0.9.7 — 2026-10-06

- post-meta separators respect `hideArticleMeta`; docs drop a retired example
  name.
