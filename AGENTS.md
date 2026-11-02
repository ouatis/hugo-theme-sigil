# AGENTS.md

Notes for AI agents working on this repository. Humans: the README is your
entry point; this file is the maintainer's cheat sheet.

## What this is

SIGIL — a restrained literary blog theme for Hugo (≥ 0.166), deep fork of
[PaperMod](https://github.com/adityatelange/hugo-PaperMod). The MIT license
and the PaperMod attribution chain in `LICENSE` / `NOTICE.md` must survive
every change.

## Build & verify

```bash
# interactive preview
cd exampleSite && hugo server --themesDir ../..

# one-shot verification (clears caches, builds with --minify, asserts artifacts)
bash scripts/check.sh
```

A clean exit from `scripts/check.sh` is the definition of "works". Run it
before proposing any change. CI (`.github/workflows/demo.yml`) builds
exampleSite for the demo site; fonts are regenerated there on every deploy.

`check.sh` also treats the **machine-readable output as a contract**, not just
"the file exists": RSS dates must parse as RFC 822 and every channel must
carry `atom:link rel=self`; `feed.json` must be JSON Feed 1.1 with unique
item ids and RFC 3339 dates; every JSON-LD block must carry an id
(`ld-org` on a homepage, `ld-breadcrumb`/`ld-post` on a post), `json.loads`,
and a schema.org `@context`, and a BlogPosting must carry a numeric `wordCount`
(schema.org types it Integer, so a quoted count is a validator warning);
every `target=_blank` must have
`noopener noreferrer` in `rel`; every external link in post content must
carry `sg-ext` and no internal one may; `llms-full.txt` must exist, be larger
than `llms.txt`, and carry one `## <title>` section per post that `llms.txt`
lists; and no built JS bundle may contain `console.log`.
`scripts/check-contracts-negative.py` proves those
assertions actually bite by mutating a built `public/` copy (run
`bash scripts/check.sh` first, then `python scripts/check-contracts-negative.py`)
— extend it whenever you add an assertion, otherwise the new check is
unverified. Both parsers read decoded text: never grep raw HTML for these,
see Pitfall 7. Write every string in a JSON-LD block as
`{{ ... | jsonify | safeJS }}`: without it Go's JS context escaper and the
hand-quoted fields disagree, and the same quote is emitted as `\"`, `\u0022`
or `\u0026quot;` depending on the field. The output happened to parse; nothing
guaranteed it would keep parsing. See Pitfall 9.

Environment: Hugo 0.166 (match CI). Font tooling needs a real python3 with
fonttools + brotli. On Windows `python3` is often the Microsoft Store stub:
it exists on PATH but every call exits 49 with no output, so `command -v`
proves nothing. `scripts/lib-python.sh` resolves an interpreter by actually
running it (`SG_PYTHON` if set, else `python3`, else `python`); every script
sources it and then uses `"$SG_PY"`. Set `SG_PYTHON` to an absolute path to
pin a specific interpreter — an unusable value is a hard error, never a
silent fallback. In Git Bash, PATH entries must use POSIX form (`/c/...`); a
`C:/...` entry silently does not take effect. Never pipe a foreground
`hugo server` into `head` (SIGPIPE kills it).

## Map

- `assets/css/extended/sigil.css` — the design layer (palette, typography,
  components). `assets/css/core/theme-vars.css` — legacy PaperMod color vars.
- `assets/css/extended/` — the **concat contract**: `head.html` concatenates
  the theme's own `sigil.css`/`fonts.css` FIRST, then every site-level
  `css/extended/*.css` LAST. Site overrides always win ties. Do not fix
  specificity with `html:root` hacks — the concat order is the mechanism.
- `layouts/partials/templates/` — OG / Twitter / Schema partials. Call
  partials with the FULL path (`templates/_funcs/get-page-images`); short
  names resolve inconsistently and broke og:image silently once.
- Site override points (never edit core templates to customize):
  `extend_head.html`, `extend_footer.html`, `comments.html` (built-in giscus
  when `[params.giscus]` + `comments` are set; shadow it for any other
  comment system), render hooks under `_default/_markup/`, anything in the
  site's `layouts/` or `assets/css/extended/`.

## Page parameter contract (for content generators)

Front matter or site params the theme reads:

| Param | Effect |
| --- | --- |
| `math` / `mermaid` / `lightbox` | opt-ins; nothing loads on pages that don't set them |
| `ogAutoCard` | build-time OG card from title (needs `ogCardFont` on CJK sites) |
| `showRelated` | related-posts block (default on) |
| `cover.image` / `cover.relative` | cover image, supersedes the OG card |
| `searchHidden`, `placeholder` | search index exclusion / search input placeholder |
| `hiddenInHomeList` | keep a post out of the homepage feed |
| `sgSeriesFrom`, `sgSeriesTab` | series navigation (site-level) |
| `archives.showAuthor` | author on archive rows (default off) |
| `comments` + `[params.giscus]` | built-in giscus comments (off by default, zero requests); front matter `comments: false` opts a page out |

SIGIL-specific site params use the `sg*` prefix (`sgKicker`, `sgHomeTitle`,
`sgReading`, `sgPlaying`, `sgMotto`, `sgSealImage`, `sgDaysInCage`,
`sgSearchEmpty`, `sgSeriesFrom`, `sgSeriesTab`). Inherited PaperMod params
keep their names.

## Pitfalls (each cost a real debugging session)

1. **Hugo's processed-image cache (`resources/_gen`) does not key on
   `images.Text` font bytes.** After changing any font, `rm -rf resources`
   before trusting a local pass — stale cache produces green builds that are
   lies.
2. **pyftsubset output flavor defaults to the input's.** Subsetting a
   `.woff2` into a `.ttf` filename still writes `wOF2` bytes, which Go's
   sfnt parser rejects (`sfnt: invalid font`). Use `--flavor=none`.
3. **goldmark passthrough config key is `enable`, not `enabled`** — wrong key
   is a silent no-op, inline `\(...\)` math then gets eaten by markdown.
4. **Partial names must be full paths** from `partials/`, including the
   `templates/` prefix.
5. **IBM Plex has no U+2234 (∴) glyph** — the OG card's mark is baked into
   `assets/og/base.png`; don't try to draw it with `images.Text`.
6. **`check.sh` asserts uncommitted `static/fonts/` artifacts** — fresh
   clone: `bash scripts/build-fonts.sh corpus` first; a failed download
   wipes `static/fonts/` (`git checkout -- static/` restores).
7. **Never grep raw HTML/XML for date or URL formats.** Hugo escapes `+` in
   a `+0000` RSS offset to `&#43;0000` without `--minify` (and leaves it
   alone with it), so a regex run over the raw bytes passes or fails on a
   build flag. Parse with `xml.etree` / `html.parser` and assert on decoded
   text. Likewise `--minify` drops attribute quotes (`class=sg-ext`), so
   attribute matching must use a parser or tolerate both forms.
8. **Python output in `check.sh` needs `PYTHONIOENCODING=utf-8`.** Without it
   Python encodes stdout with the console codepage (cp936 on Chinese Windows)
   and every em dash or CJK menu word in a failure message arrives as `??`.
   The script exports it right after resolving the interpreter; keep that
   export ahead of any heredoc that prints non-ASCII.

### 8. `llms-full.txt` was documented before it was built

`layouts/home.llmsfull.txt` and the `llms.txt` header link both shipped, but
`exampleSite/hugo.toml` never listed `LLMSFULL` in `[outputs] home`, so the
file the README advertised was never generated — and nothing failed. Both the
output and the assertion now exist. If you add an output format, add it to the
demo config the same day; a template with no output is invisible.

`plainify` alone is not enough for that file: it strips tags but leaves entities
(`&#34;`, `&rsquo;`, `&#x21a9;`), so agents would read markup instead of prose.
The template pipes the body through `htmlUnescape` after `plainify`.

### 9. JSON-LD strings: `jsonify | safeJS`, never hand-quoted

Inside a `<script>` block Go treats interpolations as JavaScript, so
`"name": {{ .Title }}` and `"name": "{{ .Title }}"` take different escaper
paths and produce different bytes for the same quote. Values are now
`{{ ... | jsonify | safeJS }}`; jsonify emits a complete JSON value (quotes
included) and safeJS stops the second escape pass. Keep `plainify` before it
and `htmlUnescape` after `plainify` — otherwise `&rsquo;` and `&#34;` survive
into the JSON as literal entity text.

## Conventions

- i18n: strings go through `i18n "key" | default "English"`; fill
  `en`, `zh-CN`, `zh`, `ja`; the other ~45 languages fall back gracefully.
- Third-party code gets vendored only with an attribution note in
  `NOTICE.md`; large dependencies that can't be vendored use a pinned CDN
  with SRI (see mermaid).
- exampleSite keeps **exactly three posts**. Feature demos fold into
  `posts/typography/` (which enables math + mermaid + lightbox); do not add
  pages.
- New features are opt-in per page or site, and load nothing when disabled.

## Public contract

`docs/api.md` is the frozen public API (params, `sg-*` classes, output
formats, data shapes) as of v0.9.0. Renames need a deprecation window;
removals wait for a major. Check it before touching any param or class name.

## v1.0.0 gate (defined 2026-10-24)

v1.0.0 is a stability statement, not a feature list. All three must hold:

- [ ] **Two weeks without a regression**, counted from 2026-10-24
      (→ 2026-11-07): Demo / Install modes stay green and no
      `fix:` commit lands on `main`. A regression resets the clock from its
      fix. Pure additive releases (new opt-in params with docs + check
      coverage) do **not** reset it.
- [ ] **Gallery healthy**: no new red items from the hugoThemesSiteBuilder
      checker, and the themes.gohugo.io card reflects the current tag.
- [ ] **Contract intact**: `git diff v0.11.3..HEAD -- docs/api.md` shows no
      removals or renames; additions are fine (with a doc row each).

When all three hold: annotated tag `v1.0.0`, release notes from the tag
message.
