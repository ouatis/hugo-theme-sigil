# Changelog

One line per tag; details in `git log`. API contract lives in
[docs/api.md](docs/api.md).

## v0.9.20

- ci: build-fonts.sh actually sets `TAR_WILDCARDS=(--wildcards)` on GNU tar — the detection block assigned an empty array, so Ubuntu demo builds failed on pattern extraction while macOS looked fine.

## v0.9.19

- Revert v0.9.18; header back to wordmark + toggle + language exits.

## v0.9.18

- Header reorganization (reverted in v0.9.19).

## v0.9.17

- Search menu item becomes an icon.

## v0.9.16

- Language switcher lists only other languages; / → ·.

## v0.9.15

- Wordmark restored on the homepage header.

## v0.9.14

- Status strip rotates every 6 s.

## v0.9.13

- Homepage: quieter title, single-ring seal, charcoal dark filter, fewer
  lines, ghost issue numbers.

## v0.9.12

- Archives drop the month layer; row meta carries month-day.

## v0.9.11

- Archives ledger meta; additive `archives.showAuthor`; check.sh guards
  build failures.

## v0.9.10

- `page-header-flat`: archives header drops the red segment.

## v0.9.9

- Archives render the page body; build-fonts.sh works on bsdtar.

## v0.9.8

- Corpus font mode for the demo; README badges.

## v0.9.7

- post-meta separators respect `hideArticleMeta`.
