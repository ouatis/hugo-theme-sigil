# Changelog

One line per tag; details in `git log`. API contract lives in
[docs/api.md](docs/api.md).

## v0.9.23

- Homepage status line gains four fields — `sgListening` / `sgWatching` / `sgWriting` / `sgExploring` — alongside `sgReading`/`sgPlaying`/`sgMotto`; each renders an icon + i18n label and any subset may be set. Two Phosphor icons added (`headphones`, `monitor-play`); the new fields reuse the existing vermilion/ink-green/amber palette (no fourth hue). i18n keys `sgNowListening`/`sgNowWatching`/`sgNowWriting`/`sgNowExploring` added to en/zh-CN/ja; other languages fall back to the template's English default.
- Demo repositions from a personal site to a public theme showcase: homepage title becomes "Notes from the Margins", the status strip carries fictional example content across all six fields, the personal "Day N in the Cage" counter and the `author` name are dropped, and the three hero intros lose the "this is its demo" framing. Demo behavior verified in a headless browser (all six items render and rotate, no console errors).

## v0.9.22

- Article typography: h2 loses its rule and dead padding (chapters by size and whitespace); blockquote color lifts to `color-mix(primary 85%, theme)` (~9.2:1) for long-quote comfort; archives year spacing 64→48 after an A/B; end-of-article de-chromed — tag pill borders at 60%, paginav loses its divider and top rule, related-posts drops its top border; whitespace now separates the stack.

## v0.9.21

- Header hierarchy: theme toggle loses its idle border ring (returns on hover/focus), language exits unify at 11px — weaker than the nav by size, since light-mode contrast math forbids opacity dimming. Section head becomes a 56px chapter mark instead of a full-width rule. Ghost issue numbers 0.07 → 0.09.

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
